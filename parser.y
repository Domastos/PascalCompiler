%{
#include <iostream>
#include <string>
#include "symbol.hpp"

int yylex(void);
int yyparse(void);
inline void yyerror (char const *s) {
    std::cerr << s << std::endl;
}
SymbolTable symtable;
%}

%token ID
%token NUM
%token RELOP
%token SIGN
%token MULOP
%token ASSIGNOP
%token OR
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

%%

program:
    PROGRAM ID '(' identifier_list ')' ';'
    declarations
    subprogram_declarations
    compound_statement
    '.'
    ;

identifier_list:
    ID
    |
    identifier_list ',' ID
    ;

declarations:
    declarations VAR identifier_list ':' type ';'
    |
    ;

type:
    standard_type
    |
    ARRAY '[' NUM '.' '.' NUM ']' OF standard_type;

standard_type:
    INTEGER
    |
    REAL
    ;

subprogram_declarations:
    subprogram_declarations subprogram_declaration ';'
    |
    ;

subprogram_declaration:
    subprogram_head declarations compound_statement;

subprogram_head:
    FUNCTION ID arguments ':' standard_type ';'
    |
    PROCEDURE ID arguments ';'
    ;

arguments:
    '(' parameter_list ')'
    |
    ;

parameter_list:
    identifier_list ':' type
    |
    parameter_list ';' identifier_list ':' type
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
    ID '[' expression ']'
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
    NUM
    |
    '(' expression ')'
    |
    NOT factor
    ;

%%
