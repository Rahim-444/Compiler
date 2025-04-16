// Ces commentaires permettent de comprendre le rôle de chaque fonction
// directement dans l'IDE (par exemple, Visual Studio Code).
#include "symtab.h"

/* Global symbol table */
SymbolTable symtab;

/* Initialize symbol table */
void initSymbolTable() { symtab.count = 0; }

/* Look up a symbol by name, return index or -1 if not found */
int lookupSymbol(char *name) {
  for (int i = 0; i < symtab.count; i++) {
    if (strcmp(symtab.entries[i].name, name) == 0) {
      return i;
    }
  }
  return -1;
}

/* Insert a new symbol into the table */
int insertSymbol(char *name, int code, int type, int size, int line,
                 int column) {
  if (symtab.count >= MAX_SYMBOLS) {
    printf("Symbol table overflow\n");
    return -1;
  }

  int index = symtab.count++;
  SymbolEntry *entry = &symtab.entries[index];

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

/* Update a symbol's value */
void updateSymbolValue(int index, void *value) {
  if (index < 0 || index >= symtab.count)
    return;

  SymbolEntry *entry = &symtab.entries[index];
  entry->isInitialized = 1;

  if (entry->type == TYPE_INT) {
    entry->value.int_val = *((int *)value);
  } else if (entry->type == TYPE_FLOAT) {
    entry->value.float_val = *((float *)value);
  }
}

/* Update a symbol's type */
void updateSymbolType(int type) {
  if (type != TYPE_INT && type != TYPE_FLOAT) {
    printf("Invalid type for symbol table update\n");
    return;
  }

  for (int i = 0; i < symtab.count; i++) {
    if (symtab.entries[i].type == 0) {
      symtab.entries[i].type = type;
    }
  }
}

/* Display the symbol table */
void displaySymbolTable() {
  printf("\n===== Symbol Table =====\n");
  printf("%-15s %-10s %-8s %-10s %-15s %-8s %-8s\n", "Name", "Entity", "Type",
         "Size", "Value", "Line", "Column");
  printf("---------------------------------------------------------------------"
         "--\n");

  for (int i = 0; i < symtab.count; i++) {
    SymbolEntry *entry = &symtab.entries[i];

    printf("%-15s %-10s %-8s ", entry->name, getEntityCodeString(entry->code),
           getTypeString(entry->type));

    /* Print size for arrays, - otherwise */
    if (entry->code == ARRAY) {
      printf("%-10d ", entry->size);
    } else {
      printf("%-10s ", "-");
    }

    /* Print value if initialized */
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

/* Get string representation of type */
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

/* Get string representation of entity code */
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

/* Check if symbol is a constant */
int isConstant(int index) {
  if (index < 0 || index >= symtab.count)
    return 0;
  return symtab.entries[index].code == CONSTANT;
}

/* Check if symbol is an array */
int isArray(int index) {
  if (index < 0 || index >= symtab.count)
    return 0;
  return symtab.entries[index].code == ARRAY;
}

/* Get symbol type */
int getSymbolType(int index) {
  if (index < 0 || index >= symtab.count)
    return -1;
  return symtab.entries[index].type;
}

/* Get array size */
int getArraySize(int index) {
  if (index < 0 || index >= symtab.count || !isArray(index))
    return -1;
  return symtab.entries[index].size;
}

/* Check if types are compatible for assignment */
int compatible_types(int type1, int type2) {
  /* type1 is the target, type2 is the source */
  return (type1 == type2) ||
         (type1 == TYPE_FLOAT &&
          type2 == TYPE_INT); // Int can be assigned to Float
}

/* General semantic error reporting */
void semanticError(char *message, int line, int column) {
  printf("Semantic Error: %s at line %d, column %d\n", message, line, column);
}

/* Improved array access checking */
void checkArrayAccess(char *name, int idx, int exprType, int isConstExpr,
                      int exprValue, int line, int column) {
  char errorMsg[256];

  int symbolIdx = lookupSymbol(name);

  /* Check if symbol exists */
  if (symbolIdx < 0) {
    sprintf(errorMsg, "Undeclared identifier '%s'", name);
    semanticError(errorMsg, line, column);
    return;
  }

  /* Check if it's actually an array */
  if (!isArray(symbolIdx)) {
    sprintf(errorMsg, "Cannot use array indexing on non-array variable '%s'",
            name);
    semanticError(errorMsg, line, column);
    return;
  }

  /* Check if index expression is integer */
  if (exprType != TYPE_INT) {
    semanticError("Array index must be of integer type", line, column);
    return;
  }

  /* Check array bounds if index is a constant expression */
  if (isConstExpr) {
    int size = getArraySize(symbolIdx);
    if (exprValue < 0 || exprValue >= size) {
      sprintf(errorMsg, "Array index %d out of bounds [0-%d] for array '%s'",
              exprValue, size - 1, name);
      semanticError(errorMsg, line, column);
    }
  }
}

/* Improved array assignment checking */
void checkArrayAssignment(char *name, int idx, int exprType, int assignType,
                          int line, int column) {
  char errorMsg[256];

  int symbolIdx = lookupSymbol(name);

  /* We already checked existence and array status in checkArrayAccess */
  if (symbolIdx < 0 || !isArray(symbolIdx))
    return;

  /* Check type compatibility */
  int arrayType = getSymbolType(symbolIdx);
  if (!compatible_types(arrayType, assignType)) {
    sprintf(
        errorMsg,
        "Type mismatch in array assignment: array '%s' is %s, expression is %s",
        name, getTypeString(arrayType), getTypeString(assignType));
    semanticError(errorMsg, line, column);
  }
}

/* Check if a variable can be used as a loop control variable */
int isValidLoopVariable(char *name, int line, int column) {
  char errorMsg[256];

  int idx = lookupSymbol(name);
  if (idx < 0) {
    sprintf(errorMsg, "Undeclared loop variable '%s'", name);
    semanticError(errorMsg, line, column);
    return 0;
  }

  if (isConstant(idx)) {
    sprintf(errorMsg, "Cannot use constant '%s' as a loop variable", name);
    semanticError(errorMsg, line, column);
    return 0;
  }

  if (isArray(idx)) {
    sprintf(errorMsg, "Cannot use array '%s' as a loop variable", name);
    semanticError(errorMsg, line, column);
    return 0;
  }

  return 1;
}

/* Check if a variable can be used in an IO operation */
int isValidIOVariable(char *name, int line, int column) {
  char errorMsg[256];

  int idx = lookupSymbol(name);
  if (idx < 0) {
    sprintf(errorMsg, "Undeclared identifier '%s'", name);
    semanticError(errorMsg, line, column);
    return 0;
  }

  if (isConstant(idx)) {
    sprintf(errorMsg, "Cannot perform IO on constant '%s'", name);
    semanticError(errorMsg, line, column);
    return 0;
  }

  return 1;
}

/* Check if an array element can be used in an IO operation */
int isValidIOArrayElement(char *name, int exprType, int isConstExpr,
                          int exprValue, int line, int column) {
  char errorMsg[256];

  int idx = lookupSymbol(name);
  if (idx < 0) {
    sprintf(errorMsg, "Undeclared identifier '%s'", name);
    semanticError(errorMsg, line, column);
    return 0;
  }

  if (!isArray(idx)) {
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
    int size = getArraySize(idx);
    if (exprValue < 0 || exprValue >= size) {
      sprintf(errorMsg, "Array index %d out of bounds [0-%d] for array '%s'",
              exprValue, size - 1, name);
      semanticError(errorMsg, line, column);
      return 0;
    }
  }

  return 1;
}

/* Check assignment compatibility and produce detailed error message */
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

/* Check loop step value - cannot be zero */
void checkLoopStep(int isConstant, int value, int line, int column) {
  if (isConstant && value == 0) {
    semanticError("Step value in for loop cannot be zero", line, column);
  }
}

/* Check condition expression type */
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

  int isZero = 0;
  if (type == TYPE_INT) {
    isZero = (*(int *)value == 0);
  } else {
    isZero = (*(float *)value == 0.0f);
  }

  if (isZero) {
    semanticError("Division by zero", line, column);
  }
}
