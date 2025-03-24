%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser.tab.h"


int line = 1;
int column = 1;

void count_position() {
    for(int i = 0; i < yyleng; i++) {
        if(yytext[i] == '\n') {
            line++;
            column = 1;
        } else {
            column++;
        }
    }
}
%}

%option noyywrap

DIGIT [0-9]
LETTER [a-zA-Z]
WHITESPACE [ \t]
IDENTIFIER {LETTER}({LETTER}|{DIGIT}|_)*
INTEGER {DIGIT}+
SIGNED_INT [\(][\+\-]{INTEGER}[\)]
FLOAT {INTEGER}\.{INTEGER}
SIGNED_FLOAT [\(][\+\-]{FLOAT}[\)]
STRING \"[^\"]*\"
SINGLE_COMMENT "<"[ \t]*"!-"[^-]*"-"[ \t]*"!>"
MULTI_COMMENT "{--"(.|\n)*"--}"

%%

{WHITESPACE}    { count_position(); }

"MainPrgm"      { count_position(); return MAIN_PRGM; }
"Var"           { count_position(); return VAR; }
"BeginPg"       { count_position(); return BEGIN_PG; }
"EndPg"         { count_position(); return END_PG; }
"let"           { count_position(); return LET; }
"@define"       { count_position(); return DEFINE; }
"Const"         { count_position(); return CONST; }
"if"            { count_position(); return IF; }
"then"          { count_position(); return THEN; }
"else"          { count_position(); return ELSE; }
"do"            { count_position(); return DO; }
"while"         { count_position(); return WHILE; }
"for"           { count_position(); return FOR; }
"from"          { count_position(); return FROM; }
"to"            { count_position(); return TO; }
"step"          { count_position(); return STEP; }
"input"         { count_position(); return INPUT; }
"output"        { count_position(); return OUTPUT; }
"Int"           { count_position(); return INT_TYPE; }
"Float"         { count_position(); return FLOAT_TYPE; }

":="            { count_position(); return ASSIGN; }
"+"             { count_position(); return PLUS; }
"-"             { count_position(); return MINUS; }
"*"             { count_position(); return MULTIPLY; }
"/"             { count_position(); return DIVIDE; }
"AND"           { count_position(); return AND; }
"OR"            { count_position(); return OR; }
"!"             { count_position(); return NOT; }
">"             { count_position(); return GT; }
"<"             { count_position(); return LT; }
">="            { count_position(); return GE; }
"<="            { count_position(); return LE; }
"=="            { count_position(); return EQ; }
"!="            { count_position(); return NE; }

";"             { count_position(); return SEMICOLON; }
":"             { count_position(); return COLON; }
","             { count_position(); return COMMA; }
"."             { count_position(); return DOT; }
"["             { count_position(); return LBRACKET; }
"]"             { count_position(); return RBRACKET; }
"{"             { count_position(); return LBRACE; }
"}"             { count_position(); return RBRACE; }
"("             { count_position(); return LPAREN; }
")"             { count_position(); return RPAREN; }
"="             { count_position(); return EQUAL; }

{INTEGER}       { count_position(); return INTEGER; }
{SIGNED_INT}    { count_position(); return INTEGER; }
{FLOAT}         { count_position(); return FLOAT_VAL; }
{SIGNED_FLOAT}  { count_position(); return FLOAT_VAL; }
{STRING}        { count_position(); return STRING; }

{IDENTIFIER}    {
                  count_position();
                  
                  if (strlen(yytext) > 14) {
                    printf("Lexical Error: Identifier '%s' exceeds maximum length at line %d\n", yytext, line);
                  } 
                  else if (yytext[strlen(yytext) - 1] == '_') {
                    printf("Lexical Error: Identifier '%s' cannot end with underscore at line %d\n", yytext, line);
                  }
                  else {
                    int i, has_consecutive = 0;
                    for (i = 0; i < strlen(yytext) - 1; i++) {
                      if (yytext[i] == '_' && yytext[i+1] == '_') {
                        has_consecutive = 1;
                        break;
                      }
                    }
                    
                    if (has_consecutive) {
                      printf("Lexical Error: Identifier '%s' has consecutive underscores at line %d\n", yytext, line);
                    } else {
                      return IDENTIFIER;
                    }
                  }
                }

{SINGLE_COMMENT} { count_position(); }
{MULTI_COMMENT}  { count_position(); }

.               { printf("Lexical Error: Unrecognized character '%s' at line %d\n", yytext, line); }

%%
