%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void yyerror(const char *s);
int yylex(void);
%}

%union {
    int num;     // For numbers
    char *str;   // For identifiers (variable names)
}

%token <num> NUMBER
%token <str> IDENTIFIER
%token ASSIGN PLUS MINUS MULT DIV LPAREN RPAREN SEMI EOL
%left PLUS MINUS
%left MULT DIV
%right ASSIGN
%type <num> expr

%%

program:
    program statement
    | statement
    ;

statement:
    IDENTIFIER ASSIGN expr SEMI EOL {
        printf("Assigning %d to %s\n", $3, $1);
        free($1); // Free allocated memory for identifier
    }
    | expr SEMI { printf("Result: %d\n", $1); }
    ;

expr:
    expr PLUS expr { $$ = $1 + $3; }
    | expr MINUS expr { $$ = $1 - $3; }
    | expr MULT expr { $$ = $1 * $3; }
    | expr DIV expr { $$ = $1 / $3; }
    | NUMBER { $$ = $1; }
    | LPAREN expr RPAREN { $$ = $2; }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}
