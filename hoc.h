#ifndef _HOC_H
#define _HOC_H
#include <stdlib.h>
typedef struct Symbol { /* symbol table entry */
    char *name;
    size_t name_len; /* length of variable name, INCLUDING '\0' */
    short type; /* VAR, BLTIN, UNDEF */
    union {
        double val;     /* if VAR */
        double (*ptr)(double); /* if BLTIN */
        /*
        double (*ptr0)();
        double (*ptr2)(double, double);
        */
    } u;
    struct Symbol *next;
} Symbol;
Symbol *install(char *s, int t, double d);
Symbol *lookup(char *s, size_t n);
typedef union Datum { /* interpreter stack type */
    double val;
    Symbol *sym;
} Datum;
extern Datum pop();
typedef int (*Inst)(); /* machine instruction */
#define STOP (Inst) 0
extern Inst prog[];
extern eval(), print();
extern add(), sub(), mul();
extern div_(); /* stdlib.h defines div */
extern negate(), power(), assign(), bltin();
extern varpush(), constpush();

int execerror(char *s, char *t);
void init();
int is_reserved_variable(char *s);
#endif /* _HOC_H */
