#pragma once

#include <string>
#include <vector>
#include <algorithm>
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
    Integer,
    IntegerReference,
    Real,
    RealReference,
    Void // for procedures
};

enum class SymbolType : int
{
    Variable,
    Function,
    Label,
    Constant
};

struct Symbol {
    std::string id;
    Type type;
    SymbolType symbolType;
    bool global;
    int address;
    double value;
};

class SymbolTable {
public:
  int lookup(std::string id);
  int lookupFunction(std::string id);
  int insert(Symbol symbol);
  void cleanLocal();
  Symbol get(int i);

private:
  std::vector<Symbol> symbols;
};

extern SymbolTable symtable;
