#include "symtab.h"


SymbolTable symtab;

void initSymbolTable() {
    symtab.count = 0;
}

int lookupSymbol(char* name) {
    for (int i = 0; i < symtab.count; i++) {
        if (strcmp(symtab.entries[i].name, name) == 0) {
            return i;
        }
    }
    return -1;
}

int insertSymbol(char* name, int code, int type, int size, int line, int column) {
    if (symtab.count >= MAX_SYMBOLS) {
        printf("Symbol table overflow\n");
        return -1;
    }
    
    int index = symtab.count++;
    SymbolEntry* entry = &symtab.entries[index];
    
    strncpy(entry->name, name, 14);
    entry->name[14] = '\0'; 
    entry->code = code;
    entry->type = type;
    entry->size = size;
    entry->line = line;
    entry->column = column;
    entry->isInitialized = 0;
    
    return index;
}


void updateSymbolValue(int index, void* value) {
    if (index < 0 || index >= symtab.count) return;
    
    SymbolEntry* entry = &symtab.entries[index];
    entry->isInitialized = 1;
    
    if (entry->type == TYPE_INT) {
        entry->value.int_val = *((int*)value);
    } else if (entry->type == TYPE_FLOAT) {
        entry->value.float_val = *((float*)value);
    }
}


void displaySymbolTable() {
    printf("\n===== Symbol Table =====\n");
    printf("%-15s %-10s %-8s %-10s %-15s %-8s %-8s\n", 
           "Name", "Entity", "Type", "Size", "Value", "Line", "Column");
    printf("-----------------------------------------------------------------------\n");
    
    for (int i = 0; i < symtab.count; i++) {
        SymbolEntry* entry = &symtab.entries[i];
        
        printf("%-15s %-10s %-8s ", 
               entry->name, 
               getEntityCodeString(entry->code),
               getTypeString(entry->type));
        
       
        if (entry->code == ARRAY) {
            printf("%-10d ", entry->size);
        } else {
            printf("%-10s ", "-");
        }
        
     
        if (entry->isInitialized) {
            if (entry->type == TYPE_INT) {
                printf("%-15d ", entry->value.int_val);
            } else {
                printf("%-15.2f ", entry->value.float_val);
            }
        } else {
            printf("%-15s ", "Uninitialized");
        }
        
        printf("%-8d %-8d\n", entry->line, entry->column);
    }
    printf("===== End of Symbol Table =====\n\n");
}


char* getTypeString(int type) {
    switch(type) {
        case TYPE_INT: return "Int";
        case TYPE_FLOAT: return "Float";
        default: return "Unknown";
    }
}


char* getEntityCodeString(int code) {
    switch(code) {
        case VARIABLE: return "Variable";
        case CONSTANT: return "Constant";
        case ARRAY: return "Array";
        default: return "Unknown";
    }
}


int isConstant(int index) {
    if (index < 0 || index >= symtab.count) return 0;
    return symtab.entries[index].code == CONSTANT;
}


int isArray(int index) {
    if (index < 0 || index >= symtab.count) return 0;
    return symtab.entries[index].code == ARRAY;
}


int getSymbolType(int index) {
    if (index < 0 || index >= symtab.count) return -1;
    return symtab.entries[index].type;
}


int getArraySize(int index) {
    if (index < 0 || index >= symtab.count || !isArray(index)) return -1;
    return symtab.entries[index].size;
}


int compatible_types(int type1, int type2) {
   
    return (type1 == type2) || 
           (type1 == TYPE_FLOAT && type2 == TYPE_INT);  
}


void semanticError(char* message, int line, int column) {
    printf("Semantic Error: %s at line %d, column %d\n", message, line, column);
}