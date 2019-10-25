#include <llvm/IR/BasicBlock.h>
#include <llvm/IR/Constants.h>
#include <llvm/IR/DerivedTypes.h>
#include <llvm/IR/Function.h>
#include <llvm/IR/IRBuilder.h>
#include <llvm/IR/LLVMContext.h>
#include <llvm/IR/Module.h>
#include <llvm/IR/Type.h>
#include <vector>

using namespace llvm;

#define CONSTi32(num) ConstantInt::get(context, APInt(32, num))

int main(void) {
    LLVMContext context;
    auto module = new Module("call", context);
    IRBuilder<> builder(context);
    auto i32_t = Type::getInt32Ty(context);

    // callee function
    auto callee_f = Function::Create(
        FunctionType::get(i32_t, std::vector<Type *>{i32_t}, false),
        GlobalValue::LinkageTypes::ExternalLinkage, "callee", module);
    auto callee_entry = BasicBlock::Create(context, "entry", callee_f);

    // do the calculation and return it
    builder.SetInsertPoint(callee_entry);
    auto callee_arg = callee_f->arg_begin();
    auto callee_ret = builder.CreateAdd(callee_arg, callee_arg);
    builder.CreateRet(callee_ret);

    // main function
    auto main_f = Function::Create(FunctionType::get(i32_t, false),
                                   GlobalValue::LinkageTypes::ExternalLinkage,
                                   "main", module);
    auto bb_entry = BasicBlock::Create(context, "entry", main_f);

    // call the function with argument 10
    builder.SetInsertPoint(bb_entry);
    auto call_arg = std::vector<Value *>{CONSTi32(10)};
    auto call = builder.CreateCall(callee_f, call_arg);
    builder.CreateRet(call);

    module->print(outs(), nullptr);
    delete module;
    return 0;
}
