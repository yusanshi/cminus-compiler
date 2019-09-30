%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "common/common.h"
#include "syntax_tree/SyntaxTree.h"

#include "lab1_lexical_analyzer/lexical_analyzer.h"

// external functions from lex
int yylex();
int yyparse();
extern FILE *yyin;

// external variables from lexical_analyzer module
extern int lines;
extern int pos_start;
extern char *yytext;

// Global syntax tree.
SyntaxTree *gt;

void yyerror(const char *s);
%}

%union {
/********** TODO: Fill in this union structure *********/
}

%token ERROR
%token ADD SUB MUL DIV
%token LT LTE GT GTE EQ NEQ
%token ASSIGN SEMICOLON COMMA
%token LPARENTHESE RPARENTHESE LBRACKET RBRACKET LBRACE RBRACE
%token ELSE IF INT RETURN VOID WHILE
%token IDENTIFIER NUMBER ARRAY LETTER EOL COMMENT BLANK

/* compulsory starting symbol */
%start program

%%
program : decl_list
        ;
decl_list : decl_list decl
          | decl
          ;
decl : var_decl
     | fun_decl
     ;
var_decl : type_spec IDENTIFIER SEMICOLON
         | type_spec IDENTIFIER LBRACKET NUMBER RBRACKET SEMICOLON
         ;
type_spec : INT
          | VOID
          ;
fun_decl : type_spec IDENTIFIER LPARENTHESE params RPARENTHESE cmpnd_stmt
         ;
params : param_list
       | VOID
       ;
param_list : param_list COMMA param
           | param
           ;
param : type_spec IDENTIFIER
      | type_spec IDENTIFIER ARRAY
      ;
cmpnd_stmt : LBRACE local_decls stmt_list RBRACE
           ;
local_decls : /* empty */
            | local_decls var_decl
            ;
stmt_list : /* empty */
          | stmt_list stmt
          ;
stmt : matched_stmt
     | open_stmt
     ;
matched_stmt : expr_stmt
             | cmpnd_stmt
             | IF LPARENTHESE expr matched_stmt ELSE matched_stmt
             | iter_stmt
             | ret_stmt
             ;
open_stmt : IF LPARENTHESE expr RPARENTHESE stmt
          | IF LPARENTHESE expr RPARENTHESE matched_stmt ELSE open_stmt
          ;
expr_stmt : expr SEMICOLON
          | SEMICOLON
          ;
iter_stmt : WHILE LPARENTHESE expr stmt
          ;
ret_stmt : RETURN SEMICOLON
         | RETURN expr SEMICOLON
         ;
expr : var ASSIGN expr
     | simple_expr
     ;
var : IDENTIFIER
    | IDENTIFIER LBRACKET expr RBRACKET
    ;
simple_expr : addi_expr relop addi_expr
            | addi_expr
            ;
relop : LT
      | LTE
      | GT
      | GTE
      | EQ
      | NEQ
      ;
addi_expr : addi_expr addop term
          | term
          ;
addop : ADD
      | SUB
      ;
term : term mulop factor
     | factor
     ;
mulop : MUL
      | DIV
      ;
factor : LPARENTHESE expr RPARENTHESE
       | var
       | call
       | NUMBER
       ;
call : IDENTIFIER LPARENTHESE args RPARENTHESE
     ;
args : /* empty */
     | arg_list
     ;
arg_list : arg_list COMMA expr
         | expr
         ;
%%

void yyerror(const char *s)
{
        // TODO: variables in Lab1 updates only in analyze() function in lexical_analyzer.l
        //       You need to move position updates to show error output below
        fprintf(stderr, "%s: %d:%d syntax error for %s\n", s, lines, pos_start, yytext);
}

/// \brief Syntax analysis from input file to output file
///
/// \param input basename of input file
/// \param output basename of output file
void syntax(const char *input, const char *output)
{
        gt = newSyntaxTree();

        char inputpath[256] = "./testcase/";
        char outputpath[256] = "./syntree/";
        strcat(inputpath, input);
        strcat(outputpath, output);

        if (!(yyin = fopen(inputpath, "r"))) {
                fprintf(stderr, "[ERR] Open input file %s failed.\n", inputpath);
                exit(1);
        }
        printf("[START]: Syntax analysis start for %s\n", input);
        FILE *fp = fopen(outputpath, "w+");
        if (!fp)
                return;

        // yyerror() is invoked when yyparse fail. If you still want to check
        // the return value, it's OK. `while (!feof(yyin))` is not needed
        // here. We only analyze once.
        yyparse();

        printf("[OUTPUT] Printing tree to output file %s\n", outputpath);
        printSyntaxTree(fp, gt);
        deleteSyntaxTree(gt);
        gt = NULL;

        fclose(fp);
        printf("[END] Syntax analysis end for %s\n", input);
}

/// \brief starting function for testing syntax module.
///
/// Invoked in test_syntax.c
int syntax_main(int argc, char ** argv)
{
        char filename[10][256];
        char output_file_name[256];
        const char *suffix = ".syntax_tree";
        int fn = getAllTestcase(filename);
        for (int i = 0; i < fn; i++) {
                int name_len = strstr(filename[i], ".cminus") - filename[i];
                strncpy(output_file_name, filename[i], name_len);
                strcpy(output_file_name + name_len, suffix);
                syntax(filename[i], output_file_name);
        }
        return 0;
}
