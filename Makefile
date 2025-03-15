# Makefile for MiniSoft Compiler with Interactive Mode

all: compiler

compiler: parser.tab.o lex.yy.o interactive_main.o
	gcc -o compiler parser.tab.o lex.yy.o interactive_main.o -L/opt/homebrew/opt/flex/lib -lfl

parser.tab.c parser.tab.h: parser.y
	bison -d parser.y

lex.yy.c: lexer.l parser.tab.h
	flex lexer.l

parser.tab.o: parser.tab.c
	gcc -c parser.tab.c

lex.yy.o: lex.yy.c
	gcc -c lex.yy.c

interactive_main.o: interactive_main.c parser.tab.h
	gcc -c interactive_main.c

clean:
	rm -f compiler *.o lex.yy.c parser.tab.c parser.tab.h parser.output

.PHONY: all clean
