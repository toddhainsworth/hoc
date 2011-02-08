#include <stdio.h>
#include <math.h>
#include "hoc.h"
#include "y.tab.h"

#define NSTACK 256
static Datum stack[NSTACK]; /* the stack */
static Datum *stackp; /* next free spot on stack */

#define NPROG 2000
Inst prog[NPROG]; /* the machine */
Inst *progp; /* the next free spot on the stack */
Inst *pc; /* program counter during execution */

initcode()
{
    stackp = stack;
    progp = prog;
}

push(Datum d) /* push d onto stack */
{
    if (stackp >= &stack[NSTACK])
        execerror("stack overflow", (char *) 0);
    *stackp++ = d;
}

Datum pop() /* pop and return top elem from stack */
{
    if (stackp <= stack)
        execerror("stack udnerflow", (char *) 0);
    return *--stackp;
}

Inst *code(Inst f) /* install one instruction or operand */
{
    Inst *oprogp = prog;
    if (progp >= &prog[NPROG])
        execerror("program too big", (char *) 0);
    *progp++ = f;
    return oprogp;
}

execute(Inst *p)
{
    for (pc = p; *pc != STOP; )
        (*(*pc++))();
}

constpush() /* push constant onto stack */
{
    Datum d;
    d.val = ((Symbol *)*pc++)->u.val;
    push(d);
}

varpush() /* push variable onto stack */
{
    Datum d;
    d.sym = (Symbol *)(*pc++);
    push(d);
}

add() /* add top two elems on stack */
{
    Datum d1, d2;
    d2 = pop();
    d1 = pop();
    d1.val += d2.val;
    push(d1);
}

sub() /* subtract top two elems on stack */
{
    Datum d1, d2;
    d2 = pop();
    d1 = pop();
    d1.val -= d2.val;
    push(d1);
}

mul() /* multiply top two elems on stack */
{
    Datum d1, d2;
    d2 = pop();
    d1 = pop();
    d1.val *= d2.val;
    push(d1);
}

div_() /* multiply top two elems on stack */
{
    Datum d1, d2;
    d2 = pop();
    d1 = pop();
    d1.val /= d2.val;
    push(d1);
}

power() /* multiply top two elems on stack */
{
    double x;
    Datum d1, d2;
    d2 = pop();
    d1 = pop();
    x = pow(d1.val, d2.val);
    d1.val = x;
    push(d1);
}

negate() /* negate top elem on stack */
{
    Datum d1;
    d1 = pop();
    d1.val = -d1.val;
    push(d1);
}

noop()
{
}





eval() /* evaluate variable on stack */
{
    Datum d;
    d = pop();
    if (d.sym->type == UNDEF)
        execerror("undefined variable", d.sym->name);
    d.val = d.sym->u.val;
    push(d);
}

assign() /* assign top value to next value */
{
    Datum d1, d2;
    d1 = pop();
    d2 = pop();
    if (d1.sym->type != VAR && d1.sym->type != UNDEF)
        execerror("assignment to non-variable", d1.sym->name);
    d1.sym->u.val = d2.val;
    d1.sym->type = VAR;
    push(d2);
}

print() /* pop top value from stack, print it */
{
    Datum d;
    d = pop();
    printf("    %.8g\n", d.val);
}

bltin()
{
    Datum d;
    d = pop();
    d.val = (*(double (*)())(*pc++))(d.val);
    push(d);
}