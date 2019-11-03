## lab3-0实验报告

| 姓名 | 学号       |
| ---- | ---------- |
| 余磊 | PB17051053 |

### 实验要求

- 编译 LLVM，最好尝试一下选择`debug`的编译选项，`体验“较大的项目”的编译过程`；
- 为几个简单的程序手工编写对应的 LLVM IR 文件；
- 为几个简单的程序编写对应 LLVM IR 生成器（使用 CPP 调用 LLVM IR 库）。

### 实验结果

描述你的代码片段和每一个BasicBlock的对应关系

### 实验难点

- 编译 LLVM 硬盘空间不足

为了获得更好的 IO 性能，我把虚拟机的硬盘分配在了本机的固态硬盘里面，固态容量吃紧，所以我是只给 Ubuntu 16.04 分配了 32GB 的空间，平时用起来也都没问题。没想到，这次编译 LLVM（使用了debug 配置），竟然因为硬盘空间不足而中断，只能通过 Vmware 的设置选项将硬盘扩展到 120GB（一开始还没想到要扩那么多，所以经历了几次“扩展、发现不够、再次扩展”痛苦的过程）。编译完成后，`llvm-build`文件夹 52.9GB，`llvm-install`文件夹 37.3GB，果然是大项目，怕了怕了。

### 实验总结

#### 学会了 LLVM IR 的基本语法

其实没怎么看官方的文档，太多太杂了没耐心看，大概就只是浏览器翻了几页了解基本概念后，就开始看`clang -S -emit-llvm gcd.c`输出的文件了，不懂的地方再在网页里`Ctrl + F`。

#### 学会了用 CPP 编写 LLVM IR 生成器

参考了之前学长的`LLVM IR及工具链介绍`里面的例子和助教给的`gcd_generator.cpp`这个例子。了解了基本语法之后，剩下的就是对着你前面写的`*ll`文件逐句翻译了。

#### 关于 LLVM 的 Debug 和 Release 版
编译 LLVM 的时候，如前文所述，我选择的是 Debug 版，看着`bin`文件夹里面动不动 2GB 的文件，我很不甘心，于是就想尝试以下 Release。没想到，Release 版不仅编译更快、内存开销更小，而且生成的二进制文件也小得多，`llvm-install`文件夹只有 1.5GB。
我在自己的`$PATH`里面配置的是 Debug 版的 LLVM，但是后来在用 CPP 调用 LLVM IR 库的时候，我发现`c++ generator.cpp ... --std=c++14`特别慢，一般要等五秒以上。直到实验做完了，我才突然想到，我还有编译好的 Release 版啊！要不要测试一下它们两个的运行时间？！
于是，先写一个简易的脚本`run_10_times.sh`，它把实验中的四个 CPP 文件都编译了 10 遍。
```
#!/bin/bash
for i in {1..10}
do
    c++ assign_generator.cpp -o ./temp/assign_generator `llvm-config --cxxflags --ldflags --libs --system-libs` --std=c++14 
    c++ call_generator.cpp -o ./temp/call_generator `llvm-config --cxxflags --ldflags --libs --system-libs` --std=c++14
    c++ if_generator.cpp -o ./temp/if_generator `llvm-config --cxxflags --ldflags --libs --system-libs` --std=c++14
    c++ while_generator.cpp -o ./temp/while_generator `llvm-config --cxxflags --ldflags --libs --system-libs` --std=c++14
    echo "Round $i finished."
done
```
使用`time ./run_10_times.sh`运行脚本并获得时间信息。

首先在 Debug 版下，输出如下：
```
Round 1 finished.
Round 2 finished.
Round 3 finished.
Round 4 finished.
Round 5 finished.
Round 6 finished.
Round 7 finished.
Round 8 finished.
Round 9 finished.
Round 10 finished.

real    3m33.096s
user    3m3.642s
sys     0m28.688s
```
换到 Release 版，输出如下：
```
Round 1 finished.
Round 2 finished.
Round 3 finished.
Round 4 finished.
Round 5 finished.
Round 6 finished.
Round 7 finished.
Round 8 finished.
Round 9 finished.
Round 10 finished.

real    1m20.850s
user    1m9.221s
sys     0m11.153s
```
时间快三倍了！Debug 再见了您嘞🤐，现在已经换上 Release。

在 LLVM 的[文档](http://llvm.org/docs/GettingStarted.html#hardware)里看到下面这些。

> Note that Debug builds require a lot of time and disk space. An LLVM-only build will need about 1-3 GB of space. A full build of LLVM and Clang will need around 15-20 GB of disk space. The exact space requirements will vary by system. (It is so large because of all the debugging information and the fact that the libraries are statically linked into multiple tools). If you are space-constrained, you can build only selected tools or only selected targets. The Release build requires considerably less space.

> [Debug] These builds are the default. The build system will compile the tools and libraries unoptimized, with debugging information, and asserts enabled.

> [Release] For these builds, the build system will compile the tools and libraries with optimizations enabled and not generate debug info. CMakes default optimization level is -O3. This can be configured by setting the CMAKE_CXX_FLAGS_RELEASE variable on the CMake command line.

看起来 Debug 版本大是因为用到的所有库都静态链接了且未被优化，运行慢是因为运行的时候还在生成调试信息？看起来这里面可以仔细挖掘、能学习不少新东西的样子，但是我懒，算了🙄。

#### 吐槽

阅读 LLVM IR 的 Documentation 的时候，确实如助教所说，“不要陷入细节”，太繁杂了，为什么它没有类似 Quick Start 这样的东西。如果我足够 NB，能开发一个 NB 的东西，我在写文档的时候，一定要写完整的 API 文档、Quick Start、Learn by Examples 这三个部分。


#### 其它

自从 Visual Studio Code 支持 [Remote SSH](https://code.visualstudio.com/blogs/2019/07/25/remote-ssh) 之后，在我心里，它就不是地表最强 IDE 了。

而是宇宙最强。