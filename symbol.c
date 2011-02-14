#include <string.h> /* strncmp(), strncpy() */
#include <stdlib.h> /* malloc() */
#include "hoc.h"

static Symbol *symlist = 0; /* symbol table; linked list */

/* for printing out symbol table (debug) */
#include <stdio.h>
#include "y.tab.h"
void print_symbol_table()
{
    Symbol *sp;
    for (sp = symlist; sp != (Symbol *) 0; sp = sp->next) {
        fprintf(stderr, "%10s", sp->name);
        if (sp->type == VAR)
            fprintf(stderr, " % 12.8f", sp->u.val);
        fputc('\n', stderr);
    }
}

Symbol *lookup(char *s, size_t n)
{
    Symbol *sp;
    for (sp = symlist; sp != (Symbol *) 0; sp = sp->next)
        if (strncmp(sp->name, s, n) == 0)
            return sp;
    return 0; /* not found */
}

/* check return from malloc */
char *emalloc(size_t n)
{
    char *p;

    p = (char *) malloc(n);
    if (p == 0)
        execerror("out of memory", (char *) 0);
    return p;
}

/* install s in symbol table */
Symbol *install(char *s, short t, double d)
{
    Symbol *sp;

    sp = (Symbol *) emalloc(sizeof(Symbol));
    sp->name_len = strlen(s) + 1; /* +1 for '\0' */
    sp->name = emalloc(sp->name_len);
    strncpy(sp->name, s, sp->name_len);
    sp->type = t;
    sp->u.val = d;
    sp->next = symlist; /* put at front of list */
    symlist = sp;
    return sp;
}
