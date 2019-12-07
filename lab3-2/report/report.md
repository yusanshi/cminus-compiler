# lab3-2实验报告
汪若辰 PB17000098

余磊 PB17051053

## 实验要求

学习了解 LLVM PASS 的作用，观察使用 `opt` 工具利用指定 PASS 对代码优化的过程，通过阅读源代码分析 PASS 的运行原理。

## 报告内容 

### DCE

#### 类型和作用

是一种 Transform Pass，它其实是 Dead Inst Elimination 和 Dead Code Elimination 的结合，前者将代码扫描一遍，优化掉明显是死代码的部分，后者在每消除一条死指令之前，会尝试将它的每个操作数清空，对由此新产生的死指令循环调用消除过程。

#### 示例

举例如下。
```c
int main(void) {
    5 / 2;
    return 0;
}
```
这一段非常简单的程序中的 `5 / 2;` 是死代码，因为它的运算结果 2 并没有被使用到。

为它手动构造 IR。
```llvm
define i32 @main() {
  %1 = sdiv i32 5, 2
  ret i32 0
}
```

使用 `opt` 工具对其进行优化：`opt test.ll -print-after-all -print-before-all -dce -S`，输出如下。
```
*** IR Dump Before Dead Code Elimination ***
define i32 @main() {
  %1 = sdiv i32 5, 2
  ret i32 0
}
*** IR Dump After Dead Code Elimination ***
define i32 @main() {
  ret i32 0
}
*** IR Dump Before Module Verifier ***
define i32 @main() {
  ret i32 0
}
*** IR Dump After Module Verifier ***
define i32 @main() {
  ret i32 0
}
; ModuleID = 'test.ll'
source_filename = "test.ll"

define i32 @main() {
  ret i32 0
}
```
可以看到，Dead Code Elimination 消除了代码中多余的 `%2 = sdiv i32 5, 2`，它正是程序中的死代码，而（我们并没有显式指定的）Module Verifier 为代码加上了 `ModuleID` 和 `source_filename` 信息。

为说明 DCE 的工作流程，再举一例。
```c
int main(void) {
    int a;
    a = 4;
    a - 2;
    return 0;
}
```

手动构造 IR 结果如下。
```llvm
define i32 @main() {
  %1 = alloca i32
  store i32 4, i32* %1
  %2 = load i32, i32* %1
  %3 = sub nsw i32 %2, 2
  ret i32 0
}
```

使用相同命令，得到最后的优化结果。
```
define i32 @main() {
  %1 = alloca i32
  store i32 4, i32* %1
  ret i32 0
}
```

可以看到，DCE 把 `load` 和 `sub` 的两个指令一并优化掉了。显然，如果 DCE 的逻辑仅仅是优化掉其结果没有被使用的指令而且“一遍过”，那么 `%3 = sub nsw i32 %2, 2` 被优化是预料之中，但是 `%2 = load i32, i32* %1` 被优化掉就无法解释了。其实，“一遍过”正是 Dead Inst Elimination 做的事情，而 Dead Code Elimination 出了对代码扫描一遍，还利用 `WorkList` 实现了一个简单的循环优化的过程，我将在下一部分详细介绍这个过程。

#### 概述

分析 DCE 这个 PASS 所在的代码 `lib/Transforms/Scalar/DCE.cpp`。

这个文件内其实包含两个 PASS：`llvm::createDeadInstEliminationPass()` 会返回 `DeadInstElimination()`，`llvm::createDeadCodeEliminationPass()` 会返回 `DCELegacyPass()`。

先来介绍“一遍过”的 `DeadInstElimination()`。它有成员函数 `bool runOnBasicBlock(BasicBlock &BB)`，其返回值表示是否对当前基本块做了修改，对于基本块的每个指令 `Inst`，调用 `isInstructionTriviallyDead(Inst, TLI)`，若其返回值为 `true`（指令的结果未被使用，且指令没有副作用），则使用 `Inst->eraseFromParent();` 将其从当前基本块中删除，同时更新作为 Flag 的 `Changed` 变量。

再来介绍相比 `DeadInstElimination()` 更彻底的 `DCELegacyPass()`。它有成员函数 `bool runOnFunction(Function &F)`，这个成员函数先做了一些初始化操作，再调用 `eliminateDeadCode()`，这个函数的返回值同样表示是否有做修改，即是否有做死指令消除。在 `eliminateDeadCode()` 内，先是一个初始的“一遍过”过程：对每个指令调用 `DCEInstruction()`，`DCEInstruction()` 函数特别的地方在于它维护了一个 `WorkList`，如果判断一条指令已经是明显的死指令，它不会立即将其删除，而是尝试把它的每个操作数清空，查看以“被清空的那个操作数”作为结果的指令是否变成了死指令，如是，就将它加入到 `WorkList`。接下来，是一个循环过程：只要 `WorkList` 不为空，就对其中的指令调用 `DCEInstruction()`。

`WorkList` 的存在和循环消除的精妙之处在于，它们的存在大大降低了消除“链式死指令”的开销。对于 `%2 = %1; %3 = %2; ...... %n = %(n-1);` 这样的“链式死指令”，不把 `%n = %(n-1);` 消除往往就发现不了前面的死指令，因为看起来前面指令的运算结果在后面要被用到。如果采用 `DeadInstElimination()` 这种“一遍过”操作，要想把这样的“链式死指令”全部消除的话，往往就要不断进行“一遍过”，直到某一遍没有指令被消除为止，显然，这么做的成本非常大，而 `WorkList` 显然相对完美地解决了这个问题。


### ADCE
#### 类型和作用
也是一种 Transform Pass，这里的「A」指的是「Aggressive」，即激进的死代码消除。它的基本运行逻辑是，它假设每条指令都是多余的，除非之后的分析能证明它是有用的。如果把 DCE 看成黑名单机制，那么 ADCE 就是白名单机制：只有被证明确实有用的代码才会保留下来。

#### 示例

我们将给出来一个 DCE 不能消除死代码的例子。

对于下面这个简单的程序：

```c
int main(void) {
    int i;
    i = 1;
    while (i < 10) {
        i = i + 1;
    }
    return i;
}
```
我们使用 LLVM 的 `phi` 指令手动构造一段和原程序逻辑相同的 IR 代码，并添加了 `%i1` 和 `%i2` 这两个多余的量：

```llvm
define i32 @main() {
entry:
  br label %loop
loop:
  %i1 = phi i32 [0, %entry], [%i2, %loop]
  %j1 = phi i32 [1, %entry], [%j2, %loop]
  %i2 = mul i32 %i1, 2
  %j2 = add i32 %j1, 1
  %cmp = icmp slt i32 %j2, 10
  br i1 %cmp, label %loop, label %return
return:
  ret i32 %j2
}
```

在此例中，`%i1` 和 `%i2` 对程序的结果没有任何影响，和它们相关的都是死代码。但是在跑 `dce` 这个 pass 之后发现代码并没有被优化，原因也不难理解：循环体中和它们相关的有 `%i1 = phi i32 [0, %entry], [%i2, %loop]` 和 `%i2 = mul i32 %i1, 2` 这两条指令，可以看出，在这两条指令中 `%i1` 和 `%i2` 互相依赖，而且由于它们是在循环体内，就形成了一种“循环依赖”的关系，`dce` 就会找不到突破口，从而不能“找到漏洞、逐一击破”。

而在 `adce` 之后，和 `%i1`，`%i2` 有关的死代码都被删除了：
```llvm
define i32 @main() {
entry:
  br label %loop

loop:                                             ; preds = %loop, %entry
  %j1 = phi i32 [ 1, %entry ], [ %j2, %loop ]
  %j2 = add i32 %j1, 1
  %cmp = icmp slt i32 %j2, 10
  br i1 %cmp, label %loop, label %return

return:                                           ; preds = %loop
  ret i32 %j2
}
```

#### 概述
ADCE 也利用了一个指令的 WorkList。主要有三个步骤：
```cpp
bool AggressiveDeadCodeElimination::performDeadCodeElimination() {
    this->initialize();
    this->markLiveInstructions();
    return this->removeDeadInstructions();
}
```

#### `initialize`
1. 对 block 和 instruction 收集一些有用的信息，如 terminator 的信息；
2. 先标记一批「live」指令和 basic block 并将对应的指令或 basic block 的非条件跳转指令加入 WorkList。判断标准：
    - 使用函数 `isAlwaysLive`
        - 可能有副作用的指令 （`mayHaveSideEffects`）
        - basic block 的一部分 terminator（不属于 branch 和 switch 的 terminator）
    - 循环中回边指向的 basic block
    - 从此 basic block 无法到达函数的返回指令，做法是从 post dominator tree 中不是返回指令的根开始向上搜索，标记搜索到的指令
    - entry block
3. 标记没有 live terminator 的 basic block，在之后的 `markLiveBranchesFromControlDependences` 中要用到。

#### `markLiveInstructions`
根据已知的 live 指令向前标记其它的 live 指令。标记指令如果：
- 此指令和已知 live 指令存在 D-U 链；
- 或会影响已知 live 指令是否执行的指令（control dependent，在函数 `markLiveBranchesFromControlDependences` 中）。

每标记一个 live 指令都将它加入 WorkList，处理完之后将它移除。不停地循环直到 WorkList 中没有需要处理的 live 指令。

#### `removeDeadInstructions`
1. 先执行函数 `updateDeadRegions`
    1. 对每一个有 dead terminator 的 basic block，先找到一个离函数出口最近的后继（根据反向控制流图的后序遍历结果判断）
    2. 将这个 basic block branch 到找到的后继
    3. 对 post dominator tree 进行相应的更新
2. 剩下没有被标记为 live 的指令都是没有副作用、不影响控制流且不影响返回值的指令，使用 `dropAllReferences` 和 `eraseFromParent` 删除。

## 实验总结

- 学会了利用 `opt` 工具观察特定 PASS 对代码优化的过程；

- 通过阅读 `lib/Transforms/Scalar/` 内的代码，大致了解了 LLVM PASS 对中间代码优化的思路和流程；

- 大大加深了对死代码消除的理解（我们选择的两个 PASS 都和死代码消除相关）。


## 实验反馈

无。
