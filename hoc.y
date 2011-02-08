%{
#include "hoc.h"
#include <stdio.h>
#include <math.h> /* fmod() */
#define MAX_VAR_NAME_LENGTH 100
#define code2(c1, c2) code(c1); code(c2)
#define code3(c1, c2, c3) code(c1); code(c2); code(c3)

extern double Pow(double, double);
/* for being nuts about compiler warnings */
int yylex();   
int yyerror(char *s);

int warning(char *s, char *t);

%}

%union {
    Symbol *sym; /* symbol table pointer */
    Inst *inst; /* (stack) machine instruction */
}

%token <sym> NUMBER VAR BLTIN UNDEF
%right '='
%left '%'
%left '+' '-'
%left '*' '/'
%left UNARYOPERATOR
%right '^' /* exponentiation */

%%

list:   /* nothing */
        | list '\n'
        | list asgn '\n' { code2(pop, STOP); return 1; }
        | list expr '\n' { code2(print, STOP); return 1; }
        | list error '\n' { yyerrok; }
        /*  semicolon-terminated expressions
        | list ';'
        | list asgn ';'
        | list expr ';' { fprintf(stdout, "    %.8g\n", $2 ) ; }
        | list error ';' { yyerrok; }
        */
        ;
asgn:    VAR '=' expr {
                /*
                    if (is_reserved_variable($1->name)) {
                        execerror("reserved variable", $1->name);
                    } else {
                    */
                        code3(varpush, (Inst) $1, assign); 
                    /* } */
                }
        ;
expr:    NUMBER { code2(constpush, (Inst) $1); }
        | VAR {
        /* if ($1->type == UNDEF)
                    execerror("undefined variable", $1->name);
                 */
                 code3(varpush, (Inst) $1, eval);
              }
        | asgn
        /* cheap hack to get 0 and 2 argument fns
        | BLTIN '(' ')' { $$ = (*($1->u.ptr0))(); }
        | BLTIN '(' expr ',' expr ')' { $$ = (*($1->u.ptr2))($3, $5); }
        */
        | BLTIN '(' expr ')' { code2(bltin, (Inst) $1->u.ptr); }
        | expr '+' expr { code(add); }
        | expr '-' expr { code(sub); }
        | expr '*' expr { code(mul); }
        | expr '/' expr { code(div_); }
        | expr '^' expr { code(power); }
        | '(' expr ')'
        | '+' expr %prec UNARYOPERATOR /* do nothing */
        | '-' expr %prec UNARYOPERATOR { code(negate); }
        /*
        | expr '%' expr { $$ = fmod($1, $3); }
        */
        ;

%%
/* end of grammar */
#include <ctype.h> /* isdigit(), isalpha(), isalnum */
#include <signal.h> /* for error handling */
#include <setjmp.h>

jmp_buf begin;

char *progname = "hoc";
int lineno = 1;
FILE *yyin;
static void fpecatch(int);

int main(int argc, char **argv)
{

    FILE *fp;
    progname = argv[0];
    fp = stdin;
    if (argc >= 2)
        fp = fopen(argv[1], "r");
    yyin = fp;

    init();
    setjmp(begin);
    signal(SIGFPE, fpecatch);
    for (initcode(); yyparse(); initcode())
        execute(prog);

    fclose(fp);
    return 0;
}

/* recover from run-time error
 */
int execerror(char *s, char *t)
{
    warning(s, t);
    /* for debugging, we would use: */
    /* abort(); */
    longjmp(begin, 0);

    return 1;
}

/* catch floating point exception
 */
void fpecatch(int f)
{
    execerror("floating point exception", (char *) 0);
}

int yylex() /* int argc, char *argv[]) */
{
    int c;

    while ((c = fgetc(yyin)) == ' ' || c == '\t')
        ;
    if (c == EOF)
        return 0;
    if (c == '.' || isdigit(c)) {
        double d;
        ungetc(c, yyin);
        fscanf(yyin, "%lf", &d);
        yylval.sym = install("", NUMBER, d);
        return NUMBER;
    }
    if (isalpha(c)) {
        Symbol *s;
        char sbuf[MAX_VAR_NAME_LENGTH];
        char *p = sbuf;
        do {
            *p++ = c;
        } while ((c = fgetc(yyin)) != EOF && isalnum(c));
        ungetc(c, yyin);
        *p = '\0';
        if ((s=lookup(sbuf, MAX_VAR_NAME_LENGTH)) == 0)
            s = install(sbuf, UNDEF, 0.0);
        yylval.sym = s;
        return s->type == UNDEF ? VAR : s->type;
    }
    if (c == '\n' || c == ';')
        lineno++;
    return c;
}

int yyerror(char *s)
{
    return warning(s, (char *) 0);
}

int warning(char *s, char *t)
{
    fprintf(stderr, "%s: %s", progname, s);
    if (t)
        fprintf(stderr, " %s", t);
    fprintf(stderr, " near line %d\n", lineno);
    return 0;
}
