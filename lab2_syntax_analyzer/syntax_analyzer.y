%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "common/common.h"
#include "syntax_tree/SyntaxTree.h"
#include "lab1_lexical_analyzer/lexical_analyzer.h"

// external functions from lex
extern int yylex();
extern int yyparse();
extern int yyrestart();
extern FILE *yyin;

// external variables from lexical_analyzer module
extern int yylineno;
extern int yyleng;
extern char *yytext;

// Global syntax tree.
SyntaxTree *gt;

void yyerror(const char * s);
%}

%union {
/********** Fill in this union structure *********/
char *id;
int num;
SyntaxTreeNode *tree_node;
}

/********** Your token definition here ***********/
%token ERROR 
%token ADD SUB MUL DIV
%token LT LTE GT GTE EQ NEQ
%token ASSIN SEMICOLON COMMA
%token LPARENTHESE RPARENTHESE LBRACKET RBRACKET LBRACE RBRACE
%token ELSE IF INT RETURN VOID WHILE
%token <id> IDENTIFIER
%token <num> NUMBER
%token ARRAY LETTER

%type <tree_node> program declaration-list declaration var-declaration fun-declaration 
%type <tree_node> params param-list param compound-stmt local-declarations
%type <tree_node> statement-list statement expression-stmt selection-stmt iteration-stmt return-stmt 
%type <tree_node> expression var simple-expression additive-expression 
%type <tree_node> term factor call args arg-list 
%type <tree_node> type-specifier relop addop mulop

/* compulsory starting symbol */
%start program

%%

/*************** Your rules here *****************/

program :
    declaration-list  {
        $$ = newSyntaxTreeNode("program");
        SyntaxTreeNode_AddChild($$, $1);
        gt->root = $$;
    };
declaration-list :
    declaration-list declaration  {
        $$=newSyntaxTreeNode("declaration-list");
        SyntaxTreeNode_AddChild($$, $1);
        SyntaxTreeNode_AddChild($$, $2);
    } |
    declaration  {
        $$=newSyntaxTreeNode("declaration-list");
        SyntaxTreeNode_AddChild($$, $1);
    };
declaration :
    var-declaration  {
        $$=newSyntaxTreeNode("declaration");
        SyntaxTreeNode_AddChild($$, $1);
    } |
    fun-declaration  {
        $$=newSyntaxTreeNode("declaration");
        SyntaxTreeNode_AddChild($$, $1);
    };
var-declaration :
    type-specifier IDENTIFIER SEMICOLON  {
        $$=newSyntaxTreeNode("var-declaration");
        SyntaxTreeNode_AddChild($$, $1);
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode($2));
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(actual_token_str(SEMICOLON)));
        free($2);
    } |
    type-specifier IDENTIFIER LBRACKET NUMBER RBRACKET SEMICOLON   {
        $$=newSyntaxTreeNode("var-declaration");
        SyntaxTreeNode_AddChild($$, $1);
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode($2));
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(actual_token_str(LBRACKET)));
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNodeFromNum($4));
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(actual_token_str(RBRACKET)));
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(actual_token_str(SEMICOLON)));
        free($2);
    };
type-specifier :
    INT  {
        $$=newSyntaxTreeNode("type-specifier");
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(actual_token_str(INT)));
    } |
    VOID  {
        $$=newSyntaxTreeNode("type-specifier");
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(actual_token_str(VOID)));
    };
fun-declaration :
    type-specifier IDENTIFIER LPARENTHESE params RPARENTHESE compound-stmt  {
        $$=newSyntaxTreeNode("fun-declaration");
        SyntaxTreeNode_AddChild($$, $1);
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode($2));
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(actual_token_str(LPARENTHESE)));
        SyntaxTreeNode_AddChild($$, $4);
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(actual_token_str(RPARENTHESE)));
        SyntaxTreeNode_AddChild($$, $6);
        free($2);
    };
params :
    param-list  {
        $$=newSyntaxTreeNode("params");
        SyntaxTreeNode_AddChild($$, $1);
    } |
    VOID  {
        $$=newSyntaxTreeNode("params");
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(actual_token_str(VOID)));
    };
param-list:
    param-list COMMA param  {
        $$=newSyntaxTreeNode("param-list");
        SyntaxTreeNode_AddChild($$, $1);
        SyntaxTreeNode_AddChild($$,  newSyntaxTreeNode(actual_token_str(COMMA)));
        SyntaxTreeNode_AddChild($$, $3);
    } |
    param  {
        $$=newSyntaxTreeNode("param-list");
        SyntaxTreeNode_AddChild($$, $1);
    };
param :
    type-specifier IDENTIFIER  {
        $$=newSyntaxTreeNode("param");
        SyntaxTreeNode_AddChild($$, $1);
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode($2));
        free($2);
    } |
    type-specifier IDENTIFIER ARRAY  {
        $$=newSyntaxTreeNode("param");
        SyntaxTreeNode_AddChild($$, $1);
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode($2));
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(actual_token_str(ARRAY)));
        free($2);
    };
compound-stmt :
    LBRACE local-declarations statement-list RBRACE  {
        $$=newSyntaxTreeNode("compound-stmt");
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(actual_token_str(LBRACE)));
        SyntaxTreeNode_AddChild($$, $2);
        SyntaxTreeNode_AddChild($$, $3);
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(actual_token_str(RBRACE)));
    };
local-declarations :
    local-declarations var-declaration  {
        $$=newSyntaxTreeNode("local-declarations");
        SyntaxTreeNode_AddChild($$, $1);
        SyntaxTreeNode_AddChild($$, $2);
    } |
    {
        $$=newSyntaxTreeNode("local-declarations");
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("epsilon"));
    };
statement-list :
    statement-list statement  {
        $$=newSyntaxTreeNode("statement-list");
        SyntaxTreeNode_AddChild($$, $1);
        SyntaxTreeNode_AddChild($$, $2);
    } |
    {
        $$=newSyntaxTreeNode("statement-list");
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("epsilon"));
    };
statement :
    expression-stmt  {
        $$=newSyntaxTreeNode("statement");
        SyntaxTreeNode_AddChild($$, $1);
    } |
    compound-stmt {
        $$=newSyntaxTreeNode("statement");
        SyntaxTreeNode_AddChild($$, $1);
    } |
    selection-stmt  {
        $$=newSyntaxTreeNode("statement");
        SyntaxTreeNode_AddChild($$, $1);
    } |
    iteration-stmt  {
        $$=newSyntaxTreeNode("statement");
        SyntaxTreeNode_AddChild($$, $1);
    } |
    return-stmt  {
        $$=newSyntaxTreeNode("statement");
        SyntaxTreeNode_AddChild($$, $1);
    };
expression-stmt :
    expression SEMICOLON  {
        $$=newSyntaxTreeNode("expression-stmt");
        SyntaxTreeNode_AddChild($$, $1);
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(actual_token_str(SEMICOLON)));
    } |
    SEMICOLON  {
        $$=newSyntaxTreeNode("expression-stmt");
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(actual_token_str(SEMICOLON)));
    };
selection-stmt :
    IF LPARENTHESE expression RPARENTHESE statement  {
        $$=newSyntaxTreeNode("selection-stmt");
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(actual_token_str(IF)));
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(actual_token_str(LPARENTHESE)));
        SyntaxTreeNode_AddChild($$, $3);
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(actual_token_str(RPARENTHESE)));
        SyntaxTreeNode_AddChild($$, $5);
    } |
    IF LPARENTHESE expression RPARENTHESE statement ELSE statement  {
        $$=newSyntaxTreeNode("selection-stmt");
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(actual_token_str(IF)));
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(actual_token_str(LPARENTHESE)));
        SyntaxTreeNode_AddChild($$, $3);
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(actual_token_str(RPARENTHESE)));
        SyntaxTreeNode_AddChild($$, $5);
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(actual_token_str(ELSE)));
        SyntaxTreeNode_AddChild($$, $7);
    };
iteration-stmt :
    WHILE LPARENTHESE expression RPARENTHESE statement  {
        $$=newSyntaxTreeNode("iteration-stmt");
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(actual_token_str(WHILE)));
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(actual_token_str(LPARENTHESE)));
        SyntaxTreeNode_AddChild($$, $3);
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(actual_token_str(RPARENTHESE)));
        SyntaxTreeNode_AddChild($$, $5);
    };
return-stmt :
    RETURN SEMICOLON  {
        $$=newSyntaxTreeNode("return-stmt");
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(actual_token_str(RETURN)));
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(actual_token_str(SEMICOLON)));
    } |
    RETURN expression SEMICOLON  {
        $$=newSyntaxTreeNode("return-stmt");
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(actual_token_str(RETURN)));
        SyntaxTreeNode_AddChild($$, $2);
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(actual_token_str(SEMICOLON)));
    };
expression :
    var ASSIN expression  {
        $$=newSyntaxTreeNode("expression");
        SyntaxTreeNode_AddChild($$, $1);
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(actual_token_str(ASSIN)));
        SyntaxTreeNode_AddChild($$, $3);
    } |
    simple-expression  {
        $$=newSyntaxTreeNode("expression");
        SyntaxTreeNode_AddChild($$, $1);
    };
var :
    IDENTIFIER  {
        $$=newSyntaxTreeNode("var");
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode($1));
        free($1);
    } |
    IDENTIFIER LBRACKET expression RBRACKET  {
        $$=newSyntaxTreeNode("var");
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode($1));
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(actual_token_str(LBRACKET)));
        SyntaxTreeNode_AddChild($$, $3);
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(actual_token_str(RBRACKET)));
        free($1);
    };
simple-expression :
    additive-expression relop additive-expression  {
        $$=newSyntaxTreeNode("simple-expression");
        SyntaxTreeNode_AddChild($$, $1);
        SyntaxTreeNode_AddChild($$, $2);
        SyntaxTreeNode_AddChild($$, $3);
    } |
    additive-expression  {
        $$=newSyntaxTreeNode("simple-expression");
        SyntaxTreeNode_AddChild($$, $1);
    };
relop :
    LTE  {
        $$=newSyntaxTreeNode("relop");
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(actual_token_str(LTE)));
    } |
    LT  {
        $$=newSyntaxTreeNode("relop");
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(actual_token_str(LT)));
    } |
    GT  {
        $$=newSyntaxTreeNode("relop");
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(actual_token_str(GT)));
    } |
    GTE  {
        $$=newSyntaxTreeNode("relop");
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(actual_token_str(GTE)));
    } |
    EQ  {
        $$=newSyntaxTreeNode("relop");
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(actual_token_str(EQ)));
    } |
    NEQ  {
        $$=newSyntaxTreeNode("relop");
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(actual_token_str(NEQ)));
    };
additive-expression :
    additive-expression addop term  {
        $$=newSyntaxTreeNode("additive-expression");
        SyntaxTreeNode_AddChild($$, $1);
        SyntaxTreeNode_AddChild($$, $2);
        SyntaxTreeNode_AddChild($$, $3);
    } |
    term   {
        $$=newSyntaxTreeNode("additive-expression");
        SyntaxTreeNode_AddChild($$, $1);
    };
addop :
    ADD  {
        $$=newSyntaxTreeNode("addop");
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(actual_token_str(ADD)));
    } |
    SUB  {
        $$=newSyntaxTreeNode("addop");
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(actual_token_str(SUB)));
    };
term :
    term mulop factor  {
        $$=newSyntaxTreeNode("term");
        SyntaxTreeNode_AddChild($$, $1);
        SyntaxTreeNode_AddChild($$, $2);
        SyntaxTreeNode_AddChild($$, $3);
    } |
    factor  {
        $$=newSyntaxTreeNode("term");
        SyntaxTreeNode_AddChild($$, $1);
    };
mulop :
    MUL  {
        $$=newSyntaxTreeNode("mulop");
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(actual_token_str(MUL)));
    } |
    DIV  {
        $$=newSyntaxTreeNode("mulop");
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(actual_token_str(DIV)));
    };
factor :
    LPARENTHESE expression RPARENTHESE  {
        $$=newSyntaxTreeNode("factor");
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(actual_token_str(LPARENTHESE)));
        SyntaxTreeNode_AddChild($$, $2);
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(actual_token_str(RPARENTHESE)));
    } |
    var  {
        $$=newSyntaxTreeNode("factor");
        SyntaxTreeNode_AddChild($$, $1);
    } |
    call  {
        $$=newSyntaxTreeNode("factor");
        SyntaxTreeNode_AddChild($$, $1);
    } |
    NUMBER  {
        $$=newSyntaxTreeNode("factor");
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNodeFromNum($1));
    };
call :
    IDENTIFIER LPARENTHESE args RPARENTHESE  {
        $$=newSyntaxTreeNode("call");
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode($1));
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(actual_token_str(LPARENTHESE)));
        SyntaxTreeNode_AddChild($$, $3);
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(actual_token_str(RPARENTHESE)));
        free($1);
    };
args :
    arg-list  {
        $$=newSyntaxTreeNode("args");
        SyntaxTreeNode_AddChild($$, $1);
    } |
    {
        $$=newSyntaxTreeNode("args");
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("epsilon"));
    };
arg-list :
    arg-list COMMA expression  {
        $$=newSyntaxTreeNode("arg-list");
        SyntaxTreeNode_AddChild($$, $1);
        SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(actual_token_str(COMMA)));
        SyntaxTreeNode_AddChild($$, $3);
    } |
    expression {
        $$=newSyntaxTreeNode("arg-list");
        SyntaxTreeNode_AddChild($$, $1);
    };
%%

void yyerror(const char *s) {
    fprintf(stderr, "%s. Syntax error for %s (Line:%d Length:%d)\n", s, yytext, yylineno, yyleng);
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
        fprintf(stderr, "[ERR] Open input file %s failed.", inputpath);
        exit(1);
    }
    yyrestart(yyin);
    printf("[START]: Syntax analysis start for %s\n", input);
    FILE * fp = fopen(outputpath, "w+");
    if (!fp) {
        return -1;
    }

    yylineno = 1;
    
    // yyerror() is invoked when yyparse fail. If you still want to check the return value, it's OK.
    // `while (!feof(yyin))` is not needed here. We only analyze once.
    yyparse();

    printf("[OUTPUT] Printing tree to output file %s\n", outputpath);
    printSyntaxTree(fp, gt);
    deleteSyntaxTree(gt);
    gt = 0;

    fclose(fp);
    printf("[END] Syntax analysis end for %s\n\n", input);
}

/// \brief starting function for testing syntax module.
///
/// Invoked in test_syntax.c
int syntax_main(int argc, char ** argv)
{
    char filename[FILE_MAX_NUMBER][NAME_MAX_LENGTH];
    char output_file_name[NAME_MAX_LENGTH];
    int files_count = getAllTestcase(filename);
    for (int i = 0;
         i < (files_count < FILE_MAX_NUMBER ? files_count : FILE_MAX_NUMBER);
         i++) {
        memset(output_file_name, 0, NAME_MAX_LENGTH);
        if (change_suffix(filename[i], output_file_name, ".cminus", ".syntax_tree") ==
            0) {
            syntax(filename[i], output_file_name);
        } else {
            printf("[ERR] Name and suffixs error\n");
            exit(1);
        }
    }
    return 0;
}
