%option noyywrap
%option yylineno
%{
/*****************声明和选项设置  begin*****************/
#include <stdio.h>
#include <stdlib.h>

#include "common/common.h"
#include "syntax_tree/SyntaxTree.h"
#include "lab1_lexical_analyzer/lexical_analyzer.h"

#ifndef LAB1_ONLY
#include "syntax_analyzer.h"
#endif


/*****************声明和选项设置  end*****************/

%}

%%

 /****请在此补全所有flex的模式与动作  start******/
"+" {return ADD;}
"-" {return SUB;}
"*" {return MUL;}
"/" {return DIV;}
"<" {return LT;}
"<=" {return LTE;}
">" {return GT;}
">=" {return GTE;}
"==" {return EQ;}
"!=" {return NEQ;}
"=" {return ASSIN;}
";" {return SEMICOLON;}
"," {return COMMA;}
"(" {return LPARENTHESE;}
")" {return RPARENTHESE;}
"[" {return LBRACKET;}
"]" {return RBRACKET;}
"{" {return LBRACE;}
"}" {return RBRACE;}
"else" {return ELSE;}
"if" {return IF;}
"int" {return INT;}
"return" {return RETURN;}
"void" {return VOID;}
"while" {return WHILE;}
[A-Za-z]+ {
        #ifndef LAB1_ONLY
        yylval.id = strdup(yytext);
        #endif
        return IDENTIFIER;
    }
[0-9]+ {
        #ifndef LAB1_ONLY
        yylval.num = atoi(yytext);
        #endif
        return NUMBER;
    }
"[]" {return ARRAY;}
\n { 
        #ifdef LAB1_ONLY
        return EOL;
        #endif
    }
"/*"([^*]|(\*+[^*/]))*"*"+"/" { 
        #ifdef LAB1_ONLY
        return COMMENT;
        #endif
    }
[ \t]+ { 
        #ifdef LAB1_ONLY
        return BLANK;
        #endif
    }
. {return ERROR;}

 /****请在此补全所有flex的模式与动作  end******/
%%

/****************C代码 start*************/

/// \brief analysize a *.cminus file
///
///	\param input_file_name
/// \param output_file_name
void analyzer(char *input_file_name, char *output_file_name) {
    char input_path[NAME_MAX_LENGTH] = "./testcase/";
    strcat(input_path, input_file_name);
    char output_path[NAME_MAX_LENGTH] = "./tokens/";
    strcat(output_path, output_file_name);
    if (!(yyin = fopen(input_path, "r"))) {
        printf("[ERR] No input file\n");
        exit(1);
    }
    printf("[START]: Read from: %s\n", input_file_name);
    FILE *fp = fopen(output_path, "w+");
    int column = 1;
    yylineno = 1;
    int token;
    char *last_lf;  // used in case LF is in a comment, thus may cause a
                    // incorrent column value.
    while (token = yylex()) {
        switch (token) {
            case ERROR:
                fprintf(fp,
                        "[ERR]: unable to analysize %s at %d line, from %d to "
                        "%d\n",
                        yytext, yylineno, column, (int)(column + yyleng));
                column += yyleng;
                break;
            case COMMENT:
                last_lf = strrchr(yytext, '\n');
                if (last_lf == NULL) {
                    column += yyleng;  // LF not found in comment, add column
                                       // normally.
                } else {
                    column = strlen(last_lf); // LF found, so adjust column
                }
                break;
            case BLANK:
                column += yyleng;
                break;
            case EOL:
                column = 1;
                break;
            default:
                fprintf(fp, "%s\t%d\t%d\t%d\t%d\n", yytext, token, yylineno,
                        column, (int)(column + yyleng));
                column += yyleng;
        }
    }
    fclose(fp);
    printf("[END]: Analysis completed.\n\n");
}


/// \brief process all *.cminus file
///
/// note that: use relative path for all i/o operations
///	process all *.cminus files under 'testcase' directory,
/// then create *.tokens files under 'tokens' directory
int lex_main(int argc, char **argv) {
    char filename[FILE_MAX_NUMBER][NAME_MAX_LENGTH];
    char output_file_name[NAME_MAX_LENGTH];
    int files_count = getAllTestcase(filename);
    for (int i = 0;
         i < (files_count < FILE_MAX_NUMBER ? files_count : FILE_MAX_NUMBER);
         i++) {
        memset(output_file_name, 0, NAME_MAX_LENGTH);
        if (change_suffix(filename[i], output_file_name, ".cminus", ".tokens") ==
            0) {
            analyzer(filename[i], output_file_name);
        } else {
            printf("[ERR] Name and suffixs error\n");
            exit(1);
        }
    }
    return 0;

}
/****************C代码 end*************/
