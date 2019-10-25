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
    auto module = new Module("while", context);
    IRBuilder<> builder(context);
    auto i32_t = Type::getInt32Ty(context);

    // main function and basic blocks
    auto main_f = Function::Create(FunctionType::get(i32_t, false),
                                   GlobalValue::LinkageTypes::ExternalLinkage,
                                   "main", module);
    auto bb_entry = BasicBlock::Create(context, "entry", main_f);
    auto bb_check = BasicBlock::Create(context, "check", main_f);
    auto bb_do = BasicBlock::Create(context, "do", main_f);
    auto bb_done = BasicBlock::Create(context, "done", main_f);

    // define `i` and `a` and store init values
    builder.SetInsertPoint(bb_entry);
    auto alloc_a = builder.CreateAlloca(i32_t);
    builder.CreateStore(CONSTi32(10), alloc_a);
    auto alloc_i = builder.CreateAlloca(i32_t);
    builder.CreateStore(CONSTi32(0), alloc_i);
    builder.CreateBr(bb_check);

    // while (i < 10) {
    builder.SetInsertPoint(bb_check);
    auto load_i = builder.CreateLoad(alloc_i);
    auto cond = builder.CreateICmpSLT(load_i, CONSTi32(10));
    builder.CreateCondBr(cond, bb_do, bb_done);

    // loop body
    builder.SetInsertPoint(bb_do);
    auto add_i = builder.CreateAdd(load_i, CONSTi32(1));  // i = i + 1
    builder.CreateStore(add_i, alloc_i);
    auto load_a = builder.CreateLoad(alloc_a);
    auto add_a = builder.CreateAdd(load_a, add_i);  // a = a + i
    builder.CreateStore(add_a, alloc_a);
    builder.CreateBr(bb_check);
    // }  // while

    // return a
    builder.SetInsertPoint(bb_done);
    load_a = builder.CreateLoad(alloc_a);
    builder.CreateRet(load_a);

    module->print(outs(), nullptr);
    delete module;
    return 0;
}
