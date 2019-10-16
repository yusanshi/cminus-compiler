# lab2实验报告

汪若辰

PB17000098

## 实验要求
使用 Bison 工具辅助实现 CMinus 的语法分析器并打印语法树.

## 实验设计
`union` 的结构: 使用两个域, 分别为字符串和语法树节点. 对于 `NUMBER` 和 `IDENTIFIER` 使用字符串 (`char *`), 非终结符使用语法树节点 (`SyntaxTreeNode *`). 在本实验中 `NUMBER` 没有必要做成 `int` 类型, 因为要从 `yytext` 转成一个 `int`, 又在构造语法树的时候变为字符串. 值得注意的是在构造完 `NUMBER` 或 `IDENTIFIER` 节点之后需要 `free` 掉相应的指针, 因为 `strdup` 使用了 `malloc` 分配了空间, 而在构造节点的时候又要分配新的空间, 没有直接使用 `strdup` 的空间.

对于语法树的处理, 只需要在要规约的时候新建一个节点, 把产生式右边的每一个符号做为节点的孩子就可以了, 主要是一些重复性的工作.

> 过滤词法分析中无用的词法符号

只需将 `return ...` 放在一个 `#ifdef LAB1_ONLY` 的块中就可以.

> 二义性文法

在 cmake 中使用 `VERBOSE` 选项可以看到 `bison` 生成的自动机和具体的冲突细节. 其实不需要处理, 因为 `bison` 在移进和规约之间选择了正确的一个, 就是有一个 warning. 具体的解决办法参考了 http://210.45.114.30/gbxu/notice_board/issues/62#note_541.

## 实验结果
以样例 [`lab2_selection-stmt.cminus`](../../lab1_lexical_analyzer/testcase/lab2_selection-stmt.cminus) 为例, 其中的
```c
if (i != 1) {
    return 3;
}
```
对应的语法树为

    >--+ selection-stmt
    |  >--* if
    |  >--* (
    |  >--+ expression
    |  |  >--+ simple-expression
    |  |  |  >--+ additive-expression
    |  |  |  |  >--+ term
    |  |  |  |  |  >--+ factor
    |  |  |  |  |  |  >--+ var
    |  |  |  |  |  |  |  >--* i
    |  |  |  >--+ relop
    |  |  |  |  >--* !=
    |  |  |  >--+ additive-expression
    |  |  |  |  >--+ term
    |  |  |  |  |  >--+ factor
    |  |  |  |  |  |  >--* 1
    |  >--* )
    |  >--+ statement
    |  |  >--+ compound-stmt
    |  |  |  >--* {
    |  |  |  >--+ local-declarations
    |  |  |  |  >--* epsilon
    |  |  |  >--+ statement-list
    |  |  |  |  >--+ statement-list
    |  |  |  |  |  >--* epsilon
    |  |  |  |  >--+ statement
    |  |  |  |  |  >--+ return-stmt
    |  |  |  |  |  |  >--* return
    |  |  |  |  |  |  >--+ expression
    |  |  |  |  |  |  |  >--+ simple-expression
    |  |  |  |  |  |  |  |  >--+ additive-expression
    |  |  |  |  |  |  |  |  |  >--+ term
    |  |  |  |  |  |  |  |  |  |  >--+ factor
    |  |  |  |  |  |  |  |  |  |  |  >--* 3
    |  |  |  |  |  |  >--* ;
    |  |  |  >--* }

由于使用 LALR 分析, 这一部分首先进行 `factor → NUMBER` 的规约 (`NUMBER == 3`), 再 `term → factor`, ..., 整个 `selection-stmt` 的生成过程为先识别了 `statement` 然后为 `)`, `expression`, `(`, `if`.

## 实验难点 (遇到的问题)
一开始没有把 `ERROR` 这个 token 加上, 导致不论什么程序都会报语法错误, 加上之后就好了.

词法分析文件里面包含 `yylval` 的部分没有使用 `LAB1_ONLY` 包起来, `make` 的时候总是报错 (其实是 `test_lex` 在报错, 但是我一直以为是语法分析的部分什么东西写错了, 花了不少时间), 最后看了看 issue 找到了解决方法.

## 实验总结
在本实验中我对语法树有了直观的了解, 还学习了 bison 的用法, 对 git 的用法也有了比较深的了解 (主要是 rebase 和 cherry-pick).

## 实验反馈
除了 gbxu/notice_board#112 提到的之外, 我还觉得助教不要在实验布置了之后还不停地向仓库里 commit, 这次从 10 月 4 号到 8 号每天都有新的 commit, 我们要不停地 merge, 把 git log 搞得很不好看. 虽然应该可以先回退到原 merge 之前, merge 新的 upstream, 再用 `git cherry-pick` 来解决, 但是因为会有冲突太麻烦所以就干脆就直接 merge 了.
