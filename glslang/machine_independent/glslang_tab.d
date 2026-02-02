module glslang.machine_independent.glslang_tab;

alias symbol_number_t = int;

enum symbol_class_t {
  unknown_sym,
  pct_type_sym,
  token_sym,
  nterm_sym
}

enum symbol_number_t NUMBER_UNDEFINED = -1;

struct sym_content_arg_t {
  symbol_class_t class_;
  symbol_number_t number;
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

class symbol_t {
  string tag;
  sym_content_t content;
  symbol_t alias_;
  bool is_alias;

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

class symbol_list_t {
  
}

class bison_t {
  symbol_t acceptsymbol;
  symbol_t errtoken;
  symbol_t undeftoken;
  
  int nnterms = 0;
  int ntokens = 1;

  symbol_t[string] symbol_table;

  this() {
    symbols_new();
  }

  void symbols_new() {
    acceptsymbol = this.symbol_get("$accept");
    acceptsymbol.content.class_ = symbol_class_t.nterm_sym;
    acceptsymbol.content.number = nnterms++;

    errtoken = this.symbol_get("YYerror");
    errtoken.content.class_ = symbol_class_t.token_sym;
    errtoken.content.number = ntokens++;

    symbol_t errtoken_alias = this.symbol_get("error");
    errtoken_alias.content.class_ = symbol_class_t.token_sym;
    errtoken.make_alias(errtoken_alias);

    undeftoken = this.symbol_get("YYUNDEF");
    undeftoken.content.class_ = symbol_class_t.token_sym;
    undeftoken.content.number = ntokens++;

    symbol_t undeftoken_alias = this.symbol_get("$undefined");
    undeftoken_alias.content.class_ = symbol_class_t.token_sym;
    undeftoken.make_alias(undeftoken_alias);
  }

  symbol_t symbol_get(string key) =>
    symbol_table.require(key, new symbol_t(key));
}

