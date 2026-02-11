module bison.symtab;
import bison;

enum symbol_class_t {
  unknown_sym,
  percent_type_sym,
  token_sym,
  nterm_sym
}

alias symbol_number_t = int;

enum symbol_number_t NUMBER_UNDEFINED = -1;

symbol_t acceptsymbol;
symbol_t errtoken;
symbol_t undeftoken;
symbol_t eoftoken;

symbol_t[string] symbol_table;
symbol_t[] symbols_sorted;

class symbol_t {
  string tag;
  int order_of_appearance;

  symbol_t alias_;
  bool is_alias;

  sym_content_t content;

  this(string tag) {
    this.tag = tag;
    this.content = new sym_content_t(this);
  }

  void make_alias(symbol_t str) {
    str.content = this.content;
    str.content.symbol = str;
    str.is_alias = true;
    str.alias_ = this;
    this.alias_ = str;
  }
}

class sym_content_t {
  symbol_t symbol;
  symbol_class_t class_;
  symbol_number_t number;

  this(symbol_t s) {
    symbol = s;

    class_ = symbol_class_t.unknown_sym;
    number = NUMBER_UNDEFINED;
  }
}

symbol_t declare_sym(symbol_t sym, symbol_class_t class_) {
  static int order_of_appearance = 0;
  sym.content.class_ = class_;
  sym.order_of_appearance = ++order_of_appearance;
  return sym;
}

symbol_t symbol_get(string key) {
  return symbol_table.require(key, new symbol_t(key));
}

symbol_t dummy_symbol_get() {
  import std.format;

  static int dummy_count = 0;
  return declare_sym(
    symbol_get(format("$@%d", ++dummy_count)),
    symbol_class_t.nterm_sym
  );
}

