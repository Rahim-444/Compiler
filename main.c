#include <stdio.h>

extern int yyparse();

int main() {
  printf("Enter expressions (Ctrl+D to exit):\n");
  while (!feof(stdin)) {
    yyparse(); // Continue parsing until EOF
  }
  return 0;
}

