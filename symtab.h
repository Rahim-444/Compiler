#ifndef SYMTAB_H
#define SYMTAB_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>


#define MAX_SYMBOLS 100


#define VARIABLE 1
#define CONSTANT 2
#define ARRAY 3


#define TYPE_INT 1
#define TYPE_FLOAT 2


typedef struct {
    char name[15];      
    int code;           
    int type;            
    int size;           
    int line;            
    int column;         
    union {
        int int_val;
        float float_val;
    } value;             
    int isInitialized;  
} SymbolEntry;


typedef struct {
    SymbolEntry entries[MAX_SYMBOLS];
    int count;
} SymbolTable;


void initSymbolTable();
int lookupSymbol(char* name);
int insertSymbol(char* name, int code, int type, int size, int line, int column);
void updateSymbolValue(int index, void* value);
void displaySymbolTable();


char* getTypeString(int type);
char* getEntityCodeString(int code);
int isConstant(int index);
int isArray(int index);
int getSymbolType(int index);
int getArraySize(int index);
int compatible_types(int type1, int type2);


void semanticError(char* message, int line, int column);


void checkArrayAccess(char* name, int idx, int exprType, int isConstExpr, int exprValue, int line, int column);
void checkArrayAssignment(char* name, int idx, int exprType, int assignType, int line, int column);

#endif 