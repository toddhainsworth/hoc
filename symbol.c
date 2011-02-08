#include <string.h> /* strncmp(), strncpy() */
#include <stdlib.h> /* malloc() */
#include "hoc.h"

static Symbol *symlist = 0; /* symbol table; linked list */

Symbol *lookup(char *s, size_t n)
{
    Symbol *sp;
    for (sp = symlist; sp != (Symbol *) 0; sp = sp->next)
        if (strncmp(sp->name, s, n) == 0)
            return sp;
    return 0; /* not found */
}

/* check return from malloc */
char *emalloc(unsigned int n)
{
    char *p;

    p = (char *) malloc(n);
    if (p == 0)
        execerror("out of memory", (char *) 0);
    return p;
}

/* install s in symbol table */
Symbol *install(char *s, int t, double d)
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
