%{
// #define YYDEBUG 1
#include <iostream>
#include <string>
#include <sstream>
#include "symbol.hpp"

int yylex(void);
int yyparse(void);
inline void yyerror (char const *s) {
    std::cerr << s << std::endl;
}

SymbolTable symtable;

std::vector<int> identifiers;
volatile bool isGlobal = true;
std::stringstream buffer;
volatile int localSize = 0;
%}

%token PROGRAM
%token VAR
%token INTEGER
%token REAL
%token FUNCTION
%token PROCEDURE
%token BEGIN_T // BEGIN is a macro in lexer.cpp
%token END
%token IF
%token THEN
%token ELSE
%token WHILE
%token DO
%token NOT
%token ARRAY
%token OF
%token ID
%token NUM
%token RELOP
%token SIGN
%token MULOP
%token ASSIGNOP
%token OR

%%

program:
    PROGRAM ID '(' identifier_list ')' ';'{
        isGlobal = true;
        std::cout << "jump.i #" + symtable.at($1).id <<"\n";
        identifiers.clear();
    }
    declarations
    subprogram_declarations {
        std::cout << symtable.at($1).id << ":" << "\n";
    }
    compound_statement {
        if(buffer.str().size()) {
            std::cout << buffer.rdbuf();
            std::stringstream().swap(buffer);
        }
    }
    '.' {
        std::cout << "exit" << "\n";
        symtable.print();
    }
    ;

identifier_list:
    ID {
        identifiers.push_back($1);
    }
    |
    identifier_list ',' ID {
        identifiers.push_back($3);
    }
    ;

declarations:
    declarations VAR identifier_list ':' type ';' {
        for (auto& i : identifiers) {
            switch($5) {
                case INTEGER:
                    symtable.at(i).token = VAR;
                    symtable.at(i).type = Type::Integer;
                    break;
                case REAL:
                    symtable.at(i).token = VAR;
                    symtable.at(i).type = Type::Real;
                    break;
                default:
                    yyerror("INVALID TYPE");
            }
            symtable.at(i).global = isGlobal;
            symtable.at(i).address = symtable.calculateAddress(isGlobal, i);
            if(!isGlobal) localSize += symtable.getSize(symtable.at(i));
        }
        identifiers.clear();
    }
    |
    ;

type:
    standard_type
    |
    ARRAY '[' NUM '.' '.' NUM ']' OF standard_type {std::cerr << "UNSUPPORTED" << "\n";};

standard_type:
    INTEGER {$$ = INTEGER;}
    |
    REAL {$$ = REAL;}
    ;

subprogram_declarations:
    subprogram_declarations subprogram_declaration ';'
    |
    ;

subprogram_declaration:
    subprogram_head
    declarations
    compound_statement {
        std::cout << "enter.i #" << localSize << "\n";
        localSize = 0;
        if(buffer.str().size()) {
            std::cout << buffer.rdbuf();
            std::stringstream().swap(buffer);
        }
        std::cout << "leave" << "\n";
        std::cout << "return" << "\n";
        symtable.print();
        symtable.cleanLocal();
        isGlobal = true;
    };

subprogram_head:
    FUNCTION ID arguments ':' standard_type ';' {
        isGlobal = false;
        symtable.at($2).token = FUNCTION;
        symtable.at($2).address = 8;
        symtable.at($2).global = true;
        symtable.at($2).reference = true;
        switch($5) {
            case INTEGER:
                symtable.at($2).type = Type::Integer;
                break;
            case REAL:
                symtable.at($2).type = Type::Real;
                break;
        }
        std::cout << symtable.at($2).id << ":" << "\n";
        // DEBUG
        std::cerr << symtable.at($2).id << " ";
        for(auto i: symtable.at($2).arguments) 
            std::cerr << static_cast<int>(i) << " ";
        std::cerr << "-> " << static_cast<int>(symtable.at($2).type);
        std::cerr << "\n";
    }
    |
    PROCEDURE ID arguments ';' {
        isGlobal = false;
        symtable.at($2).token = PROCEDURE;
        std::cout << symtable.at($2).id << ":" << "\n";
        // DEBUG
        std::cerr << symtable.at($2).id << " ";
        for(auto i: symtable.at($2).arguments) 
            std::cerr << static_cast<int>(i) << " ";
        std::cerr << "-> " << static_cast<int>(symtable.at($2).type);
        std::cerr << "\n";
    }
    ;

arguments:
    '(' parameter_list ')'
    |
    ;

parameter_list:
    identifier_list ':' type{
        int paramsCounter  = 0;
        for (auto& i : identifiers) {
            switch($3) {
                case INTEGER:
                    symtable.at(i).token = VAR;
                    symtable.at(i).type = Type::Integer;
                    break;
                case REAL:
                    symtable.at(i).token = VAR;
                    symtable.at(i).type = Type::Real;
                    break;
                default:
                    yyerror("INVALID TYPE");
            }
            symtable.at(i).reference = true;
            symtable.at(i).address = 12 + paramsCounter * 4;
            ++paramsCounter;
            symtable.at(i).global = false;
            symtable.at($-1).arguments.push_back(symtable.at(i).type); // $-1 = ID
        }
        identifiers.clear();
    }
    |
    parameter_list ';' identifier_list ':' type {
        int paramsCounter  = 0;
        for (auto& i : identifiers) {
            switch($5) {
                case INTEGER:
                    symtable.at(i).token = VAR;
                    symtable.at(i).type = Type::Integer;
                    break;
                case REAL:
                    symtable.at(i).token = VAR;
                    symtable.at(i).type = Type::Real;
                    break;
                default:
                    yyerror("INVALID TYPE");
            }
            symtable.at(i).reference = true;
            symtable.at(i).address = 12 + paramsCounter * 4;
            ++paramsCounter;
            symtable.at(i).global = false;
            symtable.at($-1).arguments.push_back(symtable.at(i).type);
        }
        identifiers.clear();
    }
    ;

compound_statement:
    BEGIN_T
    optional_statement
    END
    ;

optional_statement:
    statement_list
    |
    ;

statement_list:
    statement
    |
    statement_list ';' statement
    ;

statement:
    variable ASSIGNOP expression
    |
    procedure_statement
    |
    compound_statement
    |
    IF expression THEN statement ELSE statement
    |
    WHILE expression DO statement
    ;

variable:
    ID
    |
    ID '[' expression ']' {std::cerr << "UNSUPPORTED" << "\n";};
    ;

procedure_statement:
    ID
    |
    ID '(' expression_list ')'
    ;

expression_list:
    expression
    |
    expression_list ',' expression
    ;

expression:
    simple_expression
    |
    simple_expression RELOP simple_expression
    ;

simple_expression:
    term
    |
    SIGN term
    |
    simple_expression SIGN term
    |
    simple_expression OR term
    ;

term:
    factor
    |
    term MULOP factor
    ;

factor:
    variable
    |
    ID '(' expression_list ')'
    |
    NUM {symtable.at($1).global = isGlobal;}
    |
    '(' expression ')'
    |
    NOT factor
    ;

%%