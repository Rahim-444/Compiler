%{
#include "parser.tab.h"
#include <string.h>

%}

%option noyywrap

%%

[0-9]+   { yylval.num = atoi(yytext); return NUMBER; }
[a-zA-Z_][a-zA-Z0-9_]* { 
    yylval.str = strdup(yytext);  // Store identifier name
    return IDENTIFIER; 
}
"="      { return ASSIGN; }
"+"      { return PLUS; }
"-"      { return MINUS; }
"*"      { return MULT; }
"/"      { return DIV; }
"("      { return LPAREN; }
")"      { return RPAREN; }
";"      { return SEMI; }
[ \t]    { /* Ignore spaces/tabs */ }
\n       { return EOL; }
.       { printf("Unexpected character: %s\n", yytext); }

%%

