#include "cminus_builder.hpp"

using namespace llvm;
using namespace std;

// You can define global variables here
// to store state

void CminusBuilder::visit(syntax_program &node) {
    //
    for (auto d : node.declarations) {
        d->accept(*this);
    }
}

void CminusBuilder::visit(syntax_num &node) {
    //
}

void CminusBuilder::visit(syntax_var_declaration &node) {
    //
}

void CminusBuilder::visit(syntax_fun_declaration &node) {
    auto type = (node.type == TYPE_INT) ? Type::getInt32Ty(this->context)
                                        : Type::getVoidTy(this->context);

    auto func =
        Function::Create(FunctionType::get(type, /* TODO: params ,*/ false),
                         GlobalValue::LinkageTypes::ExternalLinkage,
                         node.id.c_str(), this->module.get());
    this->scope.push(node.id, func);
}

void CminusBuilder::visit(syntax_param &node) {
    //
}

void CminusBuilder::visit(syntax_compound_stmt &node) {
    //
}

void CminusBuilder::visit(syntax_expresion_stmt &node) {
    //
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
