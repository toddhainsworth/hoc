%{
#define YYSTYPE double
#include <stdio.h>
/* for being nuts about compiler warnings */
int yylex();   
int yyerror(char *s);

int warning(char *s, char *t);
%}

%token NUMBER
%left '%'
%left '+' '-'
%left '*' '/'
%left UNARYOPERATOR

%%

list:   /* nothing */
        | list '\n'
        | list expr '\n' { fprintf(stdout, "    %.8g\n", $2 ) ; }
        ;
expr:    NUMBER { $$ = $1; }
        | '+' expr %prec UNARYOPERATOR { $$ = $2; }
        | '-' expr %prec UNARYOPERATOR { $$ = -$2; }
        | expr '%' expr { $$ = (int) $1 % (int) $3; }
        | expr '+' expr { $$ = $1 + $3; }
        | expr '-' expr { $$ = $1 - $3; }
        | expr '*' expr { $$ = $1 * $3; }
        | expr '/' expr { $$ = $1 / $3; }
        | '(' expr ')'  { $$ = $2; }
        ;

%%

#include <stdio.h>
#include <ctype.h>
char *progname;
int lineno = 1;
FILE *yyin;

int main(int argc, char **argv)
{
    FILE *fp = stdin;
    if (argc >= 2)
        fp = fopen(argv[1], "r");
    yyin = fp;
    yyparse();
    fclose(fp);

    return 0;
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
        fscanf(yyin, "%lf", &yylval);
        return NUMBER;
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
