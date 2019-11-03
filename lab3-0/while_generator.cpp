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
    auto module = new Module("while.c", context);

    // define i32 @main()
    auto mainFunc = Function::Create(FunctionType::get(TYPE32, false),
                                     GlobalValue::LinkageTypes::ExternalLinkage,
                                     "main", module);
    // entry:
    auto entry = BasicBlock::Create(context, "entry", mainFunc);
    builder.SetInsertPoint(entry);
    // %a.memory = alloca i32
    auto aAlloca = builder.CreateAlloca(TYPE32);
    // %i.memory = alloca i32
    auto iAlloca = builder.CreateAlloca(TYPE32);
    // store i32 10, i32* %a.memory
    builder.CreateStore(CONST(10), aAlloca);
    // store i32 0, i32* %i.memory
    builder.CreateStore(CONST(0), iAlloca);
    auto whileJudgeBlock = BasicBlock::Create(context, "while.judge", mainFunc);
    auto whileContinueBlock =
        BasicBlock::Create(context, "while.continue", mainFunc);
    auto whileEndBlock = BasicBlock::Create(context, "while.end", mainFunc);
    // br label %while.judge
    builder.CreateBr(whileJudgeBlock);

    // while.judge:
    builder.SetInsertPoint(whileJudgeBlock);
    // %0 = load i32, i32* %i.memory
    auto iLoad = builder.CreateLoad(iAlloca);
    // %cmp = icmp slt i32 %0, 10
    auto icmp = builder.CreateICmpSLT(iLoad, CONST(10));
    // br i1 %cmp, label %while.continue, label %while.end
    builder.CreateCondBr(icmp, whileContinueBlock, whileEndBlock);

    // while.continue:
    builder.SetInsertPoint(whileContinueBlock);
    // %1 = load i32, i32* %i.memory
    iLoad = builder.CreateLoad(iAlloca);
    // %2 = add nsw i32 %1, 1
    auto add = builder.CreateNSWAdd(iLoad, CONST(1));
    // store i32 %2, i32* %i.memory
    builder.CreateStore(add, iAlloca);
    // %3 = load i32, i32* %a.memory
    auto aLoad = builder.CreateLoad(aAlloca);
    // %4 = load i32, i32* %i.memory
    iLoad = builder.CreateLoad(iAlloca);
    // %5 = add nsw i32 %3, %4
    add = builder.CreateNSWAdd(aLoad, iLoad);
    // store i32 %5, i32* %a.memory
    builder.CreateStore(add, aAlloca);
    // br label %while.judge
    builder.CreateBr(whileJudgeBlock);

    // while.end:
    builder.SetInsertPoint(whileEndBlock);
    // %6 = load i32, i32* %a.memory
    aLoad = builder.CreateLoad(aAlloca);
    // ret i32 %6
    builder.CreateRet(aLoad);

    builder.ClearInsertionPoint();
    module->print(outs(), nullptr);
    delete module;
    return 0;
}