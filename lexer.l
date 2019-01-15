%option noyywrap

%{
#include "parser.hpp"
#include "symbol.hpp"
#include <cstdlib> // atof()
%}

comment             \{[^\{]*\}
whitespace          [ \n\t\r]+

or                  or
program             program
var                 var
integer             integer
real                real
function            function
procedure           procedure
begin               begin
end                 end
if                  if
then                then
else                else
while               while
do                  do
not                 not
array               array
of                  of

relop               <>|<=|>=|>|=|<
sign                \+|-
mulop               \*|\/|(div)|(mod)|(and)
assignop            :=

digit               [0-9]
digits              {digit}+
optional_fraction   (\.{digits})?
optional_exponent   ([Ee]([+-]?){digits})?
num                 {digits}{optional_fraction}{optional_exponent}

letter              [a-zA-Z]
id                  {letter}({letter}|{digit})*

default             [\(\)\,\;\:\.\[\]]{1}

%%

{comment}           {/*NOP*/}
{whitespace}        {/*NOP*/}
{or}                {return OR;}
{program}           {return PROGRAM;}
{var}               {return VAR;}
{integer}           {return INTEGER;}
{real}              {return REAL;}
{function}          {return FUNCTION;}
{procedure}         {return PROCEDURE;}
{begin}             {return BEGIN_T;}
{end}               {return END;}
{if}                {return IF;}
{then}              {return THEN;}
{else}              {return ELSE;}
{while}             {return WHILE;}
{do}                {return DO;}
{not}               {return NOT;}
{array}             {return ARRAY;}
{of}                {return OF;}
{relop}             {
                    std::string val = std::string(yytext);
                    if(val == "<>") yylval = Relop::NotEqual;
                    if(val == "<=") yylval = Relop::LesserEqual;
                    if(val == ">=") yylval = Relop::GreaterEqual;
                    if(val == ">") yylval = Relop::Greater;
                    if(val == "=") yylval = Relop::Equal;
                    if(val == "<") yylval = Relop::Lesser;
                    return RELOP;
                    }
{sign}              {
                    std::string val = std::string(yytext);
                    if(val== "+") yylval = Sign::Positive;
                    if(val== "-") yylval = Sign::Negative;
                    return SIGN;
                    }
{mulop}             {
                    std::string val = std::string(yytext);
                    if(val == "*") yylval = Mulop::Multiply;
                    if(val == "/") yylval = Mulop::Divide;
                    if(val == "div") yylval = Mulop::Div;
                    if(val == "mod") yylval = Mulop::Modulo;
                    if(val == "and") yylval = Mulop::And;
                    return MULOP;
                    }
{assignop}          {return ASSIGNOP;}
{num}               {
                    yylval = symtable.lookup(std::string(yytext));
                    if(yylval < 0) {
                      Symbol sym;
                      sym.value = atof(yytext);
                      auto text = std::string(yytext);
                      if(text.find('.') != std::string::npos || text.find('e') != std::string::npos)
                        sym.type = Type::Real;
                      else
                        sym.type = Type::Integer;
                      sym.token = NUM;
                      yylval = symtable.insert(sym);
                    }
                    return NUM;
                    }
{id}                {
                    yylval = symtable.lookup(std::string(yytext));
                    if(yylval < 0) { 
                      Symbol sym;
                      sym.id = std::string(yytext);
                      sym.token = ID;
                      yylval = symtable.insert(sym);
                    }
                    return ID;
                    }
{default}           {return *yytext;}
%%
