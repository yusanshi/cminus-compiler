# lab3-0 实验报告
汪若辰

PB17000098

## 实验要求
分别直接写出和使用 C++ 程序生成四个 C 程序的 LLVM IR.

## 实验结果
以 `while_generator.cpp` 为例。

#### 定义函数和 basic block
定义了四个 basic block, `entry`, `check`, `do` 和 `done`，分别对应初始化、检查循环条件、循环体和循环结束部分。
```cpp
// main function and basic blocks
auto main_f = Function::Create(FunctionType::get(i32_t, false),
                               GlobalValue::LinkageTypes::ExternalLinkage,
                               "main", module);
auto bb_entry = BasicBlock::Create(context, "entry", main_f);
auto bb_check = BasicBlock::Create(context, "check", main_f);
auto bb_do = BasicBlock::Create(context, "do", main_f);
auto bb_done = BasicBlock::Create(context, "done", main_f);
```

#### 初始化
初始化后跳转到 `check`.

LLVM:
```llvm
  ; define variables
  %a = alloca i32
  %i = alloca i32
  store i32 0, i32* %i
  store i32 10, i32* %a
  br label %check
```

C++:
```cpp
// define `i` and `a` and store init values
builder.SetInsertPoint(bb_entry);
auto alloc_a = builder.CreateAlloca(i32_t);
builder.CreateStore(CONSTi32(10), alloc_a);
auto alloc_i = builder.CreateAlloca(i32_t);
builder.CreateStore(CONSTi32(0), alloc_i);
builder.CreateBr(bb_check);
```

#### 判断 `while` 循环的条件
判断为真则跳到循环体，为假则跳到循环体之后。

LLVM:
```llvm
check:
  %i-load = load i32, i32* %i
  %cmp = icmp slt i32 %i-load, 10
  br i1 %cmp, label %do, label %done
```

C++:
```cpp
// while (i < 10) {
builder.SetInsertPoint(bb_check);
auto load_i = builder.CreateLoad(alloc_i);
auto cond = builder.CreateICmpSLT(load_i, CONSTi32(10));
builder.CreateCondBr(cond, bb_do, bb_done);
```

#### 循环体
循环结束后跳回判断循环条件的 basic block.

LLVM:
```llvm
do:
  ; i = i + 1
  %i-add = add i32 %i-load, 1
  store i32 %i-add, i32* %i
  ; a = a + i
  %a-load = load i32, i32* %a
  %a-add = add i32 %i-add, %a-load
  store i32 %a-add, i32* %a
  br label %check
```

C++:
```cpp
// loop body
builder.SetInsertPoint(bb_do);
auto add_i = builder.CreateAdd(load_i, CONSTi32(1));  // i = i + 1
builder.CreateStore(add_i, alloc_i);
auto load_a = builder.CreateLoad(alloc_a);
auto add_a = builder.CreateAdd(load_a, add_i);  // a = a + i
builder.CreateStore(add_a, alloc_a);
builder.CreateBr(bb_check);
// }  // while
```

#### 循环结束
LLVM:
```llvm
done:
  ; return a
  %ret = load i32, i32* %a
  ret i32 %ret
```

C++:
```cpp
// return a
builder.SetInsertPoint(bb_done);
load_a = builder.CreateLoad(alloc_a);
builder.CreateRet(load_a);
```

## 实验难点
找不到比较清晰的 LLVM 文档，导致不知道去哪里查函数的具体用法，如参数等。在网上搜一些例子就可以知道怎么写了。

## 实验总结
在本次试验中我对 LLVM IR 有了基本的认识，还知道了如何利用 C++ 程序生成 LLVM IR，为后续的实验打下了基础。
