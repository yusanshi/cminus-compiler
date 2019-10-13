#  Lab 2 实验总结

## 实验简介

使用 Bison 工具实现 CMinus 的语法分析器。

## 实验设计

这里对实验中遇到的主要问题和解决过程进行叙述，一些小地方不再介绍。

### 传递`IDENTIFIER`和`NUMBER`
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

最后一步就是在 Bison 的语法规则使用存储在`$(count)`里面的值了，使用的方式有两个，以`NUMBER`为例，第一种是用到`$(count)`时指明其要使用的成员，如下。
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
我个人更喜欢第二种方式，因为如果使用第一种，在语法规则出现很多`NUMBER`的时候，每次使用`$(count)`都得加`<num>`，但是第一种方式只要声明 Token 时指定成员就可以了。


### 内存泄漏
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