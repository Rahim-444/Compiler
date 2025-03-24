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

// Symbol table structure
#define VARIABLE 1
#define CONSTANT 2
#define ARRAY 3
#define TYPE_INT 1
#define TYPE_FLOAT 2

typedef struct {
    char name[15];       // Name (max 14 chars + null)
    int code;            // VARIABLE, CONSTANT, or ARRAY
    int type;            // TYPE_INT or TYPE_FLOAT
    int size;            // For arrays (0 for simple variables)
    int line;            // Declaration line
    int column;          // Declaration column
    union {
        int int_val;
        float float_val;
    } value;             // Value for constants
    int initialized;     // Whether the value has been initialized
} SymbolEntry;

#define MAX_SYMBOLS 100
SymbolEntry symbolTable[MAX_SYMBOLS];
int symbolCount = 0;

// Symbol table functions
int lookupSymbol(char* name) {
    for (int i = 0; i < symbolCount; i++) {
        if (strcmp(symbolTable[i].name, name) == 0) {
            return i;
        }
    }
    return -1;
}

int insertSymbol(char* name, int code, int type, int size, int line, int col) {
    if (symbolCount >= MAX_SYMBOLS) return -1;
    
    strcpy(symbolTable[symbolCount].name, name);
    symbolTable[symbolCount].code = code;
    symbolTable[symbolCount].type = type;
    symbolTable[symbolCount].size = size;
    symbolTable[symbolCount].line = line;
    symbolTable[symbolCount].column = col;
    symbolTable[symbolCount].initialized = 0;
    
    return symbolCount++;
}

void displaySymbolTable() {
    printf("\n===== Symbol Table =====\n");
    printf("%-15s %-10s %-8s %-10s %-15s %-8s %-8s\n", 
           "Name", "Entity", "Type", "Size", "Value", "Line", "Column");
    printf("------------------------------------------------------------------------\n");
    
    for (int i = 0; i < symbolCount; i++) {
        char* entity_type;
        switch(symbolTable[i].code) {
            case VARIABLE: entity_type = "Variable"; break;
            case CONSTANT: entity_type = "Constant"; break;
            case ARRAY: entity_type = "Array"; break;
            default: entity_type = "Unknown";
        }
        
        char* data_type;
        switch(symbolTable[i].type) {
            case TYPE_INT: data_type = "Int"; break;
            case TYPE_FLOAT: data_type = "Float"; break;
            default: data_type = "Unknown";
        }
        
        printf("%-15s %-10s %-8s ", 
               symbolTable[i].name, entity_type, data_type);
        
        // Print size for arrays, - otherwise
        if (symbolTable[i].code == ARRAY) {
            printf("%-10d ", symbolTable[i].size);
        } else {
            printf("%-10s ", "-");
        }
        
        // Print value if initialized
        if (symbolTable[i].initialized) {
            if (symbolTable[i].type == TYPE_INT) {
                printf("%-15d ", symbolTable[i].value.int_val);
            } else {
                printf("%-15.2f ", symbolTable[i].value.float_val);
            }
        } else {
            printf("%-15s ", "Uninitialized");
        }
        
        printf("%-8d %-8d\n", symbolTable[i].line, symbolTable[i].column);
    }
    printf("===== End of Symbol Table =====\n\n");
}

// Track current variable declaration type and array size
int currentType = 0;
int arraySize = 0;

// Type checking helpers
int isCompatible(int type1, int type2) {
    return (type1 == type2) || 
           (type1 == TYPE_FLOAT && type2 == TYPE_INT);  // Int can be assigned to Float
}

// Error reporting
void semanticError(const char* msg, int line, int col) {
    printf("Semantic Error: %s at line %d, column %d\n", msg, line, col);
}

// Expression type tracking
typedef struct {
    int type;       // TYPE_INT or TYPE_FLOAT
    int isConstant; // Is it a constant expression
    union {
        int int_val;
        float float_val;
    } value;
} ExprType;

ExprType exprResult;

char errorMsg[256]; // Buffer for error messages
%}

%union {
    int int_val;
    float float_val;
    char* str_val;
    int type;               // For type information
    struct {
        int type;           // Expression type
        int isConstant;     // Is it a constant expression
        union {
            int int_val;
            float float_val;
        } value;
    } expr;
}

/* declarations des tokens */
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

/* la priorite des operateurs le dernier est le plus prioritaire */
%left OR
%left AND
%left NOT
%left GT LT GE LE EQ NE
%left PLUS MINUS
%left MULTIPLY DIVIDE
%left LPAREN RPAREN

/* start */
%start program

%%

program: 
    MAIN_PRGM IDENTIFIER SEMICOLON 
    {
        // Initialize the symbol table
        symbolCount = 0;
    }
    VAR declarations BEGIN_PG LBRACE instructions RBRACE END_PG SEMICOLON
    { 
        printf("Program successfully parsed\n");
        displaySymbolTable();
    }
    ;

declarations:
    /* vide */
    | declarations variable_declaration
    | declarations constant_declaration
    ;

variable_declaration:
    LET id_list COLON type SEMICOLON
    {
        currentType = $4;
        arraySize = 0;
    }
    | LET id_list COLON LBRACKET type SEMICOLON INTEGER RBRACKET SEMICOLON
    {
        currentType = $5;
        arraySize = $7;
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
            if (!isCompatible($5, $7.type)) {
                sprintf(errorMsg, "Type mismatch in constant declaration: expected %s, got %s", 
                        ($5 == TYPE_INT) ? "Int" : "Float", 
                        ($7.type == TYPE_INT) ? "Int" : "Float");
                semanticError(errorMsg, line, column);
            }
            
            idx = insertSymbol($3, CONSTANT, $5, 0, line, column);
            
            if ($7.isConstant) {
                symbolTable[idx].initialized = 1;
                if ($5 == TYPE_INT) {
                    if ($7.type == TYPE_INT) {
                        symbolTable[idx].value.int_val = $7.value.int_val;
                    } else {
                        symbolTable[idx].value.int_val = (int)$7.value.float_val;
                    }
                } else { // TYPE_FLOAT
                    if ($7.type == TYPE_FLOAT) {
                        symbolTable[idx].value.float_val = $7.value.float_val;
                    } else {
                        symbolTable[idx].value.float_val = (float)$7.value.int_val;
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
            insertSymbol($1, (arraySize > 0) ? ARRAY : VARIABLE, currentType, arraySize, line, column);
        }
    }
    | id_list COMMA IDENTIFIER
    {
        int idx = lookupSymbol($3);
        if (idx >= 0) {
            sprintf(errorMsg, "Redeclaration of identifier '%s'", $3);
            semanticError(errorMsg, line, column);
        } else {
            insertSymbol($3, (arraySize > 0) ? ARRAY : VARIABLE, currentType, arraySize, line, column);
        }
    }
    ;

type:
    INT_TYPE { $$ = TYPE_INT; }
    | FLOAT_TYPE { $$ = TYPE_FLOAT; }
    ;

instructions:
    /* vide */
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
            // Check if it's a constant
            if (symbolTable[idx].code == CONSTANT) {
                sprintf(errorMsg, "Cannot modify constant '%s'", $1);
                semanticError(errorMsg, line, column);
            }
            // Check if it's an array
            else if (symbolTable[idx].code == ARRAY) {
                sprintf(errorMsg, "Cannot assign to array '%s' without index", $1);
                semanticError(errorMsg, line, column);
            }
            // Check type compatibility
            else if (!isCompatible(symbolTable[idx].type, $3.type)) {
                sprintf(errorMsg, "Type mismatch in assignment: variable '%s' is %s, expression is %s", 
                        $1, 
                        (symbolTable[idx].type == TYPE_INT) ? "Int" : "Float", 
                        ($3.type == TYPE_INT) ? "Int" : "Float");
                semanticError(errorMsg, line, column);
            }
            
            // Update value if constant expression
            if ($3.isConstant) {
                symbolTable[idx].initialized = 1;
                if (symbolTable[idx].type == TYPE_INT) {
                    if ($3.type == TYPE_INT) {
                        symbolTable[idx].value.int_val = $3.value.int_val;
                    } else {
                        symbolTable[idx].value.int_val = (int)$3.value.float_val;
                    }
                } else { // TYPE_FLOAT
                    if ($3.type == TYPE_FLOAT) {
                        symbolTable[idx].value.float_val = $3.value.float_val;
                    } else {
                        symbolTable[idx].value.float_val = (float)$3.value.int_val;
                    }
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
            // Check if it's an array
            if (symbolTable[idx].code != ARRAY) {
                sprintf(errorMsg, "Cannot use index with non-array variable '%s'", $1);
                semanticError(errorMsg, line, column);
            }
            // Check index type
            else if ($3.type != TYPE_INT) {
                semanticError("Array index must be of type Int", line, column);
            }
            // Check index bounds if constant
            else if ($3.isConstant) {
                if ($3.value.int_val < 0 || $3.value.int_val >= symbolTable[idx].size) {
                    sprintf(errorMsg, "Array index out of bounds: %d (array size: %d)", 
                            $3.value.int_val, symbolTable[idx].size);
                    semanticError(errorMsg, line, column);
                }
            }
            
            // Check type compatibility
            if (!isCompatible(symbolTable[idx].type, $6.type)) {
                sprintf(errorMsg, "Type mismatch in array assignment: array '%s' is %s, expression is %s", 
                        $1, 
                        (symbolTable[idx].type == TYPE_INT) ? "Int" : "Float", 
                        ($6.type == TYPE_INT) ? "Int" : "Float");
                semanticError(errorMsg, line, column);
            }
        }
    }
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
    {
        // Check loop variable
        int idx = lookupSymbol($2);
        if (idx < 0) {
            sprintf(errorMsg, "Undeclared loop variable '%s'", $2);
            semanticError(errorMsg, line, column);
        } else if (symbolTable[idx].code == CONSTANT) {
            sprintf(errorMsg, "Cannot use constant as loop variable '%s'", $2);
            semanticError(errorMsg, line, column);
        } else if (symbolTable[idx].code == ARRAY) {
            sprintf(errorMsg, "Cannot use array as loop variable '%s'", $2);
            semanticError(errorMsg, line, column);
        }
        
        // Check expression types
        if ($4.type != TYPE_INT) {
            semanticError("'from' expression in for loop must be of type Int", line, column);
        }
        if ($6.type != TYPE_INT) {
            semanticError("'to' expression in for loop must be of type Int", line, column);
        }
        if ($8.type != TYPE_INT) {
            semanticError("'step' expression in for loop must be of type Int", line, column);
        }
        
        // Check for zero step
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
        } else if (symbolTable[idx].code == CONSTANT) {
            sprintf(errorMsg, "Cannot input to constant '%s'", $3);
            semanticError(errorMsg, line, column);
        } else if (symbolTable[idx].code == ARRAY) {
            sprintf(errorMsg, "Cannot input to array '%s' without index", $3);
            semanticError(errorMsg, line, column);
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
            $$.type = TYPE_INT; // Default to prevent cascading errors
            $$.isConstant = 0;
        } else if (symbolTable[idx].code == ARRAY) {
            sprintf(errorMsg, "Cannot use array '%s' without index", $1);
            semanticError(errorMsg, line, column);
            $$.type = symbolTable[idx].type;
            $$.isConstant = 0;
        } else {
            $$.type = symbolTable[idx].type;
            $$.isConstant = (symbolTable[idx].code == CONSTANT && symbolTable[idx].initialized);
            if ($$.isConstant) {
                if ($$.type == TYPE_INT) {
                    $$.value.int_val = symbolTable[idx].value.int_val;
                } else {
                    $$.value.float_val = symbolTable[idx].value.float_val;
                }
            }
        }
    }
    | IDENTIFIER LBRACKET expression RBRACKET 
    { 
        int idx = lookupSymbol($1);
        if (idx < 0) {
            sprintf(errorMsg, "Undeclared identifier '%s'", $1);
            semanticError(errorMsg, line, column);
            $$.type = TYPE_INT; // Default
            $$.isConstant = 0;
        } else if (symbolTable[idx].code != ARRAY) {
            sprintf(errorMsg, "Cannot use index with non-array variable '%s'", $1);
            semanticError(errorMsg, line, column);
            $$.type = symbolTable[idx].type;
            $$.isConstant = 0;
        } else if ($3.type != TYPE_INT) {
            semanticError("Array index must be of type Int", line, column);
            $$.type = symbolTable[idx].type;
            $$.isConstant = 0;
        } else if ($3.isConstant) {
            if ($3.value.int_val < 0 || $3.value.int_val >= symbolTable[idx].size) {
                sprintf(errorMsg, "Array index out of bounds: %d (array size: %d)", 
                        $3.value.int_val, symbolTable[idx].size);
                semanticError(errorMsg, line, column);
            }
            $$.type = symbolTable[idx].type;
            $$.isConstant = 0; // Array elements are not tracked as constants
        } else {
            $$.type = symbolTable[idx].type;
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
            } else { // TYPE_FLOAT
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
            } else { // TYPE_FLOAT
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
            } else { // TYPE_FLOAT
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
        
        // Check division by zero
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
                } else { // TYPE_FLOAT
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
