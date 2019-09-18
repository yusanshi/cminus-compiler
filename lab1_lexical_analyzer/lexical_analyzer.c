%option noyywrap
%{
/*****************声明和选项设置  begin*****************/
#include <string.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <dirent.h>
int files_count = 0;
int lines;
int pos_start;
int pos_end;

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
    PBRACKET = 275,
    LBRACE = 276,
    PBRACE = 277,
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



. {return ERROR;}


 /****  end******/
%%

/****************请按需求补全C代码 start*************/

/// \brief analysize a *.cminus file
///
///	\param input_file_name
/// \param output_file_name
/// \todo student should fill this function

void analyzer(char *input_file_name, char *output_file_name)
{
    char input_path[256] = "./testcase/";
    strcat(input_path, input_file_name);
    char output_path[256] = "./tokens/";
    strcat(output_path, output_file_name);
    if (!(yyin = fopen(input_path, "r")))
    {
        printf("[ERR] No input file\n");
        exit(1);
    }
    printf("[START]: Read from: %s\n", input_file_name);
    FILE *fp = fopen(output_path, "w+");
    int token;
    while (token = yylex())
    {
        switch (token)
        {
        case ERROR:
            fprintf(fp, "[ERR]: unable to analysize %s at %d line, from %d to %d\n", yytext, lines, pos_start, pos_end);
            break;
        case ADD:
            break;
        case SUB:
            break;
        case MUL:
            break;
        case DIV:
            break;
        case LT:
            break;
        case LTE:
            break;
        case GT:
            break;
        case GTE:
            break;
        case EQ:
            break;
        case NEQ:
            break;
        case ASSIN:
            break;
        case SEMICOLON:
            break;
        case COMMA:
            break;
        case LPARENTHESE:
            break;
        case RPARENTHESE:
            break;
        case LBRACKET:
            break;
        case PBRACKET:
            break;
        case LBRACE:
            break;
        case PBRACE:
            break;
        case ELSE:
            break;
        case IF:
            break;
        case INT:
            break;
        case RETURN:
            break;
        case VOID:
            break;
        case WHILE:
            break;
        case IDENTIFIER:
            break;
        case NUMBER:
            break;
        case LETTER:
            break;
        case ARRAY:
            break;
        case EOL:
            break;
        case COMMENT:
            break;
        case BLANK:
            break;
        default:
            fprintf(fp, "%s\t%d\t%d\t%d\t%d\n", yytext, token, lines, pos_start, pos_end);
        }
    }
    fclose(fp);
    printf("[END]: Analysis completed.\n");
}

/// \brief get all file paths under 'testcase' directory
///
/// under 'testcase' directory, there could be many *.cminus files.
/// \todo student should fill this function
void getAllFilename(char *dir, char filename[][256], int *files_count)
{
    struct dirent *dp;
    DIR *dirp = opendir(dir);
    while ((dp = readdir(dirp)) != NULL)
    {
        if (strlen(dp->d_name) > strlen(".cminus"))
        {
            char *dot = strrchr(dp->d_name, '.');
            if (dot && !strcmp(dot, ".cminus"))
            {
                strcpy(filename[files_count], dp->d_name);
                *files_count++;
            }
        }
    }
    closedir(dirp);
}

int change_suffix(char *source, char *dest, char *before, char *after)
{
    if (strlen(source) < strlen(before))
    {
        return -1;
    }
    else
    {
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
int main(int argc, char **argv)
{
    char filename[64][256];
    char output_file_name[256];
    char suffix[] = ".tokens";
    getAllFilename("./testcase/", filename, &files_count);
    for (int i = 0; i < (files_count < 64 ? files_count : 64); i++)
    {
        memset(output_file_name, 0, 256);
        change_suffix(filename[i], output_file_name, "cminus", "tokens");
        analyzer(filename[i], output_file_name);
    }
    return 0;
}
/**************** end*************/
