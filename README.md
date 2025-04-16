# MiniSoft Compiler

A compiler for the MiniSoft language developed with Flex and Bison. This project was created as part of the Compilation course at the University of Science and Technology Houari Boumediene (USTHB).

## Project Overview

The MiniSoft compiler implements a complete compilation process for a simple educational programming language. It features:

- Lexical analysis using Flex
- Syntactic analysis using Bison
- Semantic analysis with comprehensive error checking
- Symbol table management
- Detailed error reporting with line and column information

The compiler can detect various errors including:
- Undeclared identifiers
- Duplicate declarations
- Type incompatibilities
- Division by zero (for constant expressions)
- Array index out of bounds
- Attempt to modify constants
- Invalid loop control variables

## MiniSoft Language Features

MiniSoft is a simple programming language with the following features:

- Integer and floating-point data types
- Variable and constant declarations
- Array support
- Arithmetic and logical operations
- Control structures (if-else, while loops, for loops)
- Input/output operations
- Single-line and multi-line comments

### Sample Program

```
MainPrgm L3_software;
Var 
    <!- Variable declarations ->
    let x, y, z: Int;
    let a, b: Float;
    let arr: [Int; 10];
    @define Const PI: Float = 3.14;
    @define Const MAX: Int = 100;

BeginPg
{
    {-- Main program body --}
    x := 10;
    y := 20;
    z := x + y;
    
    a := 1.5;
    b := a * PI;
    
    arr[0] := 5;
    
    if (z > MAX) then {
        output("z exceeds maximum");
    } else {
        output("z is within limits: ", z);
    }
    
    for i from 0 to 9 step 1 {
        arr[i] := i * 2;
    }
    
    do {
        x := x - 1;
    } while (x > 0);
    
    input(y);
    output("You entered: ", y);
}
EndPg;
```

## Building and Running

### Prerequisites

To build and run the MiniSoft compiler, you need:
- GCC compiler
- Flex lexical analyzer
- Bison parser generator
- Make build system

On Ubuntu/Debian, you can install these with:
```bash
sudo apt-get install build-essential flex bison
```

### Build Instructions

1. Clone this repository:
   ```bash
   git clone https://github.com/your-username/minisoft-compiler.git
   cd minisoft-compiler
   ```

2. Build the compiler:
   ```bash
   make
   ```

3. Clean build files (optional):
   ```bash
   make clean
   ```

### Running the Compiler

To compile a MiniSoft program:
```bash
./compiler test.txt
```

This will analyze the input file and report any errors found during the compilation process. If compilation is successful, it will output "Program successfully parsed" and display the symbol table.

## Project Structure

- `lexer.l`: Flex specification for lexical analysis
- `parser.y`: Bison specification for syntactic and semantic analysis
- `symtab.h/c`: Symbol table implementation
- `Makefile`: Build configuration
- `test.txt`: Example MiniSoft program

## Implementation Details

The compiler is implemented in three main phases:

1. **Lexical Analysis**: Identifies tokens, validates identifiers and numeric constants
2. **Syntactic Analysis**: Validates program structure and builds an abstract syntax tree
3. **Semantic Analysis**: Performs type checking, validates array accesses, handles constant expressions

Special attention was given to:
- Detecting division by zero in expressions like `a := 1 / (7 - 7)`
- Preventing modification of constants
- Validating array indices
- Checking loop control variables

## Authors

- Hermez Abderrahim
- Belkacemi Abderrahim

## License

This project is licensed under the MIT License - see the LICENSE file for details.
