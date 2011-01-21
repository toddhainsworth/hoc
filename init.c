#include "hoc.h"
#include "y.tab.h"
#include <math.h>

extern double Log(double), Log10(double), Exp(double);
extern double Sqrt(double), integer(double);

static struct {
    char *name;
    double cval;
} consts[] = {
    {"PI",   3.1415926535},
    {"E",    2.71828182845904523536},
    {"GAMMA",0.577},
    {"DEG",  57.295},
    {"PHI",  1.618},
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
