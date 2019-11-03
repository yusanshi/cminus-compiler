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
    auto module = new Module("if.c", context);

    // define i32 @main()
    auto mainFunc = Function::Create(FunctionType::get(TYPE32, false),
                                     GlobalValue::LinkageTypes::ExternalLinkage,
                                     "main", module);
    // entry:
    auto entry = BasicBlock::Create(context, "entry", mainFunc);
    builder.SetInsertPoint(entry);
    // %cmp = icmp sgt i32 2, 1
    auto icmp = builder.CreateICmpSGT(CONST(2), CONST(1));
    auto trueBlock = BasicBlock::Create(context, "true", mainFunc);
    auto endBlock = BasicBlock::Create(context, "end", mainFunc);
    // br i1 %cmp, label %true, label %end
    auto br = builder.CreateCondBr(icmp, trueBlock, endBlock);

    // true:
    builder.SetInsertPoint(trueBlock);
    // ret i32 1
    builder.CreateRet(CONST(1));
    // br label %end
    builder.CreateBr(endBlock);

    // end:
    builder.SetInsertPoint(endBlock);
    // ret i32 0
    builder.CreateRet(CONST(0));

    builder.ClearInsertionPoint();
    module->print(outs(), nullptr);
    delete module;
    return 0;
}