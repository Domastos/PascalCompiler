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
  void print();

private:
  std::vector<Symbol> symbols;
};

extern SymbolTable symtable;
