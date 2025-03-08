all:
	bison -d parser.y
	flex lexer.l
	gcc -o compiler parser.tab.c lex.yy.c main.c -L/opt/homebrew/opt/flex/lib -lfl

