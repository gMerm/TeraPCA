#ifndef IO_H
#define IO_H

/* types of user command-line input */
typedef enum {
  INT,
  DOUBLE,
  STR,
  NA
} ARG_TYPE;

#endif

//mermigkis
//cpp is confused with c
#ifdef __cplusplus
extern "C" {
#endif

int findarg(const char *argname, ARG_TYPE type, void *val, int argc, char **argv);

// This part is copied from http://www-users.cs.umn.edu/~saad/software/EVSL/

//mermigkis
//cpp is confused with c
#ifdef __cplusplus
}
#endif
