#include "symbol.hpp"

int SymbolTable::lookup(std::string id)
{
  auto it = std::find_if(std::begin(symbols), std::end(symbols),
                         [&](Symbol &elem) { return elem.id == id
                        //  && elem.symbolType == SymbolType::Variable
                         && !elem.global; });
  if (it == std::end(symbols))
    it = std::find_if(std::begin(symbols), std::end(symbols),
                      [&](Symbol &elem) { return elem.id == id
                      // && elem.symbolType == SymbolType::Variable
                      && elem.global; });
  if(it == std::end(symbols)) return -1;
  return std::distance(std::begin(symbols), it);
}

int SymbolTable::lookupFunction(std::string id)
{
  auto it = std::find_if(std::begin(symbols), std::end(symbols),
                         [&](Symbol &elem) { return elem.id == id
                         && elem.symbolType == SymbolType::Function
                         && !elem.global; });
  if(it == std::end(symbols)) return -1;
  return std::distance(std::begin(symbols), it);
}

int SymbolTable::insert(Symbol symbol)
{
  if(symbol.symbolType == SymbolType::Variable){
    auto it = std::find_if(std::rbegin(symbols), std::rend(symbols),
                          [&](Symbol &elem) { return elem.symbolType == SymbolType::Variable 
                          && elem.global == symbol.global; });
    int size = symbol.type == Type::Real ? 8 : 4;
    symbol.address = (*it).address + size;
  }
  symbols.push_back(symbol);
  return symbols.size() - 1;
}

void SymbolTable::cleanLocal()
{
  std::remove_if(std::begin(symbols), std::end(symbols),
                 [](Symbol &elem) { return !elem.global; });
}

Symbol SymbolTable::get(int i)
{
  return symbols.at(i);
}