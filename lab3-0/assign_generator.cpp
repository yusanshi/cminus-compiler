#include <llvm/IR/BasicBlock.h>
#include <llvm/IR/Constants.h>
#include <llvm/IR/DerivedTypes.h>
#include <llvm/IR/Function.h>
#include <llvm/IR/IRBuilder.h>
#include <llvm/IR/LLVMContext.h>
#include <llvm/IR/Module.h>
#include <llvm/IR/Type.h>
#include <llvm/IR/Verifier.h>

#include <iostream>

using namespace llvm;
#define CONST(num) ConstantInt::get(context, APInt(32, num))

int main() {
    LLVMContext context;
    Type *TYPE32 = Type::getInt32Ty(context);
    IRBuilder<> builder(context);
    auto module = new Module("assign.c", context);

    // define i32 @main()
    auto mainFunc = Function::Create(FunctionType::get(TYPE32, false),
                                     GlobalValue::LinkageTypes::ExternalLinkage,
                                     "main", module);
    // entry:
    auto entry = BasicBlock::Create(context, "entry", mainFunc);
    builder.SetInsertPoint(entry);

    // %a.memory = alloca i32
    auto aAlloca = builder.CreateAlloca(TYPE32);
    // store i32 1, i32* %a.memory
    builder.CreateStore(CONST(1), aAlloca);
    // %0 = load i32, i32* %a.memory
    auto aLoad = builder.CreateLoad(aAlloca);
    // ret i32 %0
    builder.CreateRet(aLoad);

    builder.ClearInsertionPoint();
    module->print(outs(), nullptr);
    delete module;
    return 0;
}