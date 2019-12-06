# lab3-2实验报告

小组成员 姓名 学号

## 实验要求

请按照自己的理解，写明本次实验需要干什么

## 报告内容 

按要求说明选择的Pass和进行相关任务的回答

### ADCE
#### 示例
给出一个带有死代码的例子：
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

在此例中，`%i1` 和 `%i2` 对程序的结果没有任何影响，和它们相关的都是死代码。但是在跑 `dce` 这个 pass 之后发现代码并没有被优化。在 `adce` 之后，和 `%i1`，`%i2` 有关的死代码都被删除了：
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
ADCE 的思路为首先假定所有的指令都是死的，然后排除活指令，再删除剩下的死指令。主要有三个步骤：
```cpp
bool AggressiveDeadCodeElimination::performDeadCodeElimination() {
    this->initialize();
    this->markLiveInstructions();
    return this->removeDeadInstructions();
}
```

#### `initialize`
1. 对 block 和 instruction 收集一些有用的信息，如 terminator 的信息；
2. 先标记一批「live」（即一定不能删除）的指令和 basic block：
    - 使用函数 `isAlwaysLive`
        - 可能有副作用的指令 （`mayHaveSideEffects`）
        - basic block 的一部分 terminator（不属于 branch 和 switch 的 terminator）
    - 循环中回边指向的 basic block
    - 从此 basic block 无法到达函数的返回指令（FIXME）
    - entry block
3. 标记没有 live terminator 的 basic block。

#### `markLiveInstructions`
根据已知的 live 指令向前标记其它的 live 指令：
- 此指令和已知 live 指令存在 D-U 链；
- 会影响已知 live 指令是否执行的指令；
- 不停地循环直到没有需要处理的已知 live 指令。

#### `removeDeadInstructions`
TODO：`updateDeadRegions`

剩下没有被标记为 live 的指令都是没有副作用、不影响控制流且不影响返回值的指令，所以可以删除。

## 实验总结

此次实验有什么收获

## 实验反馈

对本次实验的建议（可选 不会评分）
