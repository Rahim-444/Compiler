%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylex();
extern FILE* yyin;
extern int line;
extern int column;
extern char* yytext;

void yyerror(const char* msg);

char* copyString(char* str) {
    char* new_str = strdup(str);
    if (!new_str) {
        fprintf(stderr, "Memory allocation error\n");
        exit(1);
    }
    return new_str;
}
%}

%union {
    int int_val;
    float float_val;
    char* str_val;
}

/* Token declarations */
%token MAIN_PRGM VAR BEGIN_PG END_PG 
%token LET DEFINE CONST
%token IF THEN ELSE DO WHILE FOR FROM TO STEP
%token INPUT OUTPUT
%token INT_TYPE FLOAT_TYPE
%token ASSIGN PLUS MINUS MULTIPLY DIVIDE
%token AND OR NOT
%token GT LT GE LE EQ NE
%token SEMICOLON COLON COMMA DOT
%token LBRACKET RBRACKET LBRACE RBRACE LPAREN RPAREN EQUAL

%token <str_val> IDENTIFIER STRING
%token <int_val> INTEGER
%token <float_val> FLOAT_VAL

/* Precedence and associativity rules */
%left OR
%left AND
%left NOT
%left GT LT GE LE EQ NE
%left PLUS MINUS
%left MULTIPLY DIVIDE
%left LPAREN RPAREN

/* Starting symbol */
%start program

%%

program: 
    MAIN_PRGM IDENTIFIER SEMICOLON VAR declarations BEGIN_PG LBRACE instructions RBRACE END_PG SEMICOLON
    { printf("Program successfully parsed\n"); }
    ;

declarations:
    /* Empty */
    | declarations variable_declaration
    | declarations constant_declaration
    ;

variable_declaration:
    LET id_list COLON type SEMICOLON
    | LET id_list COLON LBRACKET type SEMICOLON INTEGER RBRACKET SEMICOLON
    ;

constant_declaration:
    DEFINE CONST IDENTIFIER COLON type EQUAL expression SEMICOLON
    ;

id_list:
    IDENTIFIER
    | id_list COMMA IDENTIFIER
    ;

type:
    INT_TYPE
    | FLOAT_TYPE
    ;

instructions:
    /* Empty */
    | instructions instruction
    ;

instruction:
    assignment SEMICOLON
    | if_statement
    | while_loop
    | for_loop
    | io_statement SEMICOLON
    ;

assignment:
    IDENTIFIER ASSIGN expression
    | IDENTIFIER LBRACKET expression RBRACKET ASSIGN expression
    ;

if_statement:
    IF LPAREN condition RPAREN THEN LBRACE instructions RBRACE ELSE LBRACE instructions RBRACE
    | IF LPAREN condition RPAREN THEN LBRACE instructions RBRACE
    ;

while_loop:
    DO LBRACE instructions RBRACE WHILE LPAREN condition RPAREN SEMICOLON
    ;

for_loop:
    FOR IDENTIFIER FROM expression TO expression STEP expression LBRACE instructions RBRACE
    ;

io_statement:
    INPUT LPAREN IDENTIFIER RPAREN
    | OUTPUT LPAREN output_list RPAREN
    ;

output_list:
    expression
    | STRING
    | output_list COMMA expression
    | output_list COMMA STRING
    ;

expression:
    arithmetic_expression
    | logical_expression
    ;

arithmetic_expression:
    INTEGER 
    | FLOAT_VAL 
    | IDENTIFIER 
    | IDENTIFIER LBRACKET expression RBRACKET 
    | arithmetic_expression PLUS arithmetic_expression 
    | arithmetic_expression MINUS arithmetic_expression 
    | arithmetic_expression MULTIPLY arithmetic_expression 
    | arithmetic_expression DIVIDE arithmetic_expression 
    | LPAREN arithmetic_expression RPAREN
    ;

logical_expression:
    condition
    | logical_expression AND logical_expression
    | logical_expression OR logical_expression
    | NOT logical_expression
    | LPAREN logical_expression RPAREN
    ;

condition:
    arithmetic_expression GT arithmetic_expression
    | arithmetic_expression LT arithmetic_expression
    | arithmetic_expression GE arithmetic_expression
    | arithmetic_expression LE arithmetic_expression
    | arithmetic_expression EQ arithmetic_expression
    | arithmetic_expression NE arithmetic_expression
    ;

%%

void yyerror(const char* msg) {
    printf("Syntax Error: %s at line %d, column %d near '%s'\n", msg, line, column, yytext);
}
