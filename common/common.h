#ifndef __COMMON_COMMON_H__
#define __COMMON_COMMON_H__

#ifndef MAX_TOKEN_LEN
#define MAX_TOKEN_LEN 20
#endif

#include <dirent.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int getAllTestcase(char filename[][256]);

#endif /* common/common.h */
