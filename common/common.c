#include "common.h"

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

int getAllTestcase(char filename[][256])
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
