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

  this(immutable symbol_t s, sym_content_arg_t sym_content_arg) immutable {
    symbol = s;

    class_ = sym_content_arg.class_;
    number = sym_content_arg.number;
  }
}

class symbol_t {
  string tag;
  sym_content_t content;

  this(string tag) {
    this.tag = tag;
    this.content = new sym_content_t(this);
  }

  this(string tag, sym_content_arg_t sym_content_arg) immutable {
    this.tag = tag;
    this.content = new immutable sym_content_t(this, sym_content_arg);
  }
}

class symbol_list_t {
  
}

class reader_t {
  immutable symbol_t acceptsymbol;

  int nnterms = 0;

  this() {
    acceptsymbol = new immutable symbol_t(
      "$sccept",
      sym_content_arg_t(
        class_: symbol_class_t.nterm_sym,
        number: nnterms++
      )
    );
  }
}
