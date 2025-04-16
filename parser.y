%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "symtab.h"

extern int yylex();
extern FILE* yyin;
extern int line;
extern int column;
extern char* yytext;

void yyerror(const char* msg);


char errorMsg[256];


int currentType = 0;
int arraySize = 0;

//
typedef struct {
    int type;      
    int isConstant; 
    union {
        int int_val;
        float float_val;
    } value;
} ExprType;

ExprType exprResult;
%}

%union {
    int int_val;
    float float_val;
    char* str_val;
    int type;             
    struct {
        int type;           
        int isConstant;     
        union {
            int int_val;
            float float_val;
        } value;
    } expr;
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

%type <type> type
%type <expr> expression arithmetic_expression logical_expression comparison_expression
%type <expr> condition

/* Operator precedence - last has highest priority */
%left OR
%left AND
%left NOT
%left GT LT GE LE EQ NE
%left PLUS MINUS
%left MULTIPLY DIVIDE
%left LPAREN RPAREN

/* Start symbol */
%start program

%%

program: 
    MAIN_PRGM IDENTIFIER SEMICOLON 
    {
        
        initSymbolTable();
    }
    VAR declarations BEGIN_PG LBRACE instructions RBRACE END_PG SEMICOLON
    { 
        printf("Program successfully parsed\n");
        displaySymbolTable();
    }
    ;

declarations:
    /* empty */
    | declarations variable_declaration
    | declarations constant_declaration
    ;

variable_declaration:
    LET id_list COLON type SEMICOLON
    {
        currentType = $4;
        arraySize = 0;
        updateSymbolType(currentType);
    }
    | LET id_list COLON LBRACKET type SEMICOLON INTEGER RBRACKET SEMICOLON
    {
        currentType = $5;
        arraySize = $7;
        updateSymbolType(currentType);
        if (arraySize <= 0) {
            sprintf(errorMsg, "Array size must be positive, got %d", arraySize);
            semanticError(errorMsg, line, column);
        }
    }
    ;


constant_declaration:
    DEFINE CONST IDENTIFIER COLON type EQUAL expression SEMICOLON
    {
        int idx = lookupSymbol($3);
        if (idx >= 0) {
            sprintf(errorMsg, "Redeclaration of identifier '%s'", $3);
            semanticError(errorMsg, line, column);
        } else {

            if (!compatible_types($5, $7.type)) {
                sprintf(errorMsg, "Type mismatch in constant declaration: expected %s, got %s", 
                        getTypeString($5), getTypeString($7.type));
                semanticError(errorMsg, line, column);
            } else {
            
                idx = insertSymbol($3, CONSTANT, $5, 0, line, column);
                
                if ($7.isConstant) {
                    if ($5 == TYPE_INT) {
                        int intValue;
                        if ($7.type == TYPE_INT) {
                            intValue = $7.value.int_val;
                        } else {
                            
                            intValue = (int)$7.value.float_val;
                        }
                        updateSymbolValue(idx, &intValue);
                    } else {
                        float floatValue;
                        if ($7.type == TYPE_FLOAT) {
                            floatValue = $7.value.float_val;
                        } else {
                            
                            floatValue = (float)$7.value.int_val;
                        }
                        updateSymbolValue(idx, &floatValue);
                    }
                }
            }
        }
    }
    ;

id_list:
    IDENTIFIER
    {
        int idx = lookupSymbol($1);
        if (idx >= 0) {
            sprintf(errorMsg, "Redeclaration of identifier '%s'", $1);
            semanticError(errorMsg, line, column);
        } else {
            insertSymbol($1, (arraySize > 0) ? ARRAY : VARIABLE, 0, arraySize, line, column);
        }
    }
    | id_list COMMA IDENTIFIER
    {
        int idx = lookupSymbol($3);
        if (idx >= 0) {
            sprintf(errorMsg, "Redeclaration of identifier '%s'", $3);
            semanticError(errorMsg, line, column);
        } else {
            insertSymbol($3, (arraySize > 0) ? ARRAY : VARIABLE, 0, arraySize, line, column);
        }
    }
    ;

type:
    INT_TYPE { $$ = TYPE_INT; }
    | FLOAT_TYPE { $$ = TYPE_FLOAT; }
    ;

instructions:
    /* empty */
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
    {
        int idx = lookupSymbol($1);
        if (idx < 0) {
            sprintf(errorMsg, "Undeclared identifier '%s'", $1);
            semanticError(errorMsg, line, column);
        } else {
         
            if (isConstant(idx)) {
                sprintf(errorMsg, "Cannot modify constant '%s'", $1);
                semanticError(errorMsg, line, column);
            }
          
            else if (isArray(idx)) {
                sprintf(errorMsg, "Cannot assign to array '%s' without index", $1);
                semanticError(errorMsg, line, column);
            }
           
            else if (!compatible_types(getSymbolType(idx), $3.type)) {
                sprintf(errorMsg, "Type mismatch in assignment: variable '%s' is %s, expression is %s", 
                        $1, 
                        getTypeString(getSymbolType(idx)), 
                        getTypeString($3.type));
                semanticError(errorMsg, line, column);
            }
            
         
            if ($3.isConstant) {
                if (getSymbolType(idx) == TYPE_INT) {
                    int intValue;
                    if ($3.type == TYPE_INT) {
                        intValue = $3.value.int_val;
                    } else {
                        intValue = (int)$3.value.float_val;
                    }
                    updateSymbolValue(idx, &intValue);
                } else { 
                    float floatValue;
                    if ($3.type == TYPE_FLOAT) {
                        floatValue = $3.value.float_val;
                    } else {
                        floatValue = (float)$3.value.int_val;
                    }
                    updateSymbolValue(idx, &floatValue);
                }
            }
        }
    }
    | IDENTIFIER LBRACKET expression RBRACKET ASSIGN expression
    {
        int idx = lookupSymbol($1);
        if (idx < 0) {
            sprintf(errorMsg, "Undeclared identifier '%s'", $1);
            semanticError(errorMsg, line, column);
        } else {
            
            if (!isArray(idx)) {
                sprintf(errorMsg, "Cannot use array indexing on non-array variable '%s'", $1);
                semanticError(errorMsg, line, column);
            }
  
            else if ($3.type != TYPE_INT) {
                semanticError("Array index must be of integer type", line, column);
            }
            
            else if ($3.isConstant) {
                if ($3.value.int_val < 0 || $3.value.int_val >= getArraySize(idx)) {
                    sprintf(errorMsg, "Array index %d out of bounds [0-%d] for array '%s'", 
                            $3.value.int_val, getArraySize(idx)-1, $1);
                    semanticError(errorMsg, line, column);
                }
            }
            

            if (!compatible_types(getSymbolType(idx), $6.type)) {
                sprintf(errorMsg, "Type mismatch in array assignment: array '%s' is %s, expression is %s", 
                        $1, 
                        getTypeString(getSymbolType(idx)), 
                        getTypeString($6.type));
                semanticError(errorMsg, line, column);
            }
        }
    }
    ;

if_statement:
    IF LPAREN condition RPAREN THEN LBRACE instructions RBRACE ELSE LBRACE instructions RBRACE
    {
        
        if ($3.type != TYPE_INT) {
            semanticError("Condition in if statement must evaluate to a boolean", line, column);
        }
    }
    | IF LPAREN condition RPAREN THEN LBRACE instructions RBRACE
    {
        
        if ($3.type != TYPE_INT) {
            semanticError("Condition in if statement must evaluate to a boolean", line, column);
        }
    }
    ;

while_loop:
    DO LBRACE instructions RBRACE WHILE LPAREN condition RPAREN SEMICOLON
    {

        if ($7.type != TYPE_INT) {
            semanticError("Condition in while loop must evaluate to a boolean", line, column);
        }
    }
    ;

for_loop:
    FOR IDENTIFIER FROM expression TO expression STEP expression LBRACE instructions RBRACE
    {
     
        int idx = lookupSymbol($2);
        if (idx < 0) {
            sprintf(errorMsg, "Undeclared loop variable '%s'", $2);
            semanticError(errorMsg, line, column);
        } else if (isConstant(idx)) {
            sprintf(errorMsg, "Cannot use constant as loop variable '%s'", $2);
            semanticError(errorMsg, line, column);
        } else if (isArray(idx)) {
            sprintf(errorMsg, "Cannot use array as loop variable '%s'", $2);
            semanticError(errorMsg, line, column);
        }
        

        if ($4.type != TYPE_INT) {
            semanticError("'from' expression in for loop must be of type Int", line, column);
        }
        if ($6.type != TYPE_INT) {
            semanticError("'to' expression in for loop must be of type Int", line, column);
        }
        if ($8.type != TYPE_INT) {
            semanticError("'step' expression in for loop must be of type Int", line, column);
        }
        

        if ($8.isConstant && $8.value.int_val == 0) {
            semanticError("Step value in for loop cannot be zero", line, column);
        }
    }
    ;

io_statement:
    INPUT LPAREN IDENTIFIER RPAREN
    {
        int idx = lookupSymbol($3);
        if (idx < 0) {
            sprintf(errorMsg, "Undeclared identifier '%s'", $3);
            semanticError(errorMsg, line, column);
        } else if (isConstant(idx)) {
            sprintf(errorMsg, "Cannot input to constant '%s'", $3);
            semanticError(errorMsg, line, column);
        } else if (isArray(idx)) {
            sprintf(errorMsg, "Cannot input to array '%s' without specifying an index", $3);
            semanticError(errorMsg, line, column);
        }
    }
    | INPUT LPAREN IDENTIFIER LBRACKET expression RBRACKET RPAREN
    {
        int idx = lookupSymbol($3);
        if (idx < 0) {
            sprintf(errorMsg, "Undeclared identifier '%s'", $3);
            semanticError(errorMsg, line, column);
        } else if (!isArray(idx)) {
            sprintf(errorMsg, "Cannot use array indexing on non-array variable '%s'", $3);
            semanticError(errorMsg, line, column);
        } else if ($5.type != TYPE_INT) {
            semanticError("Array index must be of integer type", line, column);
        } else if ($5.isConstant) {
            if ($5.value.int_val < 0 || $5.value.int_val >= getArraySize(idx)) {
                sprintf(errorMsg, "Array index %d out of bounds [0-%d] for array '%s'", 
                        $5.value.int_val, getArraySize(idx)-1, $3);
                semanticError(errorMsg, line, column);
            }
        }
    }
    | OUTPUT LPAREN output_list RPAREN
    ;

output_list:
    expression
    | STRING
    | output_list COMMA expression
    | output_list COMMA STRING
    ;

expression:
    arithmetic_expression { $$ = $1; }
    | logical_expression { $$ = $1; }
    ;

arithmetic_expression:
    INTEGER 
    { 
        $$.type = TYPE_INT;
        $$.isConstant = 1;
        $$.value.int_val = $1;
    }
    | FLOAT_VAL 
    { 
        $$.type = TYPE_FLOAT;
        $$.isConstant = 1;
        $$.value.float_val = $1;
    }
    | IDENTIFIER 
    { 
        int idx = lookupSymbol($1);
        if (idx < 0) {
            sprintf(errorMsg, "Undeclared identifier '%s'", $1);
            semanticError(errorMsg, line, column);
            $$.type = TYPE_INT;
            $$.isConstant = 0;
        } else if (isArray(idx)) {
            sprintf(errorMsg, "Cannot use array '%s' without index", $1);
            semanticError(errorMsg, line, column);
            $$.type = getSymbolType(idx);
            $$.isConstant = 0;
        } else {
            $$.type = getSymbolType(idx);
            $$.isConstant = isConstant(idx);
        }
    }
    | IDENTIFIER LBRACKET expression RBRACKET 
    { 
        int idx = lookupSymbol($1);
        if (idx < 0) {
            sprintf(errorMsg, "Undeclared identifier '%s'", $1);
            semanticError(errorMsg, line, column);
            $$.type = TYPE_INT;
            $$.isConstant = 0;
        } else if (!isArray(idx)) {
            sprintf(errorMsg, "Cannot use array indexing on non-array variable '%s'", $1);
            semanticError(errorMsg, line, column);
            $$.type = getSymbolType(idx);
            $$.isConstant = 0;
        } else if ($3.type != TYPE_INT) {
            semanticError("Array index must be of integer type", line, column);
            $$.type = getSymbolType(idx);
            $$.isConstant = 0;
        } else if ($3.isConstant) {
            if ($3.value.int_val < 0 || $3.value.int_val >= getArraySize(idx)) {
                sprintf(errorMsg, "Array index %d out of bounds [0-%d] for array '%s'", 
                        $3.value.int_val, getArraySize(idx)-1, $1);
                semanticError(errorMsg, line, column);
            }
            $$.type = getSymbolType(idx);
            $$.isConstant = 0;
        } else {
            $$.type = getSymbolType(idx);
            $$.isConstant = 0;
        }
    }
    | arithmetic_expression PLUS arithmetic_expression 
    { 
        $$.type = ($1.type == TYPE_FLOAT || $3.type == TYPE_FLOAT) ? TYPE_FLOAT : TYPE_INT;
        $$.isConstant = ($1.isConstant && $3.isConstant);
        
        if ($$.isConstant) {
            if ($$.type == TYPE_INT) {
                $$.value.int_val = $1.value.int_val + $3.value.int_val;
            } else { 
                float val1 = ($1.type == TYPE_FLOAT) ? $1.value.float_val : (float)$1.value.int_val;
                float val2 = ($3.type == TYPE_FLOAT) ? $3.value.float_val : (float)$3.value.int_val;
                $$.value.float_val = val1 + val2;
            }
        }
    }
    | arithmetic_expression MINUS arithmetic_expression 
    { 
        $$.type = ($1.type == TYPE_FLOAT || $3.type == TYPE_FLOAT) ? TYPE_FLOAT : TYPE_INT;
        $$.isConstant = ($1.isConstant && $3.isConstant);
        
        if ($$.isConstant) {
            if ($$.type == TYPE_INT) {
                $$.value.int_val = $1.value.int_val - $3.value.int_val;
            } else {
                float val1 = ($1.type == TYPE_FLOAT) ? $1.value.float_val : (float)$1.value.int_val;
                float val2 = ($3.type == TYPE_FLOAT) ? $3.value.float_val : (float)$3.value.int_val;
                $$.value.float_val = val1 - val2;
            }
        }
    }
    | arithmetic_expression MULTIPLY arithmetic_expression 
    { 
        $$.type = ($1.type == TYPE_FLOAT || $3.type == TYPE_FLOAT) ? TYPE_FLOAT : TYPE_INT;
        $$.isConstant = ($1.isConstant && $3.isConstant);
        
        if ($$.isConstant) {
            if ($$.type == TYPE_INT) {
                $$.value.int_val = $1.value.int_val * $3.value.int_val;
            } else { 
                float val1 = ($1.type == TYPE_FLOAT) ? $1.value.float_val : (float)$1.value.int_val;
                float val2 = ($3.type == TYPE_FLOAT) ? $3.value.float_val : (float)$3.value.int_val;
                $$.value.float_val = val1 * val2;
            }
        }
    }
    | arithmetic_expression DIVIDE arithmetic_expression 
    { 
        $$.type = ($1.type == TYPE_FLOAT || $3.type == TYPE_FLOAT) ? TYPE_FLOAT : TYPE_INT;
        $$.isConstant = ($1.isConstant && $3.isConstant);
        
       
        if ($3.isConstant) {
            int isZero = 0;
            if ($3.type == TYPE_INT) {
                isZero = ($3.value.int_val == 0);
            } else {
                isZero = ($3.value.float_val == 0.0);
            }
            
            if (isZero) {
                semanticError("Division by zero", line, column);
            } else if ($$.isConstant) {
                if ($$.type == TYPE_INT) {
                    $$.value.int_val = $1.value.int_val / $3.value.int_val;
                } else { 
                    float val1 = ($1.type == TYPE_FLOAT) ? $1.value.float_val : (float)$1.value.int_val;
                    float val2 = ($3.type == TYPE_FLOAT) ? $3.value.float_val : (float)$3.value.int_val;
                    $$.value.float_val = val1 / val2;
                }
            }
        }
    }
    | LPAREN arithmetic_expression RPAREN
    { 
        $$ = $2;
    }
    ;

logical_expression:
    comparison_expression 
    { 
        $$ = $1;
    }
    | logical_expression AND logical_expression 
    { 
        $$.type = TYPE_INT;
        $$.isConstant = ($1.isConstant && $3.isConstant);
        
        if ($$.isConstant) {
            int val1, val2;
            
            if ($1.type == TYPE_INT) {
                val1 = $1.value.int_val != 0;
            } else {
                val1 = $1.value.float_val != 0.0;
            }
            
            if ($3.type == TYPE_INT) {
                val2 = $3.value.int_val != 0;
            } else {
                val2 = $3.value.float_val != 0.0;
            }
            
            $$.value.int_val = val1 && val2;
        }
    }
    | logical_expression OR logical_expression 
    { 
        $$.type = TYPE_INT;
        $$.isConstant = ($1.isConstant && $3.isConstant);
        
        if ($$.isConstant) {
            int val1, val2;
            
            if ($1.type == TYPE_INT) {
                val1 = $1.value.int_val != 0;
            } else {
                val1 = $1.value.float_val != 0.0;
            }
            
            if ($3.type == TYPE_INT) {
                val2 = $3.value.int_val != 0;
            } else {
                val2 = $3.value.float_val != 0.0;
            }
            
            $$.value.int_val = val1 || val2;
        }
    }
    | NOT logical_expression 
    { 
        $$.type = TYPE_INT;
        $$.isConstant = $2.isConstant;
        
        if ($$.isConstant) {
            int val;
            
            if ($2.type == TYPE_INT) {
                val = $2.value.int_val != 0;
            } else {
                val = $2.value.float_val != 0.0;
            }
            
            $$.value.int_val = !val;
        }
    }
    | LPAREN logical_expression RPAREN 
    { 
        $$ = $2;
    }
    ;

comparison_expression:
    arithmetic_expression GT arithmetic_expression 
    { 
        $$.type = TYPE_INT;
        $$.isConstant = ($1.isConstant && $3.isConstant);
        
        if ($$.isConstant) {
            if ($1.type == TYPE_INT && $3.type == TYPE_INT) {
                $$.value.int_val = ($1.value.int_val > $3.value.int_val);
            } else {
                float val1 = ($1.type == TYPE_FLOAT) ? $1.value.float_val : (float)$1.value.int_val;
                float val2 = ($3.type == TYPE_FLOAT) ? $3.value.float_val : (float)$3.value.int_val;
                $$.value.int_val = (val1 > val2);
            }
        }
    }
    | arithmetic_expression LT arithmetic_expression 
    { 
        $$.type = TYPE_INT;
        $$.isConstant = ($1.isConstant && $3.isConstant);
        
        if ($$.isConstant) {
            if ($1.type == TYPE_INT && $3.type == TYPE_INT) {
                $$.value.int_val = ($1.value.int_val < $3.value.int_val);
            } else {
                float val1 = ($1.type == TYPE_FLOAT) ? $1.value.float_val : (float)$1.value.int_val;
                float val2 = ($3.type == TYPE_FLOAT) ? $3.value.float_val : (float)$3.value.int_val;
                $$.value.int_val = (val1 < val2);
            }
        }
    }
    | arithmetic_expression GE arithmetic_expression 
    { 
        $$.type = TYPE_INT;
        $$.isConstant = ($1.isConstant && $3.isConstant);
        
        if ($$.isConstant) {
            if ($1.type == TYPE_INT && $3.type == TYPE_INT) {
                $$.value.int_val = ($1.value.int_val >= $3.value.int_val);
            } else {
                float val1 = ($1.type == TYPE_FLOAT) ? $1.value.float_val : (float)$1.value.int_val;
                float val2 = ($3.type == TYPE_FLOAT) ? $3.value.float_val : (float)$3.value.int_val;
                $$.value.int_val = (val1 >= val2);
            }
        }
    }
    | arithmetic_expression LE arithmetic_expression 
    { 
        $$.type = TYPE_INT;
        $$.isConstant = ($1.isConstant && $3.isConstant);
        
        if ($$.isConstant) {
            if ($1.type == TYPE_INT && $3.type == TYPE_INT) {
                $$.value.int_val = ($1.value.int_val <= $3.value.int_val);
            } else {
                float val1 = ($1.type == TYPE_FLOAT) ? $1.value.float_val : (float)$1.value.int_val;
                float val2 = ($3.type == TYPE_FLOAT) ? $3.value.float_val : (float)$3.value.int_val;
                $$.value.int_val = (val1 <= val2);
            }
        }
    }
    | arithmetic_expression EQ arithmetic_expression 
    { 
        $$.type = TYPE_INT;
        $$.isConstant = ($1.isConstant && $3.isConstant);
        
        if ($$.isConstant) {
            if ($1.type == TYPE_INT && $3.type == TYPE_INT) {
                $$.value.int_val = ($1.value.int_val == $3.value.int_val);
            } else {
                float val1 = ($1.type == TYPE_FLOAT) ? $1.value.float_val : (float)$1.value.int_val;
                float val2 = ($3.type == TYPE_FLOAT) ? $3.value.float_val : (float)$3.value.int_val;
                $$.value.int_val = (val1 == val2);
            }
        }
    }
    | arithmetic_expression NE arithmetic_expression 
    { 
        $$.type = TYPE_INT;
        $$.isConstant = ($1.isConstant && $3.isConstant);
        
        if ($$.isConstant) {
            if ($1.type == TYPE_INT && $3.type == TYPE_INT) {
                $$.value.int_val = ($1.value.int_val != $3.value.int_val);
            } else {
                float val1 = ($1.type == TYPE_FLOAT) ? $1.value.float_val : (float)$1.value.int_val;
                float val2 = ($3.type == TYPE_FLOAT) ? $3.value.float_val : (float)$3.value.int_val;
                $$.value.int_val = (val1 != val2);
            }
        }
    }
    ;

condition:
    logical_expression
    {
        $$ = $1;
    }
    ;

%%

void yyerror(const char* msg) {
    printf("Syntax Error: %s at line %d, column %d near '%s'\n", msg, line, column, yytext);
}
