%{
#include "hoc.h"
#include <stdio.h>
#include <math.h> /* fmod() */
extern double Pow();
/* for being nuts about compiler warnings */
int yylex();   
int yyerror(char *s);

int warning(char *s, char *t);
%}

%union {
    double val;
    Symbol *sym;
}

%token <val> NUMBER
%token <sym> VAR BLTIN UNDEF
%type <val> expr asgn

%right '='
%left '%'
%left '+' '-'
%left '*' '/'
%left UNARYOPERATOR
%right '^' /* exponentiation */

%%

list:   /* nothing */
        | list '\n'
        | list ';'
        | list asgn '\n'
        | list asgn ';'
        | list expr '\n' { fprintf(stdout, "    %.8g\n", $2 ) ; }
        | list expr ';' { fprintf(stdout, "    %.8g\n", $2 ) ; }
        | list error '\n' { yyerrok; }
        | list error ';' { yyerrok; }
        ;
asgn:    VAR '=' expr { $$ = $1->u.val = $3; $1->type = VAR; }
        ;
expr:    NUMBER
        | VAR { if ($1->type == UNDEF)
                    execerror("undefined variable", $1->name);
                $$ = $1->u.val; }
        | asgn
        | BLTIN '(' expr ')' { $$ = (*($1->u.ptr))($3); }
        | expr '+' expr { $$ = $1 + $3; }
        | expr '-' expr { $$ = $1 - $3; }
        | expr '*' expr { $$ = $1 * $3; }
        | expr '/' expr { 
                    if ( $3 == 0.0 )
                        execerror("division by zero", "");
                    $$ = $1 / $3;
                    }
        | expr '^' expr { $$ = Pow($1, $3); }
        | '(' expr ')'  { $$ = $2; }
        | '+' expr %prec UNARYOPERATOR { $$ = $2; }
        | '-' expr %prec UNARYOPERATOR { $$ = -$2; }
        | expr '%' expr { $$ = fmod($1, $3); }
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
static void fpecatch();

int main(int argc, char **argv)
{

    FILE *fp = stdin;
    if (argc >= 2)
        fp = fopen(argv[1], "r");
    yyin = fp;

    setjmp(begin);
    signal(SIGFPE, fpecatch);
    init();
    yyparse();
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
void fpecatch()
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
        ungetc(c, yyin);
        fscanf(yyin, "%lf", &yylval.val);
        return NUMBER;
    }
    if (isalpha(c)) {
        Symbol *s;
        char sbuf[100];
        char *p = sbuf;
        do {
            *p++ = c;
        } while ((c = getchar()) != EOF && isalnum(c));
        ungetc(c, stdin);
        *p = '\0';
        if ((s=lookup(sbuf)) == 0)
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
