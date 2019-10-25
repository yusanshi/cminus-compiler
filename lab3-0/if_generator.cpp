#include <llvm/IR/BasicBlock.h>
#include <llvm/IR/Constants.h>
#include <llvm/IR/DerivedTypes.h>
#include <llvm/IR/Function.h>
#include <llvm/IR/IRBuilder.h>
#include <llvm/IR/LLVMContext.h>
#include <llvm/IR/Module.h>
#include <llvm/IR/Type.h>

using namespace llvm;

#define CONSTi32(num) ConstantInt::get(context, APInt(32, num))

int main(void) {
    LLVMContext context;
    auto module = new Module("if", context);
    IRBuilder<> builder(context);
    auto i32_t = Type::getInt32Ty(context);

    // main function and basic blocks
    auto main_f = Function::Create(FunctionType::get(i32_t, false),
                                   GlobalValue::LinkageTypes::ExternalLinkage,
                                   "main", module);
    auto bb = BasicBlock::Create(context, "entry", main_f);
    auto cond_true = BasicBlock::Create(context, "cond_true", main_f);
    auto cond_false = BasicBlock::Create(context, "cond_false", main_f);
    builder.SetInsertPoint(bb);

    // do the comparison
    auto cond = builder.CreateICmpSGT(CONSTi32(2), CONSTi32(1));
    builder.CreateCondBr(cond, cond_true, cond_false);

    // cond is true
    builder.SetInsertPoint(cond_true);
    builder.CreateRet(CONSTi32(1));

    // cond is false
    builder.SetInsertPoint(cond_false);
    builder.CreateRet(CONSTi32(0));

    module->print(outs(), nullptr);
    delete module;
    return 0;
}
