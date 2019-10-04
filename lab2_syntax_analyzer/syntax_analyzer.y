%{
#include "common/common.h"
#include "syntax_tree/SyntaxTree.h"

#include "lab1_lexical_analyzer/lexical_analyzer.h"

// external functions from lex
int yylex();
int yyparse();
int yyrestart();
extern FILE *yyin;

// external variables from lexical_analyzer module
extern int lines;
extern int pos_start;
extern int pos_end;
extern char *yytext;

// Global syntax tree.
SyntaxTree *gt;

void yyerror(const char *s);
%}

%union {
        char *strval;
        struct _SyntaxTreeNode *node;
}

%token ERROR
%token ADD SUB MUL DIV
%token LT LTE GT GTE EQ NEQ
%token ASSIGN SEMICOLON COMMA
%token LPARENTHESE RPARENTHESE LBRACKET RBRACKET LBRACE RBRACE
%token ELSE IF INT RETURN VOID WHILE
%token <strval> IDENTIFIER
%token <strval> NUMBER
%token ARRAY

%type <node> program decl_list decl var_decl type_spec fun_decl
%type <node> params param_list param
%type <node> cmpnd_stmt local_decls stmt_list stmt
%type <node> expr_stmt sele_stmt iter_stmt ret_stmt expr var simple_expr relop
%type <node> addi_expr addop term mulop factor call args arg_list

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

/* compulsory starting symbol */
%start program

%%
program : decl_list {
        gt->root = $1;
        }
        ;
decl_list : decl_list decl {
          $$ = $1;
          SyntaxTreeNode_AddChild($$, $2);
          }
          | decl {
          $$ = newSyntaxTreeNode("decl_list");
          SyntaxTreeNode_AddChild($$, $1);
          }
          ;
decl : var_decl {
     $$ = newSyntaxTreeNode("decl");
     SyntaxTreeNode_AddChild($$, $1);
     }
     | fun_decl {
     $$ = newSyntaxTreeNode("decl");
     SyntaxTreeNode_AddChild($$, $1);
     }
     ;
var_decl : type_spec IDENTIFIER SEMICOLON {
         $$ = newSyntaxTreeNode("var_decl");
         SyntaxTreeNode_AddChild($$, $1);
         SyntaxTreeNode_AddChild($$, newSyntaxTreeNode($2));
         SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(";"));
         free($2);
         }
         | type_spec IDENTIFIER LBRACKET NUMBER RBRACKET SEMICOLON {
         $$ = newSyntaxTreeNode("var_decl");
         SyntaxTreeNode_AddChild($$, $1);
         SyntaxTreeNode_AddChild($$, newSyntaxTreeNode($2));
         SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("["));
         SyntaxTreeNode_AddChild($$, newSyntaxTreeNode($4));
         SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("]"));
         SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(";"));
         free($2);
         free($4);
         }
         ;
type_spec : INT {
          $$ = newSyntaxTreeNode("type_spec");
          SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("int"));
          }
          | VOID {
          $$ = newSyntaxTreeNode("type_spec");
          SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("void"));
          }
          ;
fun_decl : type_spec IDENTIFIER LPARENTHESE params RPARENTHESE cmpnd_stmt {
         $$ = newSyntaxTreeNode("fun_decl");
         SyntaxTreeNode_AddChild($$, $1);
         SyntaxTreeNode_AddChild($$, newSyntaxTreeNode($2));
         SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("("));
         SyntaxTreeNode_AddChild($$, $4);
         SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(")"));
         SyntaxTreeNode_AddChild($$, $6);
         free($2);
         }
         ;
params : param_list {
       $$ = newSyntaxTreeNode("params");
       SyntaxTreeNode_AddChild($$, $1);
       }
       | VOID {
       $$ = newSyntaxTreeNode("params");
       SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("void"));
       }
       ;
param_list : param_list COMMA param {
           $$ = $1;
           SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(","));
           SyntaxTreeNode_AddChild($$, $3);
           }
           | param {
           $$ = newSyntaxTreeNode("param_list");
           SyntaxTreeNode_AddChild($$, $1);
           }
           ;
param : type_spec IDENTIFIER {
      $$ = newSyntaxTreeNode("param");
      SyntaxTreeNode_AddChild($$, $1);
      SyntaxTreeNode_AddChild($$, newSyntaxTreeNode($2));
      free($2);
      }
      | type_spec IDENTIFIER ARRAY {
      $$ = newSyntaxTreeNode("param");
      SyntaxTreeNode_AddChild($$, $1);
      SyntaxTreeNode_AddChild($$, newSyntaxTreeNode($2));
      SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("[]"));
      free($2);
      }
      ;
cmpnd_stmt : LBRACE local_decls stmt_list RBRACE {
           $$ = newSyntaxTreeNode("cmpnd_stmt");
           SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("{"));
           SyntaxTreeNode_AddChild($$, $2);
           SyntaxTreeNode_AddChild($$, $3);
           SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("}"));
           }
           ;
local_decls : /* empty */ {
            $$ = newSyntaxTreeNode("local_decls");
            }
            | local_decls var_decl {
            $$ = $1;
            SyntaxTreeNode_AddChild($$, $2);
            }
            ;
stmt_list : /* empty */ {
          $$ = newSyntaxTreeNode("stmt_list");
          }
          | stmt_list stmt {
          $$ = $1;
          SyntaxTreeNode_AddChild($$, $2);
          }
          ;
stmt : expr_stmt {
     $$ = newSyntaxTreeNode("stmt");
     SyntaxTreeNode_AddChild($$, $1);
     }
     | cmpnd_stmt {
     $$ = newSyntaxTreeNode("stmt");
     SyntaxTreeNode_AddChild($$, $1);
     }
     | sele_stmt {
     $$ = newSyntaxTreeNode("stmt");
     SyntaxTreeNode_AddChild($$, $1);
     }
     | iter_stmt {
     $$ = newSyntaxTreeNode("stmt");
     SyntaxTreeNode_AddChild($$, $1);
     }
     | ret_stmt {
     $$ = newSyntaxTreeNode("stmt");
     SyntaxTreeNode_AddChild($$, $1);
     }
     ;
sele_stmt : IF LPARENTHESE expr RPARENTHESE stmt %prec LOWER_THAN_ELSE {
          $$ = newSyntaxTreeNode("sele_stmt");
          SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("if"));
          SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("("));
          SyntaxTreeNode_AddChild($$, $3);
          SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(")"));
          SyntaxTreeNode_AddChild($$, $5);
          }
          | IF LPARENTHESE expr RPARENTHESE stmt ELSE stmt {
          $$ = newSyntaxTreeNode("sele_stmt");
          SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("if"));
          SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("("));
          SyntaxTreeNode_AddChild($$, $3);
          SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(")"));
          SyntaxTreeNode_AddChild($$, $5);
          SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("else"));
          SyntaxTreeNode_AddChild($$, $7);
          }
          ;
expr_stmt : expr SEMICOLON {
          $$ = newSyntaxTreeNode("expr_stmt");
          SyntaxTreeNode_AddChild($$, $1);
          SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(";"));
          }
          | SEMICOLON {
          $$ = newSyntaxTreeNode("expr_stmt");
          SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(";"));
          }
          ;
iter_stmt : WHILE LPARENTHESE expr RPARENTHESE stmt {
          $$ = newSyntaxTreeNode("iter_stmt");
          SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("while"));
          SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("("));
          SyntaxTreeNode_AddChild($$, $3);
          SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(")"));
          SyntaxTreeNode_AddChild($$, $5);
          }
          ;
ret_stmt : RETURN SEMICOLON {
         $$ = newSyntaxTreeNode("ret_stmt");
         SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("return"));
         SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(";"));
         }
         | RETURN expr SEMICOLON {
         $$ = newSyntaxTreeNode("ret_stmt");
         SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("return"));
         SyntaxTreeNode_AddChild($$, $2);
         SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(";"));
         }
         ;
expr : var ASSIGN expr {
     $$ = $3;  // TODO FIXME var and ASSIGN should be ahead of expr
     SyntaxTreeNode_AddChild($$, $1);
     SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("="));
     }
     | simple_expr {
     $$ = newSyntaxTreeNode("expr");
     SyntaxTreeNode_AddChild($$, $1);
     }
     ;
var : IDENTIFIER {
    $$ = newSyntaxTreeNode("var");
    SyntaxTreeNode_AddChild($$, newSyntaxTreeNode($1));
    free($1);
    }
    | IDENTIFIER LBRACKET expr RBRACKET {
    $$ = newSyntaxTreeNode("var");
    SyntaxTreeNode_AddChild($$, newSyntaxTreeNode($1));
    SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("["));
    SyntaxTreeNode_AddChild($$, $3);
    SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("]"));
    free($1);
    }
    ;
simple_expr : addi_expr relop addi_expr {
            $$ = newSyntaxTreeNode("simple_expr");
            SyntaxTreeNode_AddChild($$, $1);
            SyntaxTreeNode_AddChild($$, $2);
            SyntaxTreeNode_AddChild($$, $3);
            }
            | addi_expr {
            $$ = newSyntaxTreeNode("simple_expr");
            SyntaxTreeNode_AddChild($$, $1);
            }
            ;
relop : LT {
      $$ = newSyntaxTreeNode("relop");
      SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("<"));
      }
      | LTE {
      $$ = newSyntaxTreeNode("relop");
      SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("<="));
      }
      | GT {
      $$ = newSyntaxTreeNode("relop");
      SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(">"));
      }
      | GTE {
      $$ = newSyntaxTreeNode("relop");
      SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(">="));
      }
      | EQ {
      $$ = newSyntaxTreeNode("relop");
      SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("=="));
      }
      | NEQ {
      $$ = newSyntaxTreeNode("relop");
      SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("!="));
      }
      ;
addi_expr : addi_expr addop term {
          $$ = $1;
          SyntaxTreeNode_AddChild($$, $2);
          SyntaxTreeNode_AddChild($$, $3);
          }
          | term {
          $$ = newSyntaxTreeNode("addi_expr");
          SyntaxTreeNode_AddChild($$, $1);
          }
          ;
addop : ADD {
      $$ = newSyntaxTreeNode("addop");
      SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("+"));
      }
      | SUB {
      $$ = newSyntaxTreeNode("addop");
      SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("-"));
      }
      ;
term : term mulop factor {
     $$ = $1;
     SyntaxTreeNode_AddChild($$, $2);
     SyntaxTreeNode_AddChild($$, $3);
     }
     | factor {
     $$ = newSyntaxTreeNode("term");
     SyntaxTreeNode_AddChild($$, $1);
     }
     ;
mulop : MUL {
      $$ = newSyntaxTreeNode("mulop");
      SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("*"));
      }
      | DIV {
      $$ = newSyntaxTreeNode("mulop");
      SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("/"));
      }
      ;
factor : LPARENTHESE expr RPARENTHESE {
       $$ = newSyntaxTreeNode("factor");
       SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("("));
       SyntaxTreeNode_AddChild($$, $2);
       SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(")"));
       }
       | var {
       $$ = newSyntaxTreeNode("factor");
       SyntaxTreeNode_AddChild($$, $1);
       }
       | call {
       $$ = newSyntaxTreeNode("factor");
       SyntaxTreeNode_AddChild($$, $1);
       }
       | NUMBER {
       $$ = newSyntaxTreeNode("factor");
       SyntaxTreeNode_AddChild($$, newSyntaxTreeNode($1));
       free($1);
       }
       ;
call : IDENTIFIER LPARENTHESE args RPARENTHESE {
     $$ = newSyntaxTreeNode("call");
     SyntaxTreeNode_AddChild($$, newSyntaxTreeNode($1));
     SyntaxTreeNode_AddChild($$, newSyntaxTreeNode("("));
     SyntaxTreeNode_AddChild($$, $3);
     SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(")"));
     free($1);
     }
     ;
args : /* empty */ {
     $$ = newSyntaxTreeNode("args");
     }
     | arg_list {
     $$ = newSyntaxTreeNode("args");
     SyntaxTreeNode_AddChild($$, $1);
     }
     ;
arg_list : arg_list COMMA expr {
         $$ = $1;
         SyntaxTreeNode_AddChild($$, newSyntaxTreeNode(","));
         SyntaxTreeNode_AddChild($$, $3);
         }
         | expr {
         $$ = newSyntaxTreeNode("arg_list");
         SyntaxTreeNode_AddChild($$, $1);
         }
         ;
%%

void yyerror(const char *s)
{
        // TODO: variables in Lab1 updates only in analyze() function in lexical_analyzer.l
        //       You need to move position updates to show error output below
        fprintf(stderr, "%s: %d:%d syntax error near \"%s\"\n", s, lines, pos_start, yytext);
}

/// \brief Syntax analysis from input file to output file
///
/// \param input basename of input file
/// \param output basename of output file
void syntax(const char *input, const char *output)
{
        lines = pos_start = pos_end = 1;

        gt = newSyntaxTree();

        char inputpath[256] = "./testcase/";
        char outputpath[256] = "./syntree/";
        strcat(inputpath, input);
        strcat(outputpath, output);

        if (!(yyin = fopen(inputpath, "r"))) {
                fprintf(stderr, "[ERR] Open input file %s failed.\n", inputpath);
                exit(1);
        }
        yyrestart(yyin);
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
