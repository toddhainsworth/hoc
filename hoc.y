%{
#include <stdio.h>
#include <math.h>
/* for being nuts about compiler warnings */
int yylex();   
int yyerror(char *s);

int warning(char *s, char *t);
int execerror(char *s, char *t);
double mem[26];
%}

%union {
    double val;
    int index;
}

%token <val> NUMBER
%token <index> VAR
%type <val> expr

%right '='
%left '%'
%left '+' '-'
%left '*' '/'
%left UNARYOPERATOR

%%

list:   /* nothing */
        | list '\n'
        | list expr '\n' { fprintf(stdout, "    %.8g\n", $2 ) ; }
        | list error '\n' { yyerrok; }
        ;
expr:    NUMBER
        | VAR { $$ = mem[$1]; }
        | VAR '=' expr { $$ = mem[$1] = $3; }
        | '+' expr %prec UNARYOPERATOR { $$ = $2; }
        | '-' expr %prec UNARYOPERATOR { $$ = -$2; }
        | expr '%' expr { $$ = fmod($1, $3); }
        | expr '+' expr { $$ = $1 + $3; }
        | expr '-' expr { $$ = $1 - $3; }
        | expr '*' expr { $$ = $1 * $3; }
        | expr '/' expr { 
                    if ( $3 == 0.0 )
                        execerror("division by zero", "");
                    $$ = $1 / $3;
                    }
        | '(' expr ')'  { $$ = $2; }
        ;

%%

#include <stdio.h>
#include <ctype.h>
#include <signal.h> /* for error handling */
#include <setjmp.h>

jmp_buf begin;

char *progname = "hoc";
int lineno = 1;
FILE *yyin;

int main(int argc, char **argv)
{
    void fpecatch(int);

    FILE *fp = stdin;
    if (argc >= 2)
        fp = fopen(argv[1], "r");
    yyin = fp;

    setjmp(begin);
    signal(SIGFPE, fpecatch);
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
        ungetc(c, yyin);
        fscanf(yyin, "%lf", &yylval.val);
        return NUMBER;
    }
    if (islower(c)) {
        yylval.index = c - 'a'; /* ASCII number */
        return VAR;
    }
    if (c == '\n')
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
