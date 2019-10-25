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
    auto module = new Module("assign", context);
    IRBuilder<> builder(context);
    auto i32_t = Type::getInt32Ty(context);

    // main function
    auto main_f = Function::Create(FunctionType::get(i32_t, false),
                                   GlobalValue::LinkageTypes::ExternalLinkage,
                                   "main", module);
    auto bb = BasicBlock::Create(context, "entry", main_f);

    // allocate for `a` and store a value
    builder.SetInsertPoint(bb);
    auto alloc_a = builder.CreateAlloca(i32_t);
    builder.CreateStore(CONSTi32(1), alloc_a);

    // get the value of `a` and return it
    auto load_a = builder.CreateLoad(alloc_a);
    builder.CreateRet(load_a);

    module->print(outs(), nullptr);
    delete module;
    return 0;
}
