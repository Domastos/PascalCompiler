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

enum Sign : int
{
    Positive,
    Negative
};

// horrible unscoped enum because yylval has to be an int
enum Mulop : int
{
    Multiply,
    Divide,
    Div,
    Modulo,
    And
};

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
  void print();

private:
  std::vector<Symbol> symbols;
  int tempCounter {0};
};

extern SymbolTable symtable;

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