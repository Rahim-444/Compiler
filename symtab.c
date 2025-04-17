#include "symtab.h"

SymbolTable symtab;

void initSymbolTable(void) {
  symtab.head = NULL;
  symtab.count = 0;
}

SymbolEntry *lookupSymbol(char *name) {
  SymbolNode *current = symtab.head;
  while (current != NULL) {
    if (strcmp(current->entry.name, name) == 0) {
      return &current->entry;
    }
    current = current->next;
  }
  return NULL;
}

SymbolEntry *insertSymbol(char *name, int code, int type, int size, int line,
                          int column) {
  SymbolNode *newNode = (SymbolNode *)malloc(sizeof(SymbolNode));
  if (newNode == NULL) {
    printf("Memory allocation failed\n");
    return NULL;
  }

  SymbolEntry *entry = &newNode->entry;
  strncpy(entry->name, name, 14);
  entry->name[14] = '\0';
  entry->code = code;
  entry->type = type;
  entry->size = size;
  entry->line = line;
  entry->column = column;
  entry->isInitialized = 0;

  newNode->next = symtab.head;
  symtab.head = newNode;
  symtab.count++;

  return entry;
}

void updateSymbolValue(SymbolEntry *entry, void *value) {
  if (entry == NULL)
    return;
  entry->isInitialized = 1;
  if (entry->type == TYPE_INT) {
    entry->value.int_val = *((int *)value);
  } else if (entry->type == TYPE_FLOAT) {
    entry->value.float_val = *((float *)value);
  }
}

void updateSymbolOptions(int type, int arraySize) {
  if (type != TYPE_INT && type != TYPE_FLOAT) {
    printf("Invalid type for symbol table update\n");
    return;
  }
  SymbolNode *current = symtab.head;
  while (current != NULL) {
    if (current->entry.type == 0) {
      current->entry.type = type;
    }
    if (current->entry.code == 0 && current->entry.size == 0 && arraySize > 0) {
      current->entry.size = arraySize;
      current->entry.code = ARRAY;
    } else if (current->entry.code == 0 && current->entry.size == 0) {
      current->entry.code = VARIABLE;
    }
    current = current->next;
  }
}

void displaySymbolTable(void) {
  printf("\n===== Symbol Table =====\n");
  printf("%-15s %-10s %-8s %-10s %-15s %-8s %-8s\n", "Name", "Entity", "Type",
         "Size", "Value", "Line", "Column");
  printf("---------------------------------------------------------------------"
         "\n");

  SymbolNode *current = symtab.head;
  while (current != NULL) {
    SymbolEntry *entry = &current->entry;
    printf("%-15s %-10s %-8s ", entry->name, getEntityCodeString(entry->code),
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
    current = current->next;
  }
  printf("===== End of Symbol Table =====\n\n");
}

char *getTypeString(int type) {
  switch (type) {
  case TYPE_INT:
    return "Int";
  case TYPE_FLOAT:
    return "Float";
  default:
    return "Unknown";
  }
}

char *getEntityCodeString(int code) {
  switch (code) {
  case VARIABLE:
    return "Variable";
  case CONSTANT:
    return "Constant";
  case ARRAY:
    return "Array";
  default:
    return "Unknown";
  }
}

int isConstant(SymbolEntry *entry) {
  if (entry == NULL)
    return 0;
  return entry->code == CONSTANT;
}

int isArray(SymbolEntry *entry) {
  if (entry == NULL)
    return 0;
  return entry->code == ARRAY;
}

int getSymbolType(SymbolEntry *entry) {
  if (entry == NULL)
    return -1;
  return entry->type;
}

int getArraySize(SymbolEntry *entry) {
  if (entry == NULL || !isArray(entry))
    return -1;
  return entry->size;
}

int compatible_types(int type1, int type2) {
  return (type1 == type2) || (type1 == TYPE_FLOAT && type2 == TYPE_INT);
}

void semanticError(char *message, int line, int column) {
  printf("Semantic Error: %s at line %d, column %d\n", message, line, column);
}

void checkArrayAccess(char *name, int idx, int exprType, int isConstExpr,
                      int exprValue, int line, int column) {
  char errorMsg[256];
  SymbolEntry *entry = lookupSymbol(name);

  if (entry == NULL) {
    sprintf(errorMsg, "Undeclared identifier '%s'", name);
    semanticError(errorMsg, line, column);
    return;
  }

  if (!isArray(entry)) {
    sprintf(errorMsg, "Cannot use array indexing on non-array variable '%s'",
            name);
    semanticError(errorMsg, line, column);
    return;
  }

  if (exprType != TYPE_INT) {
    semanticError("Array index must be of integer type", line, column);
    return;
  }

  if (isConstExpr) {
    int size = getArraySize(entry);
    if (exprValue < 0 || exprValue >= size) {
      sprintf(errorMsg, "Array index %d out of bounds [0-%d] for array '%s'",
              exprValue, size - 1, name);
      semanticError(errorMsg, line, column);
    }
  }
}

void checkArrayAssignment(char *name, int idx, int exprType, int assignType,
                          int line, int column) {
  char errorMsg[256];
  SymbolEntry *entry = lookupSymbol(name);

  if (entry == NULL || !isArray(entry))
    return;

  int arrayType = getSymbolType(entry);
  if (!compatible_types(arrayType, assignType)) {
    sprintf(
        errorMsg,
        "Type mismatch in array assignment: array '%s' is %s, expression is %s",
        name, getTypeString(arrayType), getTypeString(assignType));
    semanticError(errorMsg, line, column);
  }
}

int isValidLoopVariable(char *name, int line, int column) {
  char errorMsg[256];
  SymbolEntry *entry = lookupSymbol(name);

  if (entry == NULL) {
    sprintf(errorMsg, "Undeclared loop variable '%s'", name);
    semanticError(errorMsg, line, column);
    return 0;
  }

  if (isConstant(entry)) {
    sprintf(errorMsg, "Cannot use constant '%s' as a loop variable", name);
    semanticError(errorMsg, line, column);
    return 0;
  }

  if (isArray(entry)) {
    sprintf(errorMsg, "Cannot use array '%s' as a loop variable", name);
    semanticError(errorMsg, line, column);
    return 0;
  }

  return 1;
}

int isValidIOVariable(char *name, int line, int column) {
  char errorMsg[256];
  SymbolEntry *entry = lookupSymbol(name);

  if (entry == NULL) {
    sprintf(errorMsg, "Undeclared identifier '%s'", name);
    semanticError(errorMsg, line, column);
    return 0;
  }

  if (isConstant(entry)) {
    sprintf(errorMsg, "Cannot perform IO on constant '%s'", name);
    semanticError(errorMsg, line, column);
    return 0;
  }

  return 1;
}

int isValidIOArrayElement(char *name, int exprType, int isConstExpr,
                          int exprValue, int line, int column) {
  char errorMsg[256];
  SymbolEntry *entry = lookupSymbol(name);

  if (entry == NULL) {
    sprintf(errorMsg, "Undeclared identifier '%s'", name);
    semanticError(errorMsg, line, column);
    return 0;
  }

  if (!isArray(entry)) {
    sprintf(errorMsg, "Cannot use array indexing on non-array variable '%s'",
            name);
    semanticError(errorMsg, line, column);
    return 0;
  }

  if (exprType != TYPE_INT) {
    semanticError("Array index must be of integer type", line, column);
    return 0;
  }

  if (isConstExpr) {
    int size = getArraySize(entry);
    if (exprValue < 0 || exprValue >= size) {
      sprintf(errorMsg, "Array index %d out of bounds [0-%d] for array '%s'",
              exprValue, size - 1, name);
      semanticError(errorMsg, line, column);
      return 0;
    }
  }

  return 1;
}

int checkAssignmentCompatibility(char *varName, int varType, int exprType,
                                 int line, int column) {
  char errorMsg[256];
  if (!compatible_types(varType, exprType)) {
    sprintf(
        errorMsg,
        "Type mismatch in assignment: variable '%s' is %s, expression is %s",
        varName, getTypeString(varType), getTypeString(exprType));
    semanticError(errorMsg, line, column);
    return 0;
  }
  return 1;
}

void checkLoopStep(int isConstant, int value, int line, int column) {
  if (isConstant && value == 0) {
    semanticError("Step value in for loop cannot be zero", line, column);
  }
}

void checkConditionType(int exprType, const char *context, int line,
                        int column) {
  char errorMsg[256];
  if (exprType != TYPE_INT) {
    sprintf(errorMsg, "Condition in %s must evaluate to a boolean (Int type)",
            context);
    semanticError(errorMsg, line, column);
  }
}

void checkDivisionByZero(int isConstant, int type, void *value, int line,
                         int column) {
  if (!isConstant)
    return;
  int isZero =
      (type == TYPE_INT) ? (*(int *)value == 0) : (*(float *)value == 0.0f);
  if (isZero) {
    semanticError("Division by zero", line, column);
  }
}
