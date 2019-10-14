## Lab2 实验报告

| 姓名 | 学号       |
| ---- | ---------- |
| 余磊 | PB17051053 |

<!-- TOC -->

- [Lab2 实验报告](#lab2-实验报告)
    - [实验要求](#实验要求)
    - [实验设计](#实验设计)
    - [建立语法树](#建立语法树)
        - [共享数据结构（传递`IDENTIFIER`和`NUMBER`）](#共享数据结构传递identifier和number)
        - [过滤无用的词法符号](#过滤无用的词法符号)
        - [内存泄漏](#内存泄漏)
        - [Bison 中显示行号](#bison-中显示行号)
    - [实验结果](#实验结果)
    - [实验难点](#实验难点)
        - [Syntax error for int](#syntax-error-for-int)
    - [实验总结](#实验总结)
    - [实验反馈](#实验反馈)
        - [槽点：目录的重新设计](#槽点目录的重新设计)

<!-- /TOC -->

### 实验要求

Lab2 主要内容是使用 Bison 工具实现 CMinus 的语法分析器。具体来讲，Lab1 利用 Flex 输出了 Token 流，我们这里要使用 Bison，根据 Cminus 的语法规则对 Token 流进行解析，即利用 Bison 完成“动作表”的功能。

### 实验设计

这里对实验中的主要问题和解决过程进行叙述，一些小地方不再介绍。

### 建立语法树
这一部分是整个 Lab2 的重中之重了，基本思路如下。

首先声明终结符和非终结符。
```
%token ERROR 
%token ADD SUB MUL DIV
%token LT LTE GT GTE EQ NEQ
......

%type <tree_node> program declaration-list declaration var-declaration fun-declaration 
%type <tree_node> params param-list param compound-stmt local-declarations
......
```
接着写 Bison 的语法规则，这一部分费时又费力，为了减轻工作量，我在 Notepad++ 软件中，`Ctrl + H`打开替换功能，勾选下面的正则表达式，折腾好久，基本上保证最后的文本只需要进行少量修改就可以作为语法规则。

下面以`var-declaration`为例说明语法规则的建立。

`var-declaration`的语法如下：
var-declaration → type-specifier `ID` ; | type-specifier `ID` `[` `NUM` `]`; 

对于`|`分割的每一种情况，首先`$$=newSyntaxTreeNode(<name>);`建立结点，之后使用`SyntaxTreeNode_AddChild($$, <child>)`添加每个孩子：如果是非终结符，孩子就直接是`$(<count>)`，如果是终结符那么需要新建一个结点作为孩子，即`SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(<>));`。`actual_token_str()`是一个辅助函数，用于从 Token 获得对应的字符串表示（如`actual_token_str(SEMICOLON)`的结果是字符串`";"`。对`IDENTIFIER`和`NUMBER`的特殊处理见后文，这里不再叙述。

最终的语法规则如下。

```
var-declaration :
    type-specifier IDENTIFIER SEMICOLON  {
        $$=newSyntaxTreeNode("var-declaration");
        SyntaxTreeNode_AddChild($$, $1);
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode($2));
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(actual_token_str(SEMICOLON)));
        free($2);
    } |
    type-specifier IDENTIFIER LBRACKET NUMBER RBRACKET SEMICOLON   {
        $$=newSyntaxTreeNode("var-declaration");
        SyntaxTreeNode_AddChild($$, $1);
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode($2));
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(actual_token_str(LBRACKET)));
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNodeFromNum($4));
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(actual_token_str(RBRACKET)));
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(actual_token_str(SEMICOLON)));
        free($2);
    };
```

#### 共享数据结构（传递`IDENTIFIER`和`NUMBER`）

为了让 Bison 得到 Flex 处理后的语义值，我采用了如下方案。

首先定义`%union`，目的是让`yylval`这个全局变量有不同的成员（我们的`IDENTIFIER`和`NUMBER`分别是`char*`和`int`类型）。
```
%union {
char *id;
int num;
......
}
```

然后在 Flex 中更新`yylval`的值。(注意这里`strdup`的使用)
```
[A-Za-z]+ {
        #ifndef LAB1_ONLY
        yylval.id = strdup(yytext);
        #endif
        return IDENTIFIER;
    }
[0-9]+ {
        #ifndef LAB1_ONLY
        yylval.num = atoi(yytext);
        #endif
        return NUMBER;
    }
```

最后一步就是在 Bison 的语法规则使用存储在`$(count)`里面的值了，使用的方式有两种，以`NUMBER`为例，第一种是用到`$(count)`时指明其要使用的成员，如下。
```
%token IDENTIFIER NUMBER

......

factor :
    ......
    NUMBER  {
        $$=newSyntaxTreeNode("factor");
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNodeFromNum($<num>1));
    };
```
第二种是声明 Token 时直接指明`NUMBER`对应的成员，这样在使用`$(count)`时就不用再加上`<num>`了，如下：
```
%token <id> IDENTIFIER
%token <num> NUMBER

......

factor :
    ......
    NUMBER  {
        $$=newSyntaxTreeNode("factor");
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNodeFromNum($1));
    };
```
我个人更喜欢第二种方式，因为如果使用第一种，在语法规则出现很多`NUMBER`的时候，每次使用`$(count)`都得加`<num>`，但是第二种方式只要声明 Token 时指定成员就可以了。

#### 过滤无用的词法符号
做 Lab2（以及之后的实验）的时候需要把 Lab1 词法分析中的`EOL`, `COMMENT`, `BLANK`给过滤掉，过滤方法是在词法分析里把相应的`return`语句去掉。为了保证 Lab1 不受影响，我使用了`#ifdef`和`#endif`，中间的语句只有在`LAB1_ONLY`已定义的时候才会执行。最终相应代码如下。
```
\n { 
        #ifdef LAB1_ONLY
        return EOL;
        #endif
    }
"/*"([^*]|(\*+[^*/]))*"*"+"/" { 
        #ifdef LAB1_ONLY
        return COMMENT;
        #endif
    }
[ \t]+ { 
        #ifdef LAB1_ONLY
        return BLANK;
        #endif
    }
```
在编译运行 Lab1 相关程序时加上`LAB1_ONLY`的定义，这样`EOL`, `COMMENT`, `BLANK`可以正常返回，从而不影响 Lab1 实验结果的评测。

#### 内存泄漏
使用 Valgrind 检查是否存在内存泄露情况。
```
./do_cmake.sh && make -C build/ && valgrind --leak-check=full -v ./build/test_syntax
```
程序刚写好时，最终显示结果如下：
```
==21911== LEAK SUMMARY:
==21911==    definitely lost: 206 bytes in 70 blocks
==21911==    indirectly lost: 0 bytes in 0 blocks
==21911==      possibly lost: 0 bytes in 0 blocks
==21911==    still reachable: 18,114 bytes in 6 blocks
==21911==         suppressed: 0 bytes in 0 blocks
==21911== Reachable blocks (those to which a pointer was found) are not shown.
==21911== To see them, rerun with: --leak-check=full --show-leak-kinds=all
==21911== 
==21911== ERROR SUMMARY: 2 errors from 2 contexts (suppressed: 0 from 0)
==21911== ERROR SUMMARY: 2 errors from 2 contexts (suppressed: 0 from 0)
```
很明显，`definitely lost: 206 bytes in 70 blocks`，Google 之，意识到`snatax_analyzer.y`使用`IDENTIFIER`后要相应`free($(count))`，于是添加之，发现仍然`definitely lost: 24 bytes in 3 blocks`，Valgrind 的定位信息如下。
```
==22319== 24 bytes in 3 blocks are definitely lost in loss record 2 of 5
==22319==    at 0x4C2DB8F: malloc (in /usr/lib/valgrind/vgpreload_memcheck-amd64-linux.so)
==22319==    by 0x406593: newSyntaxTree (SyntaxTree.c:49)
==22319==    by 0x403B4C: syntax (syntax_analyzer.y:417)
==22319==    by 0x403DF0: syntax_main (syntax_analyzer.y:464)
==22319==    by 0x401BF5: main (test_syntax.c:3)
```
显然是建立树那里出的问题，`gt`是程序所用的全局树，看相关代码发现，虽然在`syntax()`函数里面已经有`gt = newSyntaxTree();`，但是我的`snatax_analyzer.y`里又出现了一次，如下。
```
program :
    declaration-list  {
        $$ = newSyntaxTreeNode("program");
        SyntaxTreeNode_AddChild($$, $1);
        gt = newSyntaxTree();
        gt->root = $$;
    };
```
于是删除`snatax_analyzer.y`里的`gt = newSyntaxTree();`，终于：
```
==22732== LEAK SUMMARY:
==22732==    definitely lost: 0 bytes in 0 blocks
==22732==    indirectly lost: 0 bytes in 0 blocks
==22732==      possibly lost: 0 bytes in 0 blocks
==22732==    still reachable: 18,114 bytes in 6 blocks
==22732==         suppressed: 0 bytes in 0 blocks
==22732== Reachable blocks (those to which a pointer was found) are not shown.
==22732== To see them, rerun with: --leak-check=full --show-leak-kinds=all
==22732== 
==22732== ERROR SUMMARY: 0 errors from 0 contexts (suppressed: 0 from 0)
==22732== ERROR SUMMARY: 0 errors from 0 contexts (suppressed: 0 from 0)
```
好多个`0`看着就是赏心悦目。
第一次用 Valgrind，表示它真的很强大，特别是泄露的定位方面很厉害。

#### Bison 中显示行号

Bison 中显示行号（用于`yyerror()`）也是很简单，只需要`extern int yylineno;`即可，不过要注意要在`syntax()`函数中加上`yylineno = 1;`，要不然分析下一个文件时这个全局变量会累增，不会自动归零（归一）。其实这一部分和 Lab1 是一模一样的😁。

### 实验结果

以`gcd.cminus`为例。

```
[START]: Syntax analysis start for gcd.cminus
[OUTPUT] Printing tree to output file ./syntree/gcd.syntax_tree
[END] Syntax analysis end for gcd.cminus
```

输出结果`gcd.syntax_tree`如下。
```
>--+ program
|  >--+ declaration-list
|  |  >--+ declaration-list
|  |  |  >--+ declaration
|  |  |  |  >--+ fun-declaration
|  |  |  |  |  >--+ type-specifier
|  |  |  |  |  |  >--* int
|  |  |  |  |  >--* gcd
|  |  |  |  |  >--* (
|  |  |  |  |  >--+ params
|  |  |  |  |  |  >--+ param-list
|  |  |  |  |  |  |  >--+ param-list
|  |  |  |  |  |  |  |  >--+ param
|  |  |  |  |  |  |  |  |  >--+ type-specifier
|  |  |  |  |  |  |  |  |  |  >--* int
|  |  |  |  |  |  |  |  |  >--* u
|  |  |  |  |  |  |  >--* ,
|  |  |  |  |  |  |  >--+ param
|  |  |  |  |  |  |  |  >--+ type-specifier
|  |  |  |  |  |  |  |  |  >--* int
|  |  |  |  |  |  |  |  >--* v
|  |  |  |  |  >--* )
|  |  |  |  |  >--+ compound-stmt
|  |  |  |  |  |  >--* {
|  |  |  |  |  |  >--+ local-declarations
|  |  |  |  |  |  |  >--* epsilon
|  |  |  |  |  |  >--+ statement-list
|  |  |  |  |  |  |  >--+ statement-list
|  |  |  |  |  |  |  |  >--* epsilon
|  |  |  |  |  |  |  >--+ statement
|  |  |  |  |  |  |  |  >--+ selection-stmt
|  |  |  |  |  |  |  |  |  >--* if
|  |  |  |  |  |  |  |  |  >--* (
|  |  |  |  |  |  |  |  |  >--+ expression
|  |  |  |  |  |  |  |  |  |  >--+ simple-expression
|  |  |  |  |  |  |  |  |  |  |  >--+ additive-expression
|  |  |  |  |  |  |  |  |  |  |  |  >--+ term
|  |  |  |  |  |  |  |  |  |  |  |  |  >--+ factor
|  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ var
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* v
|  |  |  |  |  |  |  |  |  |  |  >--+ relop
|  |  |  |  |  |  |  |  |  |  |  |  >--* ==
|  |  |  |  |  |  |  |  |  |  |  >--+ additive-expression
|  |  |  |  |  |  |  |  |  |  |  |  >--+ term
|  |  |  |  |  |  |  |  |  |  |  |  |  >--+ factor
|  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* 0
|  |  |  |  |  |  |  |  |  >--* )
|  |  |  |  |  |  |  |  |  >--+ statement
|  |  |  |  |  |  |  |  |  |  >--+ return-stmt
|  |  |  |  |  |  |  |  |  |  |  >--* return
|  |  |  |  |  |  |  |  |  |  |  >--+ expression
|  |  |  |  |  |  |  |  |  |  |  |  >--+ simple-expression
|  |  |  |  |  |  |  |  |  |  |  |  |  >--+ additive-expression
|  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ term
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ factor
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ var
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* u
|  |  |  |  |  |  |  |  |  |  |  >--* ;
|  |  |  |  |  |  |  |  |  >--* else
|  |  |  |  |  |  |  |  |  >--+ statement
|  |  |  |  |  |  |  |  |  |  >--+ return-stmt
|  |  |  |  |  |  |  |  |  |  |  >--* return
|  |  |  |  |  |  |  |  |  |  |  >--+ expression
|  |  |  |  |  |  |  |  |  |  |  |  >--+ simple-expression
|  |  |  |  |  |  |  |  |  |  |  |  |  >--+ additive-expression
|  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ term
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ factor
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ call
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* gcd
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* (
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ args
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ arg-list
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ arg-list
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ expression
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ simple-expression
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ additive-expression
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ term
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ factor
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ var
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* v
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* ,
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ expression
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ simple-expression
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ additive-expression
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ additive-expression
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ term
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ factor
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ var
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* u
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ addop
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* -
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ term
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ term
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ term
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ factor
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ var
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* u
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ mulop
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* /
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ factor
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ var
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* v
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ mulop
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* *
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ factor
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ var
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* v
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* )
|  |  |  |  |  |  |  |  |  |  |  >--* ;
|  |  |  |  |  |  >--* }
|  |  >--+ declaration
|  |  |  >--+ fun-declaration
|  |  |  |  >--+ type-specifier
|  |  |  |  |  >--* int
|  |  |  |  >--* main
|  |  |  |  >--* (
|  |  |  |  >--+ params
|  |  |  |  |  >--* void
|  |  |  |  >--* )
|  |  |  |  >--+ compound-stmt
|  |  |  |  |  >--* {
|  |  |  |  |  >--+ local-declarations
|  |  |  |  |  |  >--+ local-declarations
|  |  |  |  |  |  |  >--+ local-declarations
|  |  |  |  |  |  |  |  >--+ local-declarations
|  |  |  |  |  |  |  |  |  >--* epsilon
|  |  |  |  |  |  |  |  >--+ var-declaration
|  |  |  |  |  |  |  |  |  >--+ type-specifier
|  |  |  |  |  |  |  |  |  |  >--* int
|  |  |  |  |  |  |  |  |  >--* x
|  |  |  |  |  |  |  |  |  >--* ;
|  |  |  |  |  |  |  >--+ var-declaration
|  |  |  |  |  |  |  |  >--+ type-specifier
|  |  |  |  |  |  |  |  |  >--* int
|  |  |  |  |  |  |  |  >--* y
|  |  |  |  |  |  |  |  >--* ;
|  |  |  |  |  |  >--+ var-declaration
|  |  |  |  |  |  |  >--+ type-specifier
|  |  |  |  |  |  |  |  >--* int
|  |  |  |  |  |  |  >--* temp
|  |  |  |  |  |  |  >--* ;
|  |  |  |  |  >--+ statement-list
|  |  |  |  |  |  >--+ statement-list
|  |  |  |  |  |  |  >--+ statement-list
|  |  |  |  |  |  |  |  >--+ statement-list
|  |  |  |  |  |  |  |  |  >--+ statement-list
|  |  |  |  |  |  |  |  |  |  >--+ statement-list
|  |  |  |  |  |  |  |  |  |  |  >--* epsilon
|  |  |  |  |  |  |  |  |  |  >--+ statement
|  |  |  |  |  |  |  |  |  |  |  >--+ expression-stmt
|  |  |  |  |  |  |  |  |  |  |  |  >--+ expression
|  |  |  |  |  |  |  |  |  |  |  |  |  >--+ var
|  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* x
|  |  |  |  |  |  |  |  |  |  |  |  |  >--* =
|  |  |  |  |  |  |  |  |  |  |  |  |  >--+ expression
|  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ simple-expression
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ additive-expression
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ term
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ factor
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* 72
|  |  |  |  |  |  |  |  |  |  |  |  >--* ;
|  |  |  |  |  |  |  |  |  >--+ statement
|  |  |  |  |  |  |  |  |  |  >--+ expression-stmt
|  |  |  |  |  |  |  |  |  |  |  >--+ expression
|  |  |  |  |  |  |  |  |  |  |  |  >--+ var
|  |  |  |  |  |  |  |  |  |  |  |  |  >--* y
|  |  |  |  |  |  |  |  |  |  |  |  >--* =
|  |  |  |  |  |  |  |  |  |  |  |  >--+ expression
|  |  |  |  |  |  |  |  |  |  |  |  |  >--+ simple-expression
|  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ additive-expression
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ term
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ factor
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* 18
|  |  |  |  |  |  |  |  |  |  |  >--* ;
|  |  |  |  |  |  |  |  >--+ statement
|  |  |  |  |  |  |  |  |  >--+ selection-stmt
|  |  |  |  |  |  |  |  |  |  >--* if
|  |  |  |  |  |  |  |  |  |  >--* (
|  |  |  |  |  |  |  |  |  |  >--+ expression
|  |  |  |  |  |  |  |  |  |  |  >--+ simple-expression
|  |  |  |  |  |  |  |  |  |  |  |  >--+ additive-expression
|  |  |  |  |  |  |  |  |  |  |  |  |  >--+ term
|  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ factor
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ var
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* x
|  |  |  |  |  |  |  |  |  |  |  |  >--+ relop
|  |  |  |  |  |  |  |  |  |  |  |  |  >--* <
|  |  |  |  |  |  |  |  |  |  |  |  >--+ additive-expression
|  |  |  |  |  |  |  |  |  |  |  |  |  >--+ term
|  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ factor
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ var
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* y
|  |  |  |  |  |  |  |  |  |  >--* )
|  |  |  |  |  |  |  |  |  |  >--+ statement
|  |  |  |  |  |  |  |  |  |  |  >--+ compound-stmt
|  |  |  |  |  |  |  |  |  |  |  |  >--* {
|  |  |  |  |  |  |  |  |  |  |  |  >--+ local-declarations
|  |  |  |  |  |  |  |  |  |  |  |  |  >--* epsilon
|  |  |  |  |  |  |  |  |  |  |  |  >--+ statement-list
|  |  |  |  |  |  |  |  |  |  |  |  |  >--+ statement-list
|  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ statement-list
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ statement-list
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* epsilon
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ statement
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ expression-stmt
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ expression
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ var
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* temp
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* =
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ expression
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ simple-expression
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ additive-expression
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ term
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ factor
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ var
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* x
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* ;
|  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ statement
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ expression-stmt
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ expression
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ var
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* x
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* =
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ expression
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ simple-expression
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ additive-expression
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ term
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ factor
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ var
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* y
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* ;
|  |  |  |  |  |  |  |  |  |  |  |  |  >--+ statement
|  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ expression-stmt
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ expression
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ var
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* y
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* =
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ expression
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ simple-expression
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ additive-expression
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ term
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ factor
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ var
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* temp
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* ;
|  |  |  |  |  |  |  |  |  |  |  |  >--* }
|  |  |  |  |  |  |  >--+ statement
|  |  |  |  |  |  |  |  >--+ expression-stmt
|  |  |  |  |  |  |  |  |  >--+ expression
|  |  |  |  |  |  |  |  |  |  >--+ simple-expression
|  |  |  |  |  |  |  |  |  |  |  >--+ additive-expression
|  |  |  |  |  |  |  |  |  |  |  |  >--+ term
|  |  |  |  |  |  |  |  |  |  |  |  |  >--+ factor
|  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ call
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* gcd
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* (
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ args
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ arg-list
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ arg-list
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ expression
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ simple-expression
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ additive-expression
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ term
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ factor
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ var
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* x
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* ,
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ expression
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ simple-expression
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ additive-expression
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ term
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ factor
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ var
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* y
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* )
|  |  |  |  |  |  |  |  |  >--* ;
|  |  |  |  |  |  >--+ statement
|  |  |  |  |  |  |  >--+ return-stmt
|  |  |  |  |  |  |  |  >--* return
|  |  |  |  |  |  |  |  >--+ expression
|  |  |  |  |  |  |  |  |  >--+ simple-expression
|  |  |  |  |  |  |  |  |  |  >--+ additive-expression
|  |  |  |  |  |  |  |  |  |  |  >--+ term
|  |  |  |  |  |  |  |  |  |  |  |  >--+ factor
|  |  |  |  |  |  |  |  |  |  |  |  |  >--* 0
|  |  |  |  |  |  |  |  >--* ;
|  |  |  |  |  >--* }
```

可以看到，带有`*`的是叶子结点，所有的叶子结点连在一起就是源代码。

下面简要分析一下它的函数调用过程。

简洁起见，让函数体、调用参数等部分不再展开而成为叶子结点，从而得到简化的语法树。

```
>--+ program
|  >--+ declaration-list
|  |  >--+ declaration-list
|  |  |  >--+ declaration
|  |  |  |  >--+ fun-declaration
|  |  |  |  |  >--+ type-specifier
|  |  |  |  |  |  >--* int
|  |  |  |  |  >--* gcd
|  |  |  |  |  >--* (
|  |  |  |  |  >--* params
|  |  |  |  |  >--* )
|  |  |  |  |  >--+ compound-stmt
|  |  |  |  |  |  >--* {
|  |  |  |  |  |  >--* local-declarations
|  |  |  |  |  |  >--+ statement-list
|  |  |  |  |  |  |  >--* statement-list
|  |  |  |  |  |  |  >--+ statement
|  |  |  |  |  |  |  |  >--+ selection-stmt
|  |  |  |  |  |  |  |  |  >--* if
|  |  |  |  |  |  |  |  |  >--* (
|  |  |  |  |  |  |  |  |  >--* expression
|  |  |  |  |  |  |  |  |  >--* )
|  |  |  |  |  |  |  |  |  >--* statement
|  |  |  |  |  |  |  |  |  >--* else
|  |  |  |  |  |  |  |  |  >--+ statement
|  |  |  |  |  |  |  |  |  |  >--+ return-stmt
|  |  |  |  |  |  |  |  |  |  |  >--* return
|  |  |  |  |  |  |  |  |  |  |  >--+ expression
|  |  |  |  |  |  |  |  |  |  |  |  >--+ simple-expression
|  |  |  |  |  |  |  |  |  |  |  |  |  >--+ additive-expression
|  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ term
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ factor
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ call
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* gcd
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* (
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* args
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* )
|  |  |  |  |  |  |  |  |  |  |  >--* ;
|  |  |  |  |  |  >--* }
|  |  >--+ declaration
|  |  |  >--+ fun-declaration
|  |  |  |  >--* type-specifier
|  |  |  |  >--* main
|  |  |  |  >--* (
|  |  |  |  >--* params
|  |  |  |  >--* )
|  |  |  |  >--+ compound-stmt
|  |  |  |  |  >--* {
|  |  |  |  |  >--* local-declarations
|  |  |  |  |  >--+ statement-list
|  |  |  |  |  |  >--+ statement-list
|  |  |  |  |  |  |  >--* statement-list
|  |  |  |  |  |  |  >--+ statement
|  |  |  |  |  |  |  |  >--+ expression-stmt
|  |  |  |  |  |  |  |  |  >--+ expression
|  |  |  |  |  |  |  |  |  |  >--+ simple-expression
|  |  |  |  |  |  |  |  |  |  |  >--+ additive-expression
|  |  |  |  |  |  |  |  |  |  |  |  >--+ term
|  |  |  |  |  |  |  |  |  |  |  |  |  >--+ factor
|  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ call
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* gcd
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* (
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* args
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* )
|  |  |  |  |  |  |  |  |  >--* ;
|  |  |  |  |  |  >--* statement
|  |  |  |  |  >--* }
```

经过如上处理，函数调用非常明显：在`gcd()`函数中，递归调用自身的部分如下。

```
......
|  |  |  |  |  |  |  |  |  |  |  >--+ expression
|  |  |  |  |  |  |  |  |  |  |  |  >--+ simple-expression
|  |  |  |  |  |  |  |  |  |  |  |  |  >--+ additive-expression
|  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ term
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ factor
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ call
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* gcd
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* (
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* args
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* )
......

```
可以看到调用的函数本身成为了一个`expression`，而调用的时候用到的产生式是：  
27. call → `ID` `(` args `)`。

而在`main()`函数中，函数调用也类似。
```
|  |  |  |  |  |  |  |  |  >--+ expression
|  |  |  |  |  |  |  |  |  |  >--+ simple-expression
|  |  |  |  |  |  |  |  |  |  |  >--+ additive-expression
|  |  |  |  |  |  |  |  |  |  |  |  >--+ term
|  |  |  |  |  |  |  |  |  |  |  |  |  >--+ factor
|  |  |  |  |  |  |  |  |  |  |  |  |  |  >--+ call
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* gcd
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* (
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* args
|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  >--* )
```
调用的时候用到的产生式同样是：  
27. call → `ID` `(` args `)`。

### 实验难点

#### Syntax error for int

卡了挺久时间，反复在 Issue 里面翻看，最终找到了有用线索：我忘了跳过`EOL`, `COMMENT`, `BLANK`了！导致`int`后面的空格无法解析，所以刚开始就报错。

### 实验总结

- 明白了 Flex 和 Bison 间`yylval`数据的共享，它用于传递语义值；

- 学会了如何将语法规则写入 Bison 的自定义语法文件（`*.y`文件）中；

- 知道了 Forked 的仓库如何从 Fork 源更新。

### 实验反馈

#### 槽点：目录的重新设计

Lab1 和 Lab2 的目录架构如果能一开始就确定就好了，要不然来回 Merge 很麻烦，也容易有 Bug。

