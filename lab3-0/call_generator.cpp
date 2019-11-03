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
    auto module = new Module("call.c", context);

    std::vector<Type *> Ints(1, TYPE32);

    // define i32 @callee(i32 %a)
    auto calleeFunc = Function::Create(
        FunctionType::get(TYPE32, Ints, false),
        GlobalValue::LinkageTypes::ExternalLinkage, "callee", module);

    // entry:
    auto entry = BasicBlock::Create(context, "entry", calleeFunc);
    builder.SetInsertPoint(entry);
    // %a.memory = alloca i32
    auto aAlloca = builder.CreateAlloca(TYPE32);
    std::vector<Value *> args;
    for (auto arg = calleeFunc->arg_begin(); arg != calleeFunc->arg_end();
         arg++) {
        args.push_back(arg);
    }
    // store i32 %a, i32* %a.memory
    builder.CreateStore(args[0], aAlloca);
    // %0 = load i32, i32* %a.memory
    auto aLoad = builder.CreateLoad(aAlloca);
    // %1 = mul nsw i32 %0, 2
    auto mul = builder.CreateNSWMul(aLoad, CONST(2));
    // ret i32 %1
    builder.CreateRet(mul);

    // define i32 @main()
    auto mainFunc = Function::Create(FunctionType::get(TYPE32, false),
                                     GlobalValue::LinkageTypes::ExternalLinkage,
                                     "main", module);
    // entry:
    entry = BasicBlock::Create(context, "entry", mainFunc);
    builder.SetInsertPoint(entry);

    // %0 = call i32 @callee(i32 10)
    auto call = builder.CreateCall(calleeFunc, {CONST(10)});
    // ret i32 %0
    builder.CreateRet(call);

    builder.ClearInsertionPoint();
    module->print(outs(), nullptr);
    delete module;
    return 0;
}