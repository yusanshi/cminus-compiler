#include "cminus_builder.hpp"
#include <iostream>

using namespace llvm;
using namespace std;

static Function *curr_function = nullptr;
static Value *curr_expression_value = nullptr;

void CminusBuilder::visit(syntax_program &node) {
    for (auto d : node.declarations) {
        d.get()->accept(*this);
    }
}

void CminusBuilder::visit(syntax_num &node) {
    // Not needed
}

void CminusBuilder::visit(syntax_var_declaration &node) {
    GlobalVariable *gv;
    auto int_type = Type::getInt32Ty(this->context);
    if (!node.num.get()) {
        auto int_init = ConstantAggregateZero::get(int_type);
        gv = new GlobalVariable(*this->module.get(), int_type, false,
                                GlobalValue::LinkageTypes::CommonLinkage,
                                int_init, node.id);
    } else if (node.num.get()->value < 0) {
        cerr << "syntax_var_declaration: array length is negative\n";
        exit(101);
    } else {
        auto array_type = ArrayType::get(int_type, node.num.get()->value);
        auto array_init = ConstantAggregateZero::get(array_type);
        gv = new GlobalVariable(*this->module.get(), array_type, false,
                                GlobalValue::LinkageTypes::CommonLinkage,
                                array_init, node.id);
    }
    this->scope.push(node.id, gv);
}

void CminusBuilder::visit(syntax_fun_declaration &node) {
    auto type = (node.type == TYPE_INT) ? Type::getInt32Ty(this->context)
                                        : Type::getVoidTy(this->context);
    Function *func;
    if (node.params.empty()) {
        func = Function::Create(FunctionType::get(type, false),
                                GlobalValue::LinkageTypes::ExternalLinkage,
                                node.id, this->module.get());
    } else {
        vector<Type *> params;
        for (auto p : node.params) {
            if (p.get()->isarray) {
                params.push_back(Type::getInt32PtrTy(this->context));
            } else {
                params.push_back(Type::getInt32Ty(this->context));
            }
        }
        func = Function::Create(FunctionType::get(type, params, false),
                                GlobalValue::LinkageTypes::ExternalLinkage,
                                node.id, this->module.get());
    }
    this->scope.push(node.id, func);
    curr_function = func;
    node.compound_stmt.get()->accept(*this);
}

void CminusBuilder::visit(syntax_param &node) {
    // Not needed
}

void CminusBuilder::visit(syntax_compound_stmt &node) {
    if (!curr_function) {
        cerr << "syntax_compound_stmt: no function\n";
        exit(101);
    }
    auto entry = BasicBlock::Create(this->context, "", curr_function);
    this->builder.SetInsertPoint(entry);

    this->scope.enter();
    auto i32_t = Type::getInt32Ty(this->context);
    for (auto d : node.local_declarations) {
        auto decl = d.get();
        if (decl->num.get()) {
            // Array
            auto type = ArrayType::get(i32_t, decl->num.get()->value);
            auto val = this->builder.CreateAlloca(type);
            this->scope.push(decl->id, val);
        } else {
            // Int
            auto val = this->builder.CreateAlloca(i32_t);
            this->scope.push(decl->id, val);
        }
    }

    // TODO I'm not sure, may be wrong here.
    for (auto s : node.statement_list) {
        s.get()->accept(*this);
    }

    this->scope.exit();
}

void CminusBuilder::visit(syntax_expresion_stmt &node) {
    // auto expr = node.expression.get();
}

void CminusBuilder::visit(syntax_selection_stmt &node) {
    //
}

void CminusBuilder::visit(syntax_iteration_stmt &node) {
    //
}

void CminusBuilder::visit(syntax_return_stmt &node) {
    //
}

void CminusBuilder::visit(syntax_var &node) {
    //
}

void CminusBuilder::visit(syntax_assign_expression &node) {
    //
}

void CminusBuilder::visit(syntax_simple_expression &node) {
    //
}

void CminusBuilder::visit(syntax_additive_expression &node) {
    //
}

void CminusBuilder::visit(syntax_term &node) {
    //
}

void CminusBuilder::visit(syntax_call &node) {
    //
}
