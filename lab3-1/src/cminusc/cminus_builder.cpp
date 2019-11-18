#include "cminus_builder.hpp"
#include <iostream>

using namespace llvm;
using namespace std;

#define CONSTi32(num) ConstantInt::get(context, APInt(32, num))

static Function *curr_function = nullptr;

static Value *curr_expression_value = nullptr;
static Value *curr_addi_left_value = nullptr;
static Value *curr_addi_right_value = nullptr;
static Value *curr_factor_value = nullptr;
static Value *curr_term_value = nullptr;

// Exit code
// 101: ?
// 102: Not implemented.
// 103: Not found.
// 104: Return type unmatched.

void CminusBuilder::visit(syntax_program &node) {
    for (auto d : node.declarations) {
        d->accept(*this);
    }
}

void CminusBuilder::visit(syntax_num &node) {
    curr_factor_value = CONSTi32(node.value);
}

void CminusBuilder::visit(syntax_var_declaration &node) {
    GlobalVariable *gv;
    auto int_type = Type::getInt32Ty(this->context);
    if (!node.num.get()) {
        auto int_init = ConstantAggregateZero::get(int_type);
        gv = new GlobalVariable(*this->module.get(), int_type, false,
                                GlobalValue::LinkageTypes::CommonLinkage,
                                int_init, node.id);
    } else if (node.num->value < 0) {
        cerr << "syntax_var_declaration: array length is negative\n";
        exit(101);
    } else {
        auto array_type = ArrayType::get(int_type, node.num->value);
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
            if (p->isarray) {
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
    node.compound_stmt->accept(*this);
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
            auto type = ArrayType::get(i32_t, decl->num->value);
            auto val = this->builder.CreateAlloca(type);
            this->scope.push(decl->id, val);
        } else {
            // Int
            auto val = this->builder.CreateAlloca(i32_t);
            this->scope.push(decl->id, val);
        }
    }

    for (auto s : node.statement_list) {
        s->accept(*this);
    }

    this->scope.exit();
}

void CminusBuilder::visit(syntax_expresion_stmt &node) {
    node.expression->accept(*this);
}

void CminusBuilder::visit(syntax_selection_stmt &node) {
    //
}

void CminusBuilder::visit(syntax_iteration_stmt &node) {
    //
}

void CminusBuilder::visit(syntax_return_stmt &node) {
    if (node.expression) {  // return non-void;
        if (curr_function->getReturnType() == Type::getVoidTy(this->context)) {
            // Function defined to return void but actually return a non-void
            // value.
            cerr << "Void function should not return a value\n";
            exit(104);
        } else {
            node.expression->accept(*this);
            this->builder.CreateRet(curr_expression_value);
            curr_expression_value = nullptr;
        }
    } else {  // return;
        if (curr_function->getReturnType() == Type::getVoidTy(this->context)) {
            this->builder.CreateRetVoid();
        } else {
            // Function defined to return int but actually "return;"
            cerr << "Non-void function should return a value\n";
            exit(104);
        }
    }
}

void CminusBuilder::visit(syntax_var &node) {
    auto val_ptr = this->scope.find(node.id);
    if (!val_ptr) {
        cerr << "Name " << node.id << " not found\n";
        exit(103);
    }

    auto val = this->builder.CreateLoad(val_ptr);
    if (node.expression.get()) {
        // TODO
        cerr << "Array var not implemented\n";
        exit(102);
    }

    curr_factor_value = val;
}

void CminusBuilder::visit(syntax_assign_expression &node) {
    node.expression->accept(*this);
    if (node.var.get()) {
        auto var_ptr = this->scope.find(node.var->id);
        if (!var_ptr) {
            cerr << "Name " << node.var->id << " not found\n";
            exit(103);
        }
        this->builder.CreateStore(curr_expression_value, var_ptr);
    }
    // Pass out the curr_expression_value
}

void CminusBuilder::visit(syntax_simple_expression &node) {
    auto left_addi = node.additive_expression_l.get();
    left_addi->term->accept(*this);
    auto term_value = curr_term_value;
    curr_term_value = nullptr;
    if (left_addi->additive_expression.get()) {
        if (left_addi->op == OP_PLUS) {
            curr_addi_left_value =
                this->builder.CreateNSWAdd(curr_addi_left_value, term_value);
        } else if (left_addi->op == OP_MINUS) {
            curr_addi_left_value =
                this->builder.CreateNSWSub(curr_addi_left_value, term_value);
        }
    } else {
        curr_addi_left_value = term_value;
    }

    Value *simp_expr_val;
    auto right_addi = node.additive_expression_r.get();
    if (right_addi) {
        right_addi->term->accept(*this);
        auto term_value = curr_term_value;
        curr_term_value = nullptr;
        if (right_addi->additive_expression.get()) {
            if (right_addi->op == OP_PLUS) {
                curr_addi_right_value = this->builder.CreateNSWAdd(
                    curr_addi_right_value, term_value);
            } else if (right_addi->op == OP_MINUS) {
                curr_addi_right_value = this->builder.CreateNSWSub(
                    curr_addi_right_value, term_value);
            }
        } else {
            curr_addi_right_value = term_value;
        }

        Value *icmp;
        switch (node.op) {
        // <=
        case OP_LE:
            icmp = this->builder.CreateICmpSLE(curr_addi_left_value,
                                               curr_addi_right_value);
            break;
        // <
        case OP_LT:
            icmp = this->builder.CreateICmpSLT(curr_addi_left_value,
                                               curr_addi_right_value);
            break;
        // >
        case OP_GT:
            icmp = this->builder.CreateICmpSGT(curr_addi_left_value,
                                               curr_addi_right_value);
            break;
        // >=
        case OP_GE:
            icmp = this->builder.CreateICmpSGE(curr_addi_left_value,
                                               curr_addi_right_value);
            break;
        // ==
        case OP_EQ:
            icmp = this->builder.CreateICmpEQ(curr_addi_left_value,
                                              curr_addi_right_value);
            break;
        // !=
        case OP_NEQ:
            icmp = this->builder.CreateICmpNE(curr_addi_left_value,
                                              curr_addi_right_value);
        }
        simp_expr_val =
            this->builder.CreateZExt(icmp, Type::getInt32Ty(this->context));
    } else {
        simp_expr_val = curr_addi_left_value;
    }

    curr_expression_value = simp_expr_val;
}

void CminusBuilder::visit(syntax_additive_expression &node) {
    //
}

void CminusBuilder::visit(syntax_term &node) {
    node.factor->accept(*this);
    auto factor_value = curr_factor_value;
    curr_factor_value = nullptr;
    if (node.term.get()) {
        node.term->accept(*this);
        if (node.op == OP_MUL) {
            curr_term_value =
                this->builder.CreateNSWMul(curr_term_value, factor_value);
        } else if (node.op == OP_DIV) {
            curr_term_value =
                this->builder.CreateSDiv(curr_term_value, factor_value);
        }
    } else {
        curr_term_value = factor_value;
    }
}

void CminusBuilder::visit(syntax_call &node) {
    //
}
