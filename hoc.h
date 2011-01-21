#ifndef _HOC_H
#define _HOC_H
typedef struct Symbol { /* symbol table entry */
    char *name;
    short type; /* VAR, BLTIN, UNDEF */
    union {
        double val;     /* if VAR */
        double (*ptr)();/* if BLTIN */
    } u;
    struct Symbol *next;
} Symbol;
Symbol *install(char *s, int t, double d);
Symbol *lookup(char *s);
int execerror(char *s, char *t);
void init();
#endif /* _HOC_H */
