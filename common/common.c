#include "common.h"

#include <dirent.h>
#include <string.h>

/// \brief change suffix in source string and save to dest string.
///
/// \return 0 if no errors, or -1
int change_suffix(char *source, char *dest, char *before, char *after) {
    if (strlen(source) < strlen(before)) {
        return -1;
    } else {
        strncpy(dest, source, strlen(source) - strlen(before));
        strcat(dest, after);
        return 0;
    }
}

/// \brief get all files names with 'suffix' under 'dir' directory
///
/// \return files number
int getAllFilename(char *dir, char *suffix, char filename[][NAME_MAX_LENGTH]) {
    struct dirent *dp;
    DIR *dirp = opendir(dir);
    int files_count = 0;
    while ((dp = readdir(dirp)) != NULL) {
        if (strlen(dp->d_name) > strlen(suffix)) {
            char *dot = strrchr(dp->d_name, '.');
            if (dot && !strcmp(dot, suffix)) {
                strcpy(filename[files_count], dp->d_name);
                files_count++;
            }
        }
    }
    closedir(dirp);
    return files_count;
}

/// \brief get all files with suffix '.cminus' under 'testcase' directory
///
/// \return files number
int getAllTestcase(char filename[][NAME_MAX_LENGTH]) {
    return getAllFilename("./testcase/", ".cminus", filename);
}
