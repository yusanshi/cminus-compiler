# lab3-1实验报告
汪若辰 PB17000098

余磊 PB17051053

## 实验要求
使用 LLVM 将 C- 的语法树翻译为 LLVM IR。

## 实验设计

### expression（汪若辰）
由于 `visit` 没有返回值，所以只好使用全局变量返回表达式的 `Value *`。在分析完一个表达式（的部分）后将对应的全局变量设置为它的 `Value *`，然后调用 `visit` 的函数就可以通过全局变量获得表达式的值了。表达式的组成从小到大是 factor, term, additive-expression 和 expression，我们就对应地设置了四个全局变量。

factor 和 expression 的分析方法和其他的有一点不同。以 factor 为例，由于 factor 有四种，在分析 term 的时候 accept 这个 factor 会根据类型自动地选择四种 factor 的 visit 函数，所以在 num, call, expression 和 var 分析完后需要将全局变量 `curr_factor_value` 设置成它的 value。

在翻译和数组有关的表达式的时候会出现需要适配不同的类型的问题，详细分析见 [实验难点中的部分](#数组传参)。

### statement（余磊）
在 C- 的语法规则里面，函数体里面前面是 declarations，后面是 statements，其中 statements 包含了程序的所有运行逻辑，它主要由 expression、selection、iteration、return 构成，expression 在前面已经介绍过，下面来分别简要介绍一下后三个的设计思路。

**selection**

其基本逻辑如下：
```llvm
; IF-THEN
br %cond, %true, %end
true:
...
br %end
end:

; IF-ELSE-THEN
br %cond, %true, %false
true:
...
br %end
false:
...
br %end
end:
```
一步一步地将上面的逻辑翻译成对应函数即可。不过在 IF-ELSE-THEN 上遇到一个很有意思的问题：生成的 IR 里面 `false` 和 `end` 这两个 BasicBlock 的顺序是相反的，明明我们是按照正确的顺序 `SetInsertPoint` 的啊！直到后来，我突发奇想，改变了 `BasicBlock::Create()` 的顺序，发现生成的 IR 里顺序也对应改变，再后来，我留意到 `BasicBlock::Create()` 的参数 `Parent` 表示要插入的函数，它是可以先不指定的，因此可以先创建所有需要的 BasicBlock，再按需用 `insertInto` 插入到函数。生成 IR 代码时，会按照函数的 BasicBlock 表来指定插入顺序，因此能保证顺序的正确性。

**iteration**

相关逻辑如下：

```llvm
br %judge
judge:
...
br %cond, %continue, %end
continue:
...
br %judge
end:
```
由于它和 selection 非常相似，这里不再说明。

**return**

返回类型是 `void` 时用 `this->builder.CreateRetVoid()`，是 `int` 是用 `this->builder.CreateRet(curr_expression_value)`。这里我增加了对返回类型是否匹配的判断，用 `node.expression` 是否为 `nullptr` 来判断当前的 `return` 语句是否有返回值，用 `curr_function->getReturnType()` 来得到当前函数声明的返回类型，如果二者匹配就返回对应类型的值，否则报错。

### 测试
实验完成后，为了尽可能找出其中的 Bug，我们决定编写测试。汪若辰对 shell 脚本比较熟悉，于是他来负责编写脚本，余磊则负责收集测试文件。

（汪若辰）

（余磊）`cminus.md` 里面语法规则很繁杂，自己逐个写单元测试不仅费时费力，而且还可能写的不全面，于是我就想在网上找现成的 C- 程序，在汪若辰的提示下，我开始收集 GitHub 上的 C- 编译器项目里附带的测试文件，收集整理完大概有六七十个。汪若辰的脚本写好之后，我又开始根据他的脚本的运行结果来整理，最终剩下 34 个测试文件。

测试全部跑通的时候，看着一排排绿色的 `ok`，非常有成就感。
```bash
(wrc|yl)@(manjaro|ubuntu):~/.../lab3-1$ ./test.sh
Running testcase 01-gcd.cminus ... ok
Running testcase 02-dfs.cminus ... ok
Running testcase 03-sort.cminus ... ok
Running testcase 04-fibonacci.cminus ... ok
Running testcase 05-blank-stmt.cminus ... ok
Running testcase 06-uncategorized.cminus ... ok
Running testcase 07-quicksort.cminus ... ok
Running testcase 08-search.cminus ... ok
Running testcase 09-array-param.cminus ... ok
Running testcase 10-array-assign.cminus ... ok
Running testcase 11-fun-dec.cminus ... ok
Running testcase 12-input.cminus ... ok
Running testcase 13-uncategorized.cminus ... ok
Running testcase 14-uncategorized.cminus ... ok
Running testcase 15-pass-array.cminus ... ok
Running testcase 16-uncategorized.cminus ... ok
Running testcase 17-int-main.cminus ... ok
Running testcase 18-param-main.cminus ... ok
Running testcase 19-while.cminus ... ok
Running testcase 20-output.cminus ... ok
Running testcase 21-global-var.cminus ... ok
Running testcase 22-uncategorized.cminus ... ok
Running testcase 23-fibonacci.cminus ... ok
Running testcase 24-uncategorized.cminus ... ok
Running testcase 25-right-assign.cminus ... ok
Running testcase 26-while.cminus ... ok
Running testcase 27-selection.cminus ... ok
Running testcase 28-annoyed-code.cminus ... ok
Running testcase 29-last-main.cminus ... ok
Running testcase 30-while.cminus ... ok
Running testcase 31-array-out-of-range.cminus ... ok
Running testcase 32-scope.cminus ... ok
Running testcase 33-call.cminus ... ok
Running testcase 34-if.cminus ... ok

Run 34 tests, 0 fails.
```

## 实验难点
### return

### 数组传参
1. 在定义的函数内传递（余磊）

    在函数调用传递参数的时候，对于数组将是传递一个指针过去，而不是传值，这样就导致 `curr_expression_value` 不能直接作为调用时传递的参数。为了处理这种问题，我定义了一个全局变量 `is_passing_array`，用它来指导 `curr_expression_value` 的计算：如果为 `false`，那么 `curr_expression_value` 和之前一样是个表达式的值；如果为 `true`，那么它将是 `this->scope.find(node.id)` 的值。

    我还遇到了一个问题：如何判断当前的参数是个数组，也就是在什么情况下为 `is_passing_array` 赋 `true` 值，我想了很久还是不知道怎么从调用方来判断，最后我换了个思路：从被调用方判断，也就是通过被调用函数的参数表来判断。当然这样的方式会有个问题，它无法识别出调用方和被调用方的参数是否匹配。这个实验本身并不把错误检测作为一个重点，而且我也没想到不这样做的其他方法，因此只能如此。

2. 再传递

## 实验总结
余磊：
- 了解了访问者模式这种设计模式；
- 被队友写的 shell 脚本所激励，决定学习 shell 脚本编写；
- 学会了 `llvm::IRBuilder` 下一堆函数的使用。

## 实验反馈
1. 无需全局变量

    我们发现全局变量只是用于传递参数或者返回值，如果可以修改 `visit` 的返回值和参数的话完全可以避免使用全局变量。使用全局变量还是会导致一些不容易发现的 bug 的。比如在 [`f1d5d7a`] 中修复的 bug，在分析完一个 expression 的时候可能会忘记设置对应的全局变量，从而对应的值没有被传出来。（~~不过 C++ 要写多个返回值也挺麻烦的~~）

2. `enum class`

    `enum class` 是 C++11 中出现的功能，它不会把 enum 的名字暴露在全局的作用域中。把 `relop` 和 `type_specifier` 改成 `enum class` 比较好。

3. `neg_idx_except()` 的存在有些多余

    数组在 C/C++ 的实现中没有边界检查，但是这个实验却要求我们对数组的下界进行检查，这样会导致程序逻辑中多了运行时的下标检查，我们认为这是多余、无意义的。

[`f1d5d7a`]: http://210.45.114.30/PB17000098/compiler_cminus/commit/f1d5d7a1e4facc0537ebaccd7e512895d85ea64b
