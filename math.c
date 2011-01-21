#include <math.h>
#include <errno.h>
#include "hoc.h"

double errcheck(double d, char *s);

double Exp(double x)
{
    return errcheck(exp(x), "exp");
}

double Log(double x)
{
    return errcheck(log(x), "exp");
}

double Log10(double x)
{
    return errcheck(log10(x), "log10");
}
double Sqrt(double x)
{
    return errcheck(sqrt(x), "sqrt");
}

double Pow(double x, double y)
{
    return errcheck(pow(x,y), "pow");
}

double integer(double x)
{
    return (double) (long) x;
}

double errcheck(double d, char *s)
{
    if (errno == EDOM) {
        errno = 0;
        execerror(s, "argument out of domain");
    } else if (errno == ERANGE) {
        errno = 0;
        execerror(s, "result out of range");
    }
    return d;
}
