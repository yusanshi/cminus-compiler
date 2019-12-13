# lab4实验报告
组长 汪若辰 PB17000098

小组成员 余磊 PB17051053

## 实验要求

请按照自己的理解，写明本次实验需要干什么

## 报告内容 
### 1. RISC-V 机器代码的生成和运行
- LLVM 8.0.1 适配 RISC-V 并安装 spike 模拟器

    ...

    或者如果使用的 Linux 发行版是 Arch 系的话，可以直接使用 `pacman` 安装 `riscv64-linux-gnu-gcc` 和 `spike` 并安装 AUR 中的 `riscv-pk-git`。

- 将 gcd 样例编译到 RISC-V 汇编

- 汇编上述生成的 RISC-V 汇编并利用 spike 执行

写一个简单的 [Makefile](../test/Makefile) 来自动化编译和运行的过程。例如在编译 `gcd.c` 时使用 `make gcd`，运行时 `make run gcd`。省去自己打命令的麻烦。


### 2. LLVM 源码阅读与理解
#### `RegAllocFast.cpp` 中的问题
- `RegAllocFast` 函数的执行流程？

- `allocateInstruction` 函数有几次扫描过程以及每一次扫描的功能？

- `calcSpillCost` 函数的执行流程？

- `hasTiedOps`，`hasPartialRedefs`，`hasEarlyClobbers` 变量的作用？

#### 书上算法与 LLVM 的实现之间的不同点


## 组内讨论内容

## 实验总结

此次实验有什么收获

## 实验反馈
- 怎么又把 PDF 文件放到仓库里面了（gbxu/notice_board#177）
