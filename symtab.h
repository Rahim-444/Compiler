#ifndef SYMTAB_H
#define SYMTAB_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define VARIABLE 1
#define CONSTANT 2
#define ARRAY 3

#define TYPE_INT 1
#define TYPE_FLOAT 2

/* Structure for a symbol table entry */
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

/* Node structure for the linked list */
typedef struct SymbolNode {
    SymbolEntry entry;
    struct SymbolNode* next;
} SymbolNode;

/* Symbol table structure using a linked list */
typedef struct {
    SymbolNode* head;
    int count;  // Optional, kept for convenience
} SymbolTable;

/* Function declarations */
void initSymbolTable(void);
SymbolEntry* lookupSymbol(char* name);
SymbolEntry* insertSymbol(char* name, int code, int type, int size, int line, int column);
void updateSymbolValue(SymbolEntry* entry, void* value);
void updateSymbolOptions(int type, int arraySize);
void displaySymbolTable(void);

char* getTypeString(int type);
char* getEntityCodeString(int code);
int isConstant(SymbolEntry* entry);
int isArray(SymbolEntry* entry);
int getSymbolType(SymbolEntry* entry);
int getArraySize(SymbolEntry* entry);
int compatible_types(int type1, int type2);

void semanticError(char* message, int line, int column);

void checkArrayAccess(char* name, int idx, int exprType, int isConstExpr, int exprValue, int line, int column);
void checkArrayAssignment(char* name, int idx, int exprType, int assignType, int line, int column);
int isValidLoopVariable(char* name, int line, int column);
int isValidIOVariable(char* name, int line, int column);
int isValidIOArrayElement(char* name, int exprType, int isConstExpr, int exprValue, int line, int column);
int checkAssignmentCompatibility(char* varName, int varType, int exprType, int line, int column);
void checkLoopStep(int isConstant, int value, int line, int column);
void checkConditionType(int exprType, const char* context, int line, int column);
void checkDivisionByZero(int isConstant, int type, void* value, int line, int column);

#endif
