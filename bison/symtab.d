module bison.symtab;
import bison;

enum symbol_class_ {
  unknown_sym,
  percent_type_sym,
  token_sym,
  nterm_sym
}

alias symbol_number = int;

enum symbol_number NUMBER_UNDEFINED = -1;

symbol acceptsymbol;
symbol errtoken;
symbol undeftoken;
symbol eoftoken;

symbol[string] symbol_table;
symbol[] symbols_sorted;

class symbol {
  string tag;
  int order_of_appearance;

  symbol alias_;
  bool is_alias;

  sym_content content;

  this(string tag) {
    this.tag = tag;
    this.content = new sym_content(this);
  }

  void make_alias(symbol str) {
    str.content = this.content;
    str.content.symbol_ = str;
    str.is_alias = true;
    str.alias_ = this;
    this.alias_ = str;
  }
}

class sym_content {
  symbol symbol_;
  symbol_class_ class_;
  symbol_number number;

  this(symbol s) {
    symbol_ = s;

    class_ = symbol_class_.unknown_sym;
    number = NUMBER_UNDEFINED;
  }
}

symbol declare_sym(symbol sym, symbol_class_ class_) {
  static int order_of_appearance = 0;
  sym.content.class_ = class_;
  sym.order_of_appearance = ++order_of_appearance;
  return sym;
}

symbol symbol_get(string key) {
  return symbol_table.require(key, new symbol(key));
}

symbol dummy_symbol_get() {
  import std.format;

  static int dummy_count = 0;
  return declare_sym(
    symbol_get(format("$@%d", ++dummy_count)),
    symbol_class_.nterm_sym
  );
}

