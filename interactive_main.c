#include "parser.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern FILE *yyin;
extern int yyparse();
extern void yyrestart(FILE *);
extern int line;
extern int column;

// Function to reset parser state between parses
void reset_parser() {
  // Reset line and column counters
  line = 1;
  column = 1;

  // Optionally reset other state variables
  // (like symbol table, etc. if you want to keep them separate between parses)
}

int main(int argc, char *argv[]) {
  char buffer[1024];
  FILE *temp_file = NULL;

  if (argc > 1) {
    // Regular file mode
    FILE *file = fopen(argv[1], "r");
    if (!file) {
      fprintf(stderr, "Cannot open file %s\n", argv[1]);
      return 1;
    }
    yyin = file;
    printf("Parsing file %s...\n", argv[1]);
    yyparse();
    fclose(file);
  } else {
    // Interactive mode
    printf("MiniSoft Interactive Parser\n");
    printf("Enter code (type 'exit;' on a new line to quit):\n");

    while (1) {
      // Create a temporary file for input
      temp_file = tmpfile();
      if (!temp_file) {
        fprintf(stderr, "Error creating temporary file\n");
        return 1;
      }

      printf(">> ");
      fflush(stdout);

      // Read until "exit;" or EOF
      char line_buffer[1024];
      int done = 0;

      while (!done && fgets(line_buffer, sizeof(line_buffer), stdin)) {
        if (strcmp(line_buffer, "exit;\n") == 0) {
          done = 1;
          break;
        }

        fputs(line_buffer, temp_file);

        // If the line ends with a semicolon, try parsing
        if (strchr(line_buffer, ';')) {
          break;
        }

        printf(".. ");
        fflush(stdout);
      }

      if (done) {
        break;
      }

      // EOF encountered
      if (feof(stdin)) {
        break;
      }

      // Rewind temp file and parse
      rewind(temp_file);
      yyin = temp_file;
      yyrestart(yyin);
      reset_parser();

      printf("\n");
      yyparse();
      printf("\n");

      fclose(temp_file);
    }
  }

  return 0;
}
