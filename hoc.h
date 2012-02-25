#ifndef _HOC_H
#define _HOC_H
#include <stdlib.h> /* size_t */
typedef struct Symbol { /* symbol table entry */
    char *name;
    size_t name_len; /* length of variable name, INCLUDING '\0' */
    short type; /* VAR, BLTIN, UNDEF */
    union {
        double val;     /* if VAR */
        double (*ptr)(double); /* if BLTIN */
        double (*defn)(); /* FUNCTION, PROCEDURE */
        char *str; /* STRING */
        /*
        double (*ptr0)();
        double (*ptr2)(double, double);
        */
    } u;
    struct Symbol *next;
} Symbol;
void print_symbol_table();
Symbol *install(char *s, short t, double d);
Symbol *lookup(char *s, size_t n);
typedef union Datum { /* interpreter stack type */
    double val;
    Symbol *sym;
} Datum;
extern Datum pop();
typedef size_t (*Inst)(); /* machine instruction */
#define STOP (Inst) 0
extern Inst prog[], *progp, *code();
extern void eval(), print(), prexpr();
extern void mod(), add(), sub(), mul();
extern void div_(); /* stdlib.h defines div */
extern void negate(), power(), assign(), bltin();
extern void varpush(), constpush();
extern void gt(), lt(), eq(), ge(), le(), ne(), and(), or(), not();
extern void ifcode(), whilecode();
extern void argassign(), procret(), funcret(), arg(), varread(), prstr(), call();
extern void defn(Symbol *s);

Inst *code();

int execerror(char *s, char *t);
void init();
void initcode();
void execute(Inst *p);
int is_reserved_variable(char *s);
#endif /* _HOC_H */
