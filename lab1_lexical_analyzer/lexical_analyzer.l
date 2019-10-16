%option noyywrap
%{
/*****************声明和选项设置  begin*****************/

#include "lab1_lexical_analyzer/lexical_analyzer.h"
#include "common/common.h"

#ifndef LAB1_ONLY
#include "syntax_analyzer.h"
#endif

int lines;
int pos_start;
int pos_end;

static int count_new_line(const char *str, int *after_nl);
static int str_ends_with(const char *str, const char *ending);

#define BUMP_POS(n)                       \
        do {                              \
                pos_start = pos_end;      \
                pos_end = pos_start + n;  \
        } while(0)
%}

commentPattern "/*"([^\*]|(\*)*[^\*/])*(\*)*"*/"
identifierPattern [a-zA-Z][a-zA-Z]*

%%

 /****请在此补全所有flex的模式与动作  start******/

\/\*([^*/]|[^*]\/+|\*+[^/])*\*+\/ {
        int after_nl;
        lines += count_new_line(yytext, &after_nl);
        if (after_nl != 0) {
                pos_start = pos_end = after_nl + 1;
        } else {
                BUMP_POS(strlen(yytext));
        }
#ifdef LAB1_ONLY
        return COMMENT;
#endif
}
"[]" { BUMP_POS(2); return ARRAY; }

 /* ops */
"+" { BUMP_POS(1); return ADD; }
"-" { BUMP_POS(1); return SUB; }
"*" { BUMP_POS(1); return MUL; }
"/" { BUMP_POS(1); return DIV; }
"<=" { BUMP_POS(2); return LTE; }
"<" { BUMP_POS(1); return LT; }
">=" { BUMP_POS(2); return GTE; }
">" { BUMP_POS(1); return GT; }
"==" { BUMP_POS(2); return EQ; }
"!=" { BUMP_POS(2); return NEQ; }
"=" { BUMP_POS(1); return ASSIN; }
";" { BUMP_POS(1); return SEMICOLON; }
"," { BUMP_POS(1); return COMMA; }
"(" { BUMP_POS(1); return LPARENTHESE; }
")" { BUMP_POS(1); return RPARENTHESE; }
"[" { BUMP_POS(1); return LBRACKET; }
"]" { BUMP_POS(1); return RBRACKET; }
"{" { BUMP_POS(1); return LBRACE; }
"}" { BUMP_POS(1); return RBRACE; }

 /* keywords */
"else" { BUMP_POS(4); return ELSE; }
"if" { BUMP_POS(2); return IF; }
"int" { BUMP_POS(3); return INT; }
"return" { BUMP_POS(6); return RETURN; }
"void" { BUMP_POS(4); return VOID; }
"while" { BUMP_POS(5); return WHILE; }

[a-zA-Z]+ {
#ifndef LAB1_ONLY
        yylval.strval = strdup(yytext);
#endif
        BUMP_POS(strlen(yytext));
        return IDENTIFIER;
}
[0-9]+ {
#ifndef LAB1_ONLY
        yylval.strval = strdup(yytext);
#endif
        BUMP_POS(strlen(yytext));
        return NUMBER;
}

"\n" {
        pos_end = pos_start = 1;
        lines++;
#ifdef LAB1_ONLY
        return EOL;
#endif
}
[ \t] {
        BUMP_POS(1);
#ifdef LAB1_ONLY
        return BLANK;
#endif
}
. { return ERROR; }



 /****请在此补全所有flex的模式与动作  end******/
%%
/****************C代码 start*************/

/// \brief analysize a *.cminus file
///
/// \param input_file_name
/// \param output_file_name
/// \todo student should fill this function
void analyzer(char *input_file_name, char *output_file_name)
{
        // Setup
        lines = 1;
        pos_start = 1;
        pos_end = 1;

        // Meddle with input and output paths
        char input_path[256] = "./testcase/";
        if (input_file_name)
                strcat(input_path, input_file_name);
        else
                strcpy(input_path, "/dev/stdin");

        char output_path[256] = "./tokens/";
        if (output_file_name)
                strcat(output_path, output_file_name);
        else
                strcpy(output_path, "/dev/stdout");

        // Open input file
        if (!(yyin = fopen(input_path, "r"))) {
                printf("[ERR] No input file\n");
                exit(1);
        }

        FILE *fout = fopen(output_path, "w+");
        int token;

        // Start to do real things
#ifndef MY_MAGIC_MACRO__
        printf("[START]: Read from: %s\n", input_file_name);
#endif
        while ((token = yylex())) {
                switch (token) {
                case ERROR:
                        fprintf(fout, "[ERR]: unable to analyze %s at %d line, "
                                "from %d to %d\n", yytext, lines, pos_start, pos_end);
                        break;
                case COMMENT:
                case BLANK:
                        break;
                case EOL:
                        break;
                default:
                        fprintf(fout, "%s\t%d\t%d\t%d\t%d\n", yytext, token, lines,
                                pos_start, pos_end);
                        break;
                }
        }
#ifndef MY_MAGIC_MACRO__
        printf("[END]: Analysis completed.\n");
#endif

        fclose(fout);
}

/// Return the number of '\n' in `str`. *after_nl is the number of characters
/// after the final '\n'.
static int count_new_line(const char *str, int *after_nl)
{
        int len = strlen(str);
        int ret = 0;
        *after_nl = 0;
        for (int i = 0; i < len; i++) {
                (*after_nl)++;
                if (str[i] == '\n') {
                        *after_nl = 0;
                        ret++;
                }
        }
        if (ret == 0)
                *after_nl = 0;
        return ret;
}

/// \brief get all file paths under 'testcase' directory
///
/// under 'testcase' directory, there could be many *.cminus files.
/// \todo student should fill this function
static int get_all_testcase(char filename[][256])
{
        int num = 0;
        DIR *cases_dir = opendir("testcase");
        if (cases_dir == NULL) {
                printf("Error opening testcase dir\n");
                exit(1);
        }

        struct dirent *stuff;
        while ((stuff = readdir(cases_dir)) != NULL) {
                if (!str_ends_with(stuff->d_name, ".cminus"))
                        continue;
                strcpy(filename[num++], stuff->d_name);
        }

        closedir(cases_dir);
        return num;
}

/// Check if `str` ends with `ending`.
static int str_ends_with(const char *str, const char *ending)
{
        if (str == NULL || ending == NULL)
                return 0;

        int str_len = strlen(str);
        int end_len = strlen(ending);
        if (str_len < end_len)
                return 0;

        return strcmp(str + (str_len - end_len), ending) == 0;
}

/// \brief process all *.cminus file
///
/// note that: use relative path for all i/o operations
int lex_main(int argc, char **argv){
        char filename[50][256];
        char output_file_name[256];
        char suffix[] = ".tokens";
        int files_count = get_all_testcase(filename);
        for(int i = 0; i < files_count; i++) {
                int name_len = strstr(filename[i], ".cminus") - filename[i];
                strncpy(output_file_name, filename[i], name_len);
                strcpy(output_file_name+name_len, suffix);
                analyzer(filename[i], output_file_name);
        }
        return 0;
}
/****************C代码 end*************/
