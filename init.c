#include "hoc.h"
#include "y.tab.h"
#include <math.h>
#include <stdlib.h> /* drand48() */
#include <string.h> /* strncmp() */

extern double Log(double), Log10(double), Exp(double);
extern double Sqrt(double), integer(double);

static struct {
    char *name;
    double cval;
} consts[] = {
    {"PI",    3.14159265358979323846},
    {"E",     2.71828182845904523536},
    {"GAMMA", 0.57721566490153286060}, /* euler const */
    {"DEG",  57.29577951308232087680}, /* deg/radian */
    {"PHI",   1.61803398874989484820}, /* golden ratio */
    {0,  0}
};

static struct {
    char *name;
    double (*func)(double);
} builtins[] = {
    {"sin",   sin},
    {"cos",   cos},
    {"atan",  atan},
    {"log",   Log},
    {"log10", Log10},
    {"exp",   Exp},
    {"sqrt",  Sqrt},
    {"int",   integer},
    {"abs",   fabs},
    /* terrible abuse of C's generosity */
    {"atan2", atan2},
    {"rand", drand48},
    {0, 0}
};

void init()
{
    int i;
    Symbol *s;

    for (i = 0; consts[i].name; i++)
        install(consts[i].name, VAR, consts[i].cval);
    for (i = 0; builtins[i].name; i++) {
        s = install(builtins[i].name, BLTIN, 0.0);
        s->u.ptr = builtins[i].func;
    }
}

/* check if a variable that a user is trying to
 * create is one of the built-in mathematical
 * constants
 */
int is_reserved_variable(char *s)
{
    int i;
    for (i = 0; consts[i].name; i++)
        if (!strncmp(s, consts[i].name, sizeof(consts[i].name)/sizeof(char)))
            return 1;
    return 0;
}
