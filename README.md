# Cminus Compiler

This is course project of Principles of Compiler. We have built a compiler for C Minus programming language.

## Team
**Members**

- [weirane](https://github.com/weirane) (Team leader)
- Me

We got full marks in every subtask.😁


## Lab
### Lab1
Lexical analyzer.
```bash
# in project root dir

# build
./do_cmake.sh && make -C build/

# generate tokens
./build/test_lex

# compare
diff tokens/gcd.tokens lab1/TA_tokens/gcd.tokens
```

### Lab2
Syntax analyzer.
```bash
# in project root dir

# build
./do_cmake.sh && make -C build/

# generate syntex tree
./build/test_syntax

# compare
diff syntree lab2/TA_syntree
```
### Lab3
#### Lab3-0
Build LLVM. Handcraft several LLVM IR files and LLVM IR generators.

See [README.md](lab3-0/README.md#12-下载llvm-801源码并编译) to build LLVM.

```bash
# in lab3-0 dir

# test IR files
lli assign_hand.ll ; echo $?
lli call_hand.ll ; echo $?
lli if_hand.ll ; echo $?
lli while_hand.ll ; echo $?

# test IR generators
mkdir temp
c++ assign_generator.cpp -o ./temp/assign_generator `llvm-config --cxxflags --ldflags --libs --system-libs` --std=c++14 && ./temp/assign_generator > ./temp/assign_generated.ll && lli ./temp/assign_generated.ll ; echo $?
c++ call_generator.cpp -o ./temp/call_generator `llvm-config --cxxflags --ldflags --libs --system-libs` --std=c++14 && ./temp/call_generator > ./temp/call_generated.ll && lli ./temp/call_generated.ll ; echo $?
c++ if_generator.cpp -o ./temp/if_generator `llvm-config --cxxflags --ldflags --libs --system-libs` --std=c++14 && ./temp/if_generator > ./temp/if_generated.ll && lli ./temp/if_generated.ll ; echo $?
c++ while_generator.cpp -o ./temp/while_generator `llvm-config --cxxflags --ldflags --libs --system-libs` --std=c++14 && ./temp/while_generator > ./temp/while_generated.ll && lli ./temp/while_generated.ll ; echo $?
```
#### Lab3-1

LLVM IR generator.
```bash
# in lab3-1 dir

# build `cminusc` executable file
mkdir build && cd build
cmake .. -DLLVM_DIR=/path/to/your/llvm/install/lib/cmake/llvm/
make -j

## test `cminusc` executable file
../test.sh
```
#### Lab3-2
We are required to read source code about LLVM Pass. No need for coding.

### Lab4
We are required to read source code about reigster allocation in LLVM. No need for coding.