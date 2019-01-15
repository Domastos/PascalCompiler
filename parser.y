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
std::stringstream buffer;
volatile bool isGlobal = true;
volatile int localSize = 0;

int callMethod(Symbol& sym);
void emitAssignment(int lhs, int rhs);
int emitExpression(std::string op, int lhs, int rhs);
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
        std::cout << "\t" << "jump.i #" + symtable.at($1).id <<"\n";
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
        std::cout << "\t" << "exit" << "\n";
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
        std::cout << "\t" << "enter.i #" << localSize << "\n";
        localSize = 0;
        if(buffer.str().size()) {
            std::cout << buffer.rdbuf();
            std::stringstream().swap(buffer);
        }
        std::cout << "\t" << "leave" << "\n";
        std::cout << "\t" << "return" << "\n";
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
        std::cerr << symtable.at($2).id << " ( ";
        for(auto i: symtable.at($2).arguments) 
            std::cerr << static_cast<int>(i) << " ";
        std::cerr << ") -> " << static_cast<int>(symtable.at($2).type);
        std::cerr << "\n";
    }
    |
    PROCEDURE ID arguments ';' {
        isGlobal = false;
        symtable.at($2).token = PROCEDURE;
        std::cout << symtable.at($2).id << ":" << "\n";
        // DEBUG
        std::cerr << symtable.at($2).id << " ( ";
        for(auto i: symtable.at($2).arguments) 
            std::cerr << static_cast<int>(i) << " ";
        std::cerr << ")\n";
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
    variable ASSIGNOP expression {
        emitAssignment($1, $3);
    }
    |
    procedure_statement
    |
    compound_statement
    |
    IF expression {
        $1 = symtable.insertLabel(); // end of then

        std::string zero = (symtable.at($2).type == Type::Real) ?
                                std::string("#0.0") : 
                                std::string("#0");
        buffer << "\t" << relopSymbol(Relop::Equal) << typeSuffix(symtable.at($2).type) 
                << " "
                << zero
                << ","
                << toAddress(symtable.at($2))
                << ","
                << "#" << symtable.at($1).id
                << "\n";
    } THEN statement {
        $4 = symtable.insertLabel(); // end of else
        buffer << "\t" << "jump.i #" << symtable.at($4).id << "\n"; // skip else
        buffer << symtable.at($1).id << ":" << "\n";
    } ELSE statement {
        buffer << symtable.at($4).id << ":" << "\n";
    }
    |
    WHILE {
        $1 = symtable.insertLabel(); // start
        buffer << symtable.at($1).id << ":" << "\n";
    }
    expression DO {
        $4 = symtable.insertLabel(); // end
        std::string zero = (symtable.at($3).type == Type::Real) ?
                                std::string("#0.0") : 
                                std::string("#0");
        buffer << "\t" << relopSymbol(Relop::Equal) << typeSuffix(symtable.at($3).type) 
                << " "
                << zero
                << ","
                << toAddress(symtable.at($3))
                << ","
                << "#" << symtable.at($4).id
                << "\n";
    }
    statement {
        buffer << "\t" << "jump.i #" << symtable.at($1).id << "\n"; // back to start
        buffer << symtable.at($4).id << ":" << "\n"; // end
    }
    ;

variable:
    ID
    |
    ID '[' expression ']' {std::cerr << "UNSUPPORTED" << "\n";};
    ;

procedure_statement:
    ID {
        if(symtable.at($1).token == FUNCTION || symtable.at($1).token == PROCEDURE) {
            if(symtable.at($1).arguments.size() > 0)
                yyerror("FUNCTION HAS ARGS");

            $$ = symtable.insertTemp(isGlobal, symtable.at($1).type);
            buffer << "\t" << "push.i "
            << toAddress(symtable.at($$))
            << "\n";
            buffer << "\t" << "call.i "
            << "#" << symtable.at($1).id
            << "\n";
            buffer << "\t" << "incsp.i #4\n";
        }
        else
            yyerror("NOT PROCEDURE OR FUNCTION");
    }
    |
    ID '(' expression_list ')' {
        if($1 == symtable.lookup("write")) {
            for(auto& i : identifiers) {
                buffer << "\t" << "write" << typeSuffix(symtable.at(i).type) << " "
                << toAddress(symtable.at(i))
                << "\n";
            }
        } 
        else if ($1 == symtable.lookup("read")){
            for(auto& i : identifiers) {
                buffer << "\t" << "read" << typeSuffix(symtable.at(i).type) << " "
                << toAddress(symtable.at(i))
                << "\n";
            }
        }
        else if(symtable.at($1).token == FUNCTION) {
            $$ = callMethod(symtable.at($1));
        }
        else if (symtable.at($1).token == PROCEDURE) {
            callMethod(symtable.at($1));
        }
        else
            yyerror("NOT PROCEDURE OR FUNCTION");
        identifiers.clear();
    }
    ;

expression_list:
    expression {
        identifiers.push_back($1);
    }
    |
    expression_list ',' expression {
        identifiers.push_back($3);
    }
    ;

expression:
    simple_expression
    |
    simple_expression RELOP simple_expression {
        int lhs = $1;
        int rhs = $3;
        if(symtable.at(lhs).type == Type::Real || symtable.at(rhs).type == Type::Real) {
            $$ = symtable.insertTemp(isGlobal, Type::Real);
            if(symtable.at(lhs).type == Type::Integer) {
                int temp = symtable.insertTemp(isGlobal, Type::Real);
                emitAssignment(temp, lhs);
                lhs = temp;
            }
            else if(symtable.at(rhs).type == Type::Integer) {
                int temp = symtable.insertTemp(isGlobal, Type::Real);
                emitAssignment(temp, rhs);
                rhs = temp;
            }
        }
        else
            $$ = symtable.insertTemp(isGlobal, Type::Integer);

        int isTrue = symtable.insertLabel();
        int afterTrue = symtable.insertLabel();
        buffer << "\t" << relopSymbol(static_cast<Relop>($2)) << typeSuffix(symtable.at($$).type) << " "
        << toAddress(symtable.at(lhs)) << ","
        << toAddress(symtable.at(rhs)) << ","
        << "#" << symtable.at(isTrue).id
        << "\n";
        switch (symtable.at($2).type) {
            case Type::Integer:
                buffer << "\t" << "mov.i #0," << toAddress(symtable.at($$)) << "\n";
                break;
            case Type::Real:
                buffer << "\t" << "mov.r #0.0," << toAddress(symtable.at($$)) << "\n";
                break;
        }
        buffer << "\t" << "jump.i #" << symtable.at(afterTrue).id << "\n";
        buffer << symtable.at(isTrue).id << ":" << "\n";
        switch (symtable.at($2).type) {
            case Type::Integer:
                buffer << "\t" << "mov.i #1," << toAddress(symtable.at($$)) << "\n";
                break;
            case Type::Real:
                buffer << "\t" << "mov.r #1.0," << toAddress(symtable.at($$)) << "\n";
                break;
        }
        buffer << symtable.at(afterTrue).id << ":" << "\n";
    }
    ;

simple_expression:
    term
    |
    SIGN term {
        if($1 == Sign::Positive)
            $$ = $2;
        else {
            $$ = symtable.insertTemp(isGlobal, symtable.at($2).type);
            buffer << "\t" << signSymbol(static_cast<Sign>($1)) << typeSuffix(symtable.at($$).type) 
            << " "
            << "#0,"
            << toAddress(symtable.at($2)) 
            << ","
            << toAddress(symtable.at($$))
            << "\n";
        }
    }
    |
    simple_expression SIGN term {
        $$ = emitExpression(signSymbol(static_cast<Sign>($2)), $1, $3);
    }
    |
    simple_expression OR term {
        $$ = emitExpression("or", $1, $3);
    }
    ;

term:
    factor
    |
    term MULOP factor {
        $$ = emitExpression(mulopSymbol(static_cast<Mulop>($2)), $1, $3);
    }
    ;

factor:
    variable {
        if(symtable.at($1).token == PROCEDURE)
            yyerror("PROCEDURE HAS NO RETVAL");
        if(symtable.at($1).token == FUNCTION) {
            if(symtable.at($1).arguments.size() > 0)
                yyerror("FUNCTION HAS ARGS");

            $$ = symtable.insertTemp(isGlobal, symtable.at($1).type);
            buffer << "\t" << "push.i "
            << toAddress(symtable.at($$))
            << "\n";
            buffer << "\t" << "call.i "
            << "#" << symtable.at($1).id
            << "\n";
            buffer << "\t" << "incsp.i #4\n";
        }
        // if actual variable just propagate
        $$ = $1;
    }
    |
    ID '(' expression_list ')' {
        if(symtable.at($1).token != FUNCTION)
            yyerror("NOT A FUNCTION");
        $$ = callMethod(symtable.at($1));
    }
    |
    NUM
    |
    '(' expression ')' {
        $$ = $2;
    }
    |
    NOT factor {
        $$ = symtable.insertTemp(isGlobal, symtable.at($2).type);
        int isZero = symtable.insertLabel();
        int afterZero = symtable.insertLabel();
        switch (symtable.at($2).type) {
            case Type::Integer:
                buffer << "\t" << "je.i #0," << toAddress(symtable.at($2)) << "#"+symtable.at(0).id << "\n";
                buffer << "\t" << "mov.i #0," << toAddress(symtable.at($$)) << "\n";
                break;
            case Type::Real:
                buffer << "\t" << "je.r #0.0," << toAddress(symtable.at($2)) << "#"+symtable.at(0).id << "\n";
                buffer << "\t" << "mov.r #0.0," << toAddress(symtable.at($$)) << "\n";
                break;
        }
        buffer << "\t" << "jump.i #" << symtable.at(afterZero).id << "\n";
        buffer << symtable.at(isZero).id << ":" << "\n";
        switch (symtable.at($2).type) {
            case Type::Integer:
                buffer << "\t" << "mov.i #1," << toAddress(symtable.at($$)) << "\n";
                break;
            case Type::Real:
                buffer << "\t" << "mov.r #1.0," << toAddress(symtable.at($$)) << "\n";
                break;
        }
        buffer << symtable.at(afterZero).id << ":" << "\n";
    }
    ;

%%

int callMethod(Symbol& sym) {
    if (identifiers.size() != sym.arguments.size()) 
        yyerror("INVALID ARGUMENT COUNT");
    
    int pushCounter = 0;
    for(int i = 0; i < identifiers.size() ; ++i) {
        int index = identifiers.at(i);
        if(symtable.at(identifiers.at(i)).token == NUM) {
            int pos = symtable.insertTemp(isGlobal, sym.arguments.at(i));
            emitAssignment(pos, identifiers.at(i));
            index = pos;
        }
        if (symtable.at(index).type != sym.arguments.at(i)) 
            yyerror("TYPE MISMATCH");
        buffer << "\t" << "push.i #"
            << toAddress(symtable.at(index))
            << "\n";
        ++pushCounter;
    }
    int resultPos = -1;
    if(sym.token == FUNCTION) {
        int pos = symtable.insertTemp(isGlobal, sym.type);
        buffer << "\t" << "push.i #"
            << toAddress(symtable.at(pos))
            << "\n";
        ++pushCounter;
        resultPos = pos;
    }

    identifiers.clear();
    buffer << "\t" << "call.i "
        << "#" << sym.id
        << "\n";
    buffer << "\t" << "incsp.i #"<< std::to_string(pushCounter*4) <<"\n";
    return resultPos;
}

void emitAssignment(int lhs, int rhs) {
    if(symtable.at(lhs).type == symtable.at(rhs).type)
            buffer << "\t" << "mov"
            << typeSuffix(symtable.at(lhs).type)
            << " "
            << toAddress(symtable.at(rhs))
            << ","
            << toAddress(symtable.at(lhs))
            << "\n";
    else {
        if(symtable.at(lhs).type == Type::Integer)
            buffer << "\t" << "realtoint"
            << typeSuffix(symtable.at(lhs).type)
            << " "
            << toAddress(symtable.at(rhs))
            << ","
            << toAddress(symtable.at(lhs))
            << "\n";
        else 
            buffer << "\t" << "inttoreal"
            << typeSuffix(symtable.at(lhs).type)
            << " "
            << toAddress(symtable.at(rhs))
            << ","
            << toAddress(symtable.at(lhs))
            << "\n";
    }
}

int emitExpression(std::string op, int lhs, int rhs) {
    int dst = 0;
    if(symtable.at(lhs).type == Type::Real || symtable.at(rhs).type == Type::Real) {
        dst = symtable.insertTemp(isGlobal, Type::Real);
        if(symtable.at(lhs).type == Type::Integer) {
            int temp = symtable.insertTemp(isGlobal, Type::Real);
            emitAssignment(temp, lhs);
            lhs = temp;
        }
        else if (symtable.at(rhs).type == Type::Integer) {
            int temp = symtable.insertTemp(isGlobal, Type::Real);
            emitAssignment(temp, rhs);
            rhs = temp;
        }
    }
    else
        dst = symtable.insertTemp(isGlobal, Type::Integer);

    buffer << "\t" << op << typeSuffix(symtable.at(dst).type) << " "
    << toAddress(symtable.at(lhs)) << ","
    << toAddress(symtable.at(rhs)) << ","
    << toAddress(symtable.at(dst))
    << "\n";
    return dst;
}