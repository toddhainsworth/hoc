#ifndef _HOC_H
#define _HOC_H
#include <stdlib.h>
typedef struct Symbol { /* symbol table entry */
    char *name;
    short type; /* VAR, BLTIN, UNDEF */
    union {
        double val;     /* if VAR */
        double (*ptr0)(); /* if BLTIN */
        double (*ptr)(double); /* if BLTIN */
        double (*ptr2)(double, double); /* if BLTIN */
    } u;
    struct Symbol *next;
} Symbol;
Symbol *install(char *s, int t, double d);
Symbol *lookup(char *s, size_t n);
int execerror(char *s, char *t);
void init();
int is_reserved_variable(char *s);
#endif /* _HOC_H */
