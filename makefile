CC=g++
FL=flex
BI=bison

.PHONY: clean cleanintermediate

all: kompilator

kompilator: main.o lexer.o parser.o symbol.o
	$(CC) -o kompilator main.o lexer.o parser.o symbol.o -lfl

main.o: main.cpp parser.hpp
	$(CC) main.cpp -c -o main.o

symbol.o: symbol.cpp symbol.hpp
	$(CC) symbol.cpp -c -o symbol.o

lexer.o: lexer.cpp
	$(CC) lexer.cpp -c -o lexer.o

lexer.cpp: lexer.l parser.hpp symbol.hpp
	$(FL) --outfile=lexer.cpp lexer.l

parser.o: parser.cpp parser.hpp
	$(CC) parser.cpp -c -o parser.o

parser.cpp parser.hpp: parser.y symbol.hpp
	$(BI) --output=parser.cpp --defines=parser.hpp parser.y

clean: cleanintermediate
	rm -f parser.cpp parser.hpp lexer.cpp kompilator

cleanintermediate:
	rm -f *.o

