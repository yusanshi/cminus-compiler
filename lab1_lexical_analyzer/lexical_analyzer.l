%option noyywrap
%option yylineno
%{
/*****************声明和选项设置  begin*****************/
#include <dirent.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>

#define NAME_MAX_LENGTH 256
#define FILE_MAX_NUMBER 64

enum cminus_token_type {
    ERROR = 258,
    ADD = 259,
    SUB = 260,
    MUL = 261,
    DIV = 262,
    LT = 263,
    LTE = 264,
    GT = 265,
    GTE = 266,
    EQ = 267,
    NEQ = 268,
    ASSIN = 269,
    SEMICOLON = 270,
    COMMA = 271,
    LPARENTHESE = 272,
    RPARENTHESE = 273,
    LBRACKET = 274,
    RBRACKET = 275,
    LBRACE = 276,
    RBRACE = 277,
    ELSE = 278,
    IF = 279,
    INT = 280,
    RETURN = 281,
    VOID = 282,
    WHILE = 283,
    IDENTIFIER = 284,
    NUMBER = 285,
    LETTER = 286,
    ARRAY = 287,
    EOL = 288,
    COMMENT = 289,
    BLANK = 290
};
/*****************end*****************/

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
[A-Za-z]+ {return IDENTIFIER;}
[0-9]+ {return NUMBER;}
"[]" {return ARRAY;}
\n {return EOL;}
"/*"([^*]|(\*+[^*/]))*"*"+"/" {return COMMENT;}
[ \t]+ {return BLANK;}
. {return ERROR;}

 /****  end******/
%%

/****************请按需求补全C代码 start*************/

/// \brief analysize a *.cminus file
///
///	\param input_file_name
/// \param output_file_name
/// \todo student should fill this function

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
    printf("[END]: Analysis completed.\n");
}

/// \brief get all file paths under 'testcase' directory
///
/// under 'testcase' directory, there could be many *.cminus files.
/// \todo student should fill this function
void getAllFilename(char *dir, char filename[][NAME_MAX_LENGTH],
                    int *files_count) {
    struct dirent *dp;
    DIR *dirp = opendir(dir);
    while ((dp = readdir(dirp)) != NULL) {
        if (strlen(dp->d_name) > strlen(".cminus")) {
            char *dot = strrchr(dp->d_name, '.');
            if (dot && !strcmp(dot, ".cminus")) {
                strcpy(filename[*files_count], dp->d_name);
                (*files_count)++;
            }
        }
    }
    closedir(dirp);
}

int change_suffix(char *source, char *dest, char *before, char *after) {
    if (strlen(source) < strlen(before)) {
        return -1;
    } else {
        strncpy(dest, source, strlen(source) - strlen(before));
        strcat(dest, after);
        return 0;
    }
}

/// \brief process all *.cminus file
///
/// note that: use relative path for all i/o operations
///	process all *.cminus files under 'testcase' directory,
/// then create *.tokens files under 'tokens' directory
/// \todo student should fill this function
int main(int argc, char **argv) {
    char filename[FILE_MAX_NUMBER][NAME_MAX_LENGTH];
    char output_file_name[NAME_MAX_LENGTH];
    char suffix[] = ".tokens";
    int files_count = 0;
    getAllFilename("./testcase/", filename, &files_count);
    for (int i = 0;
         i < (files_count < FILE_MAX_NUMBER ? files_count : FILE_MAX_NUMBER);
         i++) {
        memset(output_file_name, 0, NAME_MAX_LENGTH);
        if (change_suffix(filename[i], output_file_name, "cminus", "tokens") ==
            0) {
            analyzer(filename[i], output_file_name);
        } else {
            printf("[ERR] Name and suffixs error\n");
            exit(1);
        }
    }
    return 0;
}
/**************** end*************/
