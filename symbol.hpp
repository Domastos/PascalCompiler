#pragma once

#include <string>
#include <vector>
#include <algorithm>
#include <iostream>
#include <iomanip>
#include "parser.hpp"

enum Relop : int
{
    NotEqual,
    LesserEqual,
    GreaterEqual,
    Greater,
    Equal,
    Lesser
};

inline std::string relopSymbol(Relop op) {
    switch(op){
        case NotEqual:
            return "jne";
            break;
        case LesserEqual:
            return "jle";
            break;
        case GreaterEqual:
            return "jge";
            break;
        case Greater:
            return "jg";
            break;
        case Equal:
            return "je";
            break;
        case Lesser:
            return "jl";
            break;
        }
}

enum Sign : int
{
    Positive,
    Negative
};

inline std::string signSymbol(Sign si) {
    switch(si){
        case Positive:
            return "add";
            break;
        case Negative:
            return "sub";
            break;
        }
}

// horrible unscoped enum because yylval has to be an int
enum Mulop : int
{
    Multiply,
    Divide,
    Div,
    Modulo,
    And
};

inline std::string mulopSymbol(Mulop op) {
    switch(op){
        case Multiply:
            return "mul";
            break;
        case Divide:
            return "div";
            break;
        case Div:
            return "div";
            break;
        case Modulo:
            return "mod";
            break;
        case And:
            return "and";
            break;
        }
}

enum class Type : int
{
    Integer = 1,
    Real = 2,
    Undefined = -1
};

struct Symbol {
    std::string id;
    Type type {Type::Undefined};
    int token {ID};
    bool reference {false};
    bool global {true};
    int address{0};
    double value {0.0};
    std::vector<Type> arguments;
};

class SymbolTable {
public:
  int lookup(std::string id);
  int lookupFunction(std::string id);
  int insert(Symbol symbol);
  void cleanLocal();
  Symbol& at(int i);
  int getSize(Symbol& sym);
  int calculateAddress(bool global, int pos);
  int insertTemp(bool global, Type type);
  int insertLabel();
  void print();

private:
  std::vector<Symbol> symbols;
  int tempCounter {0};
  int labelCounter {0};
};

extern SymbolTable symtable;
extern volatile int localSize;

inline std::string typeSuffix(Type type) {
    switch(type) {
        case Type::Integer:
            return ".i";
            break;
        case Type::Real:
            return ".r";
            break;
        default:
            return ".u";
            break;
        }
}

inline std::string toAddress(Symbol& sym) {
    if(sym.token == NUM) {
        if(sym.type == Type::Integer)
            return std::string("#") + std::to_string(static_cast<int>(sym.value));
        return std::string("#") + std::to_string(sym.value);
    }

    std::string result = "";
    result += (sym.reference) ? "*" : "";
    result += (sym.global) ? "" : ((sym.address > 0) ? "BP+" : "BP");
    result += (sym.token == FUNCTION) ? "BP+" : "";
    result += std::to_string(sym.address);
    return result;
}