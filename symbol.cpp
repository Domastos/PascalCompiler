#include "symbol.hpp"

int SymbolTable::lookup(std::string id)
{
  auto it = std::find_if(std::begin(symbols), std::end(symbols),
                         [&](Symbol &elem) {
                           return elem.id == id 
                           && (elem.token == PROCEDURE || elem.token == FUNCTION);
                         });
  if (it == std::end(symbols))
    it = std::find_if(std::begin(symbols), std::end(symbols),
                 [&](Symbol &elem) {
                    return elem.id == id
                    && !elem.global; });
  // symbol not in local scope, switch to global lookup
  if (it == std::end(symbols))
    it = std::find_if(std::begin(symbols), std::end(symbols),
                      [&](Symbol &elem) {
                        return elem.id == id
                        && elem.global; });
  if (it == std::end(symbols))
    return -1;
  return std::distance(std::begin(symbols), it);
}

int SymbolTable::lookupFunction(std::string id)
{
  auto it = std::find_if(std::begin(symbols), std::end(symbols),
                         [&](Symbol &elem) { return elem.id == id
                         && (elem.token == PROCEDURE || elem.token == FUNCTION);});
  if(it == std::end(symbols)) return -1;
  return std::distance(std::begin(symbols), it);
}

int SymbolTable::insert(Symbol symbol)
{
  symbols.push_back(symbol);
  return symbols.size() - 1;
}

void SymbolTable::cleanLocal()
{
  symbols.erase(std::remove_if(std::begin(symbols), std::end(symbols),
                 [](Symbol &elem) { return !elem.global; }),
                 std::end(symbols));
  tempCounter = 0;
}

Symbol& SymbolTable::at(int i)
{
  return symbols.at(i);
}

int SymbolTable::getSize(Symbol& sym) {
  if(sym.reference || sym.type == Type::Integer)
    return 4;
  else if (sym.type == Type::Real)
    return 8;
  else
    return 0;
}

int SymbolTable::calculateAddress(bool global, int pos) {
  if (global)
  {
    auto top = std::max_element(std::begin(symbols), std::end(symbols), [](auto &a,auto &b) {
      if (!a.global || a.type == Type::Undefined || a.token == FUNCTION)
        return true;
      return a.address < b.address;
    });
    if(std::distance(std::begin(symbols), top) == pos)
      return 0;
    return (*top).address + getSize(*top);
  }
  else {
    auto top = std::min_element(std::begin(symbols), std::end(symbols), [](auto &a,auto &b) {
    if (b.global || b.type == Type::Undefined  || b.token == FUNCTION)
      return true;
    return a.address < b.address;
  });
    if(std::distance(std::begin(symbols), top) == pos)
      return -1 * getSize(symbols.at(pos));
    return (*top).address - getSize(symbols.at(pos));
  }
}

int SymbolTable::insertTemp(bool global, Type type) {
  Symbol sym;
  sym.id = "t" + std::to_string(tempCounter++);
  sym.token = ID;
  sym.global = global;
  sym.type = type;
  int pos = this->insert(sym);
  symbols.at(pos).address = calculateAddress(global, pos);
  return pos;
}

void SymbolTable::print() {
  std::cerr << "\n";
  std::cerr
      << std::setw(8)
      << "pos"
      << "|"
      << std::setw(14)
      << "ID"
      << "|"
      << std::setw(8)
      << "TYPE"
      << "|"
      << std::setw(6)
      << "TOK"
      << "|"
      << std::setw(6)
      << "REF"
      << "|"
      << std::setw(6)
      << "GLOBAL"
      << "|"
      << std::setw(8)
      << "ADDR"
      << "|"
      << std::setw(12)
      << "VAL"
      << "|"
      << std::endl;
  for (size_t i = 0; i < symbols.size(); ++i) {
    std::cerr 
    << std::setw(8)
    << i 
    << "|"
    << std::setw(14)
    <<symbols.at(i).id
    << "|"
    << std::setw(8)
    <<static_cast<int>(symbols.at(i).type)
    << "|"
    << std::setw(6)
    <<static_cast<int>(symbols.at(i).token)
    << "|"
    << std::setw(6)
    <<static_cast<int>(symbols.at(i).reference)
    << "|"
    << std::setw(6)
    <<symbols.at(i).global
    << "|"
    << std::setw(8)
    <<symbols.at(i).address
    << "|"
    << std::setw(12)
    <<symbols.at(i).value
    << "|"
    <<std::endl;
  }
}