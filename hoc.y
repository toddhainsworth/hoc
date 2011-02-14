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
int follow(char expect, int ifyes, int ifno);
static void fpecatch(int f);
static void interrupt_catch(int f);

%}

/* y.tab.h content comes from here */

%union {
    Symbol *sym; /* symbol table pointer */
    Inst *inst; /* (stack) machine instruction */
}

%token <sym> NUMBER PRINT VAR BLTIN UNDEF WHILE IF ELSE
%type <inst> stmt asgn expr stmtlist cond while if end
%right '='
%left OR
%left AND
%left GT GE LT LE EQ NE
%left '%'
%left '+' '-'
%left '*' '/'
%left UNARYOPERATOR NOT
%right '^' /* exponentiation */

%%

list:     /* nothing */
        | list '\n'
        | list asgn '\n' { code2(pop, STOP); return 1; }
        | list stmt '\n' { code(STOP); return 1; }
        | list expr '\n' { code2(print, STOP); return 1; }
        | list error '\n' { yyerrok; }
        /*  semicolon-terminated expressions
        | list ';'
        | list asgn ';'
        | list expr ';' { fprintf(stdout, "    %.8g\n", $2 ) ; }
        | list error ';' { yyerrok; }
        */
        ;

asgn:    VAR '=' expr { $$ = $3;
                    Symbol *s = (Symbol *) $1;
                    if (is_reserved_variable(s->name)) {
                        execerror("reserved variable", s->name);
                    } else {
                        /*
                        code(varpush);
                        code((Inst) $1);
                        code(assign);
                        */
                        code3(varpush, (Inst) $1, assign);
                    }
                }
        ;

stmt:     expr { code(pop); }
        | PRINT expr { code(prexpr); $$ = $2; }
        | while cond stmt end {
                ($1)[1] = (Inst) $3; /* body of loop */
                ($1)[2] = (Inst) $4; /* end, if cond fails */
            }
        | if cond stmt end { /* else-less if */
                ($1)[1] = (Inst) $3; /* then part */
                ($1)[3] = (Inst) $4; /* end, if cond fails */
            }
        | if cond stmt end ELSE stmt end { /* if with else */
                ($1)[1] = (Inst) $3; /* then part */
                ($1)[2] = (Inst) $6; /* else part */
                ($1)[3] = (Inst) $7; /* end, if cond fails */
            }
        | '{' stmtlist '}' { $$ = $2; }
        ;

cond:    '(' expr ')' { code(STOP); $$ = $2; }
        ;

while:    WHILE { $$ = code3(whilecode, STOP, STOP); }
        ;

if:       IF { $$ = code(ifcode); code3(STOP, STOP, STOP); }
        ;

end:      /* nothing */ { code(STOP); $$ = progp; }
        ;

stmtlist: /* nothing */ { $$ = progp; }
        | stmtlist '\n'
        | stmtlist stmt
        ;

expr:     NUMBER { $$ = code2(constpush, (Inst) $1); }
        | VAR { $$ = code3(varpush, (Inst) $1, eval); }
        | asgn
        /* cheap hack to get 0 and 2 argument fns
        | BLTIN '(' ')' { $$ = (*($1->u.ptr0))(); }
        | BLTIN '(' expr ',' expr ')' { $$ = (*($1->u.ptr2))($3, $5); }
        */
        | BLTIN '(' expr ')' { $$ = $3; code2(bltin, (Inst) $1->u.ptr); }
        | '(' expr ')' { $$ = $2; }
        | expr '%' expr { code(mod); }
        | expr '+' expr { code(add); }
        | expr '-' expr { code(sub); }
        | expr '*' expr { code(mul); }
        | expr '/' expr { code(div_); }
        | expr '^' expr { code(power); }
        | '+' expr %prec UNARYOPERATOR { $$ = $2; }
        | '-' expr %prec UNARYOPERATOR { $$ = $2;  code(negate); }
        | expr GT expr { code(gt); }
        | expr GE expr { code(ge); }
        | expr LT expr { code(lt); }
        | expr LE expr { code(le); }
        | expr EQ expr { code(eq); }
        | expr NE expr { code(ne); }
        | expr AND expr { code(and); }
        | expr OR expr { code(or); }
        | NOT expr { $$ = $2; code(not); }
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

int main(int argc, char **argv)
{

    FILE *fp;
    progname = argv[0];
    fp = stdin;
    if (argc >= 2)
        if (!(fp = fopen(argv[1], "r")) ) {
            fprintf(stderr, "file not found: %s\n", argv[1]);
            exit(1);
        }
    yyin = fp;

    init();
    setjmp(begin);
    signal(SIGFPE, fpecatch);
    signal(SIGINT, interrupt_catch);
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
static void fpecatch(int f)
{
    execerror("floating point exception", (char *) 0);
}

static void interrupt_catch(int f)
{
    /*
     * fputc('\n', stderr);
     * print_symbol_table();
     */
    execerror("BREAK!", (char *) 0);
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

    switch (c) {
        case '>': return follow('=', GE, GT);
        case '<': return follow('=', LE, LT);
        case '=': return follow('=', EQ, '=');
        case '!': return follow('=', NE, NOT);
        case '|': return follow('|', OR, '|');
        case '&': return follow('&', AND, '&');
        case '\n': lineno++; return '\n';
        default:  return c;
    }
}

int follow(char expect, int ifyes, int ifno) /* look ahead for >=, etc. */
{
    int c = fgetc(yyin);
    if (c == expect)
        return ifyes;
    ungetc(c, yyin);
    return ifno;
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
