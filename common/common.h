#ifndef __COMMON_COMMON_H__
#define __COMMON_COMMON_H__

#ifndef MAX_TOKEN_LEN
#define MAX_TOKEN_LEN 20
#endif

#ifndef NAME_MAX_LENGTH
#define NAME_MAX_LENGTH 256
#endif

#ifndef FILE_MAX_NUMBER
#define FILE_MAX_NUMBER 64
#endif

/// \brief change suffix in source string and save to dest string.
///
/// \return 0 if no errors, or -1
int change_suffix(char *source, char *dest, char *before, char *after);

/// \brief get all files with suffix '.cminus' under 'testcase' directory
///
/// \return files number
int getAllTestcase(char filename[][NAME_MAX_LENGTH]);

#endif /* common/common.h */
