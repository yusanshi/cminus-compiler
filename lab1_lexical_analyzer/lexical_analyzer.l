%option noyywrap
%{
/*****************声明和选项设置  begin*****************/
#include <string.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <dirent.h>

int lines;
int pos_start;
int pos_end;

int count_new_line(const char *str, int *after_nl);
static int str_ends_with(const char *str, const char *ending);
static void path_change_suffix(char *path, const char *suffix);

#define BUMP_POS(n)                       \
        do {                              \
                pos_start = pos_end;      \
                pos_end = pos_start + n;  \
        } while(0)

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
        BLANK = 290,
};
/*****************end*****************/

%}

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
        return COMMENT;
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

[a-zA-Z]+ { BUMP_POS(strlen(yytext)); return IDENTIFIER; }
[0-9]+ { BUMP_POS(strlen(yytext)); return NUMBER; }

"\n" { pos_end = pos_start = 1; lines++; return EOL; }
[ \t] { BUMP_POS(1); return BLANK; }
. { return ERROR; }


 /****  end******/
%%

/****************请按需求补全C代码 start*************/

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

int count_new_line(const char *str, int *after_nl)
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

static void path_change_suffix(char *path, const char *suffix)
{
        char *dot = strrchr(path, '.');
        if (dot == NULL || suffix == NULL)
                return;

        strcpy(dot + 1, suffix);
}

// This macro is for testing on my machine. Hope TAs do not define it
// when compiling!
#ifndef MY_MAGIC_MACRO__
/// \brief process all *.cminus file
///
/// note that: use relative path for all i/o operations
///        process all *.cminus files under 'testcase' directory,
/// then create *.tokens files under 'tokens' directory
/// \todo student should fill this function
int main(int argc, char **argv)
{
        char fins[10][256];
        char fout[256];
        const char *suffix = "tokens";
        int file_count = get_all_testcase(fins);
        for (int i = 0; i < file_count; i++) {
                strcpy(fout, fins[i]);
                path_change_suffix(fout, suffix);

                analyzer(fins[i], fout);
        }
        return 0;
}
/**************** end*************/
#endif
