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

  this(string tag) {
    this.tag = tag;
    this.content = new sym_content_t(this);
  }
}

class symbol_list_t {
  
}

class reader_t {
  symbol_t acceptsymbol;
  symbol_t errtoken;

  int nnterms = 0;
  int ntokens = 1;

  this() {
    acceptsymbol = new symbol_t("$accept");
    acceptsymbol.content.class_ = symbol_class_t.nterm_sym;
    acceptsymbol.content.number = nnterms++;

    errtoken = new symbol_t("YYerror");
    errtoken.content.class_ = symbol_class_t.token_sym;
    errtoken.content.number = ntokens++;
  }
}
