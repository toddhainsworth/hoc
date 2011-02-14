#include <stdio.h>
#include <math.h>
#include "hoc.h"
#include "y.tab.h"

#define NSTACK 256
static Datum stack[NSTACK]; /* the stack */
static Datum *stackp; /* next free spot on stack */

#define NPROG 2000
Inst prog[NPROG]; /* the machine */
Inst *progp; /* the next free spot on the machine */
Inst *pc; /* program counter during execution */

void simple_print_machine();

void initcode()
{
    stackp = stack;
    progp = prog;
}

void push(Datum d) /* push d onto stack */
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

void execute(Inst *p)
{
    /* simple_print_machine(); */
    for (pc = p; *pc != STOP; )
        (*(*pc++))();
}

void constpush() /* push constant onto stack */
{
    /* terse version */
    /* Datum d; d.val = ((Symbol *)*pc++)->u.val; */

    Datum d;
    Symbol *s;
    double x;

    s = (Symbol *) *pc;
    pc += 1;

    x = s->u.val;
    d.val = x;
    push(d);
}

void varpush() /* push variable onto stack */
{
    Datum d;
    d.sym = (Symbol *)(*pc++);
    push(d);
}

void add() /* add top two elems on stack */
{
    Datum d1, d2;
    d2 = pop();
    d1 = pop();
    d1.val += d2.val;
    push(d1);
}

void sub() /* subtract top two elems on stack */
{
    Datum d1, d2;
    d2 = pop();
    d1 = pop();
    d1.val -= d2.val;
    push(d1);
}

void mul() /* multiply top two elems on stack */
{
    Datum d1, d2;
    d2 = pop();
    d1 = pop();
    d1.val *= d2.val;
    push(d1);
}

void mod() /* a mod b for top two elems on stack*/
{
    Datum d1, d2;
    d2 = pop();
    d1 = pop();
    d1.val = fmod(d1.val, d2.val);
    push(d1);
}


void div_() /* multiply top two elems on stack */
{
    Datum d1, d2;
    d2 = pop();
    d1 = pop();
    d1.val /= d2.val;
    push(d1);
}

void power() /* multiply top two elems on stack */
{
    double x;
    Datum d1, d2;
    d2 = pop();
    d1 = pop();
    x = pow(d1.val, d2.val);
    d1.val = x;
    push(d1);
}

void negate() /* negate top elem on stack */
{
    Datum d1;
    d1 = pop();
    d1.val = -d1.val;
    push(d1);
}

void noop()
{ }

void eval() /* evaluate variable on stack */
{
    Datum d;
    d = pop();
    if (d.sym->type == UNDEF)
        execerror("undefined variable", d.sym->name);
    d.val = d.sym->u.val;
    push(d);
}

void assign() /* assign top value to next value */
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

void print() /* pop top value from stack, print it */
{
    Datum d;
    d = pop();
    printf("    %.8g\n", d.val);
}

void bltin()
{
    Datum d;
    d = pop();
    d.val = (*(double (*)())(*pc++))(d.val);
    push(d);
}

void le()
{
    Datum d1, d2;
    d2 = pop();
    d1 = pop();
    d1.val = (double) (d1.val <= d2.val);
    push(d1);
}

void lt()
{
    Datum d1, d2;
    d2 = pop();
    d1 = pop();
    d1.val = (double) (d1.val < d2.val);
    push(d1);
}

void ge()
{
    Datum d1, d2;
    d2 = pop();
    d1 = pop();
    d1.val = (double) (d1.val >= d2.val);
    push(d1);
}

void gt()
{
    Datum d1, d2;
    d2 = pop();
    d1 = pop();
    d1.val = (double) (d1.val > d2.val);
    push(d1);
}

void eq()
{
    Datum d1, d2;
    d2 = pop();
    d1 = pop();
    d1.val = (double) (d1.val == d2.val);
    push(d1);
}

void ne()
{
    Datum d1, d2;
    d2 = pop();
    d1 = pop();
    d1.val = (double) (d1.val != d2.val);
    push(d1);
}

void and()
{
    Datum d1, d2;
    d2 = pop();
    d1 = pop();
    d1.val = (double) (d1.val && d2.val);
    push(d1);
}

void or()
{
    Datum d1, d2;
    d2 = pop();
    d1 = pop();
    d1.val = (double) (d1.val || d2.val);
    push(d1);
}

void not()
{
    Datum d;
    d = pop();
    d.val = (double) !d.val;
    push(d);
}

void whilecode()
{
    Datum d;
    Inst *savepc = pc; /* loop body */

    execute(savepc + 2);
    d = pop();
    while (d.val) {
        execute(*((Inst **) (savepc))); /* body */
        execute(savepc + 2);
        d = pop();
    }
    pc = *((Inst **) (savepc + 1)); /* next statement */
}

void ifcode()
{
    Datum d;
    Inst *savepc = pc; /* then part */

    execute(savepc + 3); /* condition */
    d = pop();
    if (d.val)
        execute(*((Inst **) (savepc)));
    else if (*((Inst **) (savepc + 1))) /* else part ? */
        execute(*((Inst **) (savepc + 1)));
    pc = *((Inst **) (savepc + 2)); /* next stmt */
}

void prexpr() /* print numeric value */
{
    Datum d;
    d = pop();
    printf("%.8g\n", d.val);
}

/* print the machine and the address of each instruction,
 * but don't do any fancy recognition.
 */
void simple_print_machine()
{
    Inst *loop_progp;
    size_t ct = 0;
    for (loop_progp = prog; loop_progp != progp; ++loop_progp) {
        ct++;
        fprintf(stderr, "%4u %8x %10x\n", ct, loop_progp, *loop_progp);
    }
}
