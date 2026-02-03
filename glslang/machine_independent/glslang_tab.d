module glslang.machine_independent.glslang_tab;

alias symbol_number_t = int;
alias rule_number_t = int;

enum symbol_class_t {
  unknown_sym,
  percent_type_sym,
  token_sym,
  nonterm_sym
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
  symbol_t sym;
  symbol_list_t next;

  this(symbol_t sym) {
    this.sym = sym;
  }
}

void symbols_new() {
  acceptsymbol = symbol_get("$accept");
  acceptsymbol.content.class_ = symbol_class_t.nonterm_sym;
  acceptsymbol.content.number = nnonterms++;

  errtoken = symbol_get("YYerror");
  errtoken.content.class_ = symbol_class_t.token_sym;
  errtoken.content.number = ntokens++;

  symbol_t errtoken_alias = symbol_get("error");
  errtoken_alias.content.class_ = symbol_class_t.token_sym;
  errtoken.make_alias(errtoken_alias);

  undeftoken = symbol_get("YYUNDEF");
  undeftoken.content.class_ = symbol_class_t.token_sym;
  undeftoken.content.number = ntokens++;

  symbol_t undeftoken_alias = symbol_get("$undefined");
  undeftoken_alias.content.class_ = symbol_class_t.token_sym;
  undeftoken.make_alias(undeftoken_alias);
}

symbol_t symbol_get(string key) {
  return symbol_table.require(key, new symbol_t(key));
}

symbol_t dummy_symbol_get() {
  import std.format;
  static int dummy_count = 0;

  symbol_t sym = symbol_get(format("$@%d", ++dummy_count));
  sym.content.class_ = symbol_class_t.nonterm_sym;
  return sym;
}

symbol_list_t grammar_symbol_append(symbol_t sym) {
  symbol_list_t p = new symbol_list_t(sym);

  if (grammar_end)
    grammar_end.next = p;
  else
    grammar = p;

  grammar_end = p;

  if (sym)
    ++nritems;

  return p;
}

void grammar_current_rule_begin(symbol_t lhs) {
  ++nrules;
  previous_rule_end = grammar_end;

  current_rule = grammar_symbol_append(lhs);

  if (lhs.content.class_ == symbol_class_t.unknown_sym ||
    lhs.content.class_ == symbol_class_t.percent_type_sym) {
    lhs.content.class_ = symbol_class_t.nonterm_sym;
  }
}

void grammar_current_rule_symbol_append(symbol_t sym) {
  grammar_symbol_append(sym);
}

void grammar_current_rule_end() {
  grammar_symbol_append(null);
}

void grammar_midrule_action() {
  symbol_list_t midrule = new symbol_list_t(dummy_symbol_get());
  ++nrules;
  ++nritems;
  //
}

symbol_t acceptsymbol;
symbol_t errtoken;
symbol_t undeftoken;

symbol_list_t grammar;
symbol_list_t grammar_end;

symbol_list_t current_rule;
symbol_list_t previous_rule_end;

int nnonterms = 0;
int ntokens = 1;

int nritems = 0;

rule_number_t nrules = 0;

symbol_t[string] symbol_table;

static this() {
  symbols_new();

  grammar_current_rule_begin(symbol_get("variable_identifier"));
  grammar_current_rule_symbol_append(symbol_get("IDENTIFIER"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("primary_expression"));
  grammar_current_rule_symbol_append(symbol_get("variable_identifier"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("primary_expression"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_PAREN"));
  grammar_current_rule_symbol_append(symbol_get("expression"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_PAREN"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("primary_expression"));
  grammar_current_rule_symbol_append(symbol_get("FLOATCONSTANT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("primary_expression"));
  grammar_current_rule_symbol_append(symbol_get("INTCONSTANT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("primary_expression"));
  grammar_current_rule_symbol_append(symbol_get("UINTCONSTANT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("primary_expression"));
  grammar_current_rule_symbol_append(symbol_get("BOOLCONSTANT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("primary_expression"));
  grammar_current_rule_symbol_append(symbol_get("STRING_LITERAL"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("primary_expression"));
  grammar_current_rule_symbol_append(symbol_get("INT32CONSTANT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("primary_expression"));
  grammar_current_rule_symbol_append(symbol_get("UINT32CONSTANT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("primary_expression"));
  grammar_current_rule_symbol_append(symbol_get("INT64CONSTANT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("primary_expression"));
  grammar_current_rule_symbol_append(symbol_get("UINT64CONSTANT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("primary_expression"));
  grammar_current_rule_symbol_append(symbol_get("INT16CONSTANT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("primary_expression"));
  grammar_current_rule_symbol_append(symbol_get("UINT16CONSTANT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("primary_expression"));
  grammar_current_rule_symbol_append(symbol_get("DOUBLECONSTANT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("primary_expression"));
  grammar_current_rule_symbol_append(symbol_get("FLOAT16CONSTANT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("postfix_expression"));
  grammar_current_rule_symbol_append(symbol_get("primary_expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("postfix_expression"));
  grammar_current_rule_symbol_append(symbol_get("postfix_expression"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_BRACKET"));
  grammar_current_rule_symbol_append(symbol_get("integer_expression"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_BRACKET"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("postfix_expression"));
  grammar_current_rule_symbol_append(symbol_get("function_call"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("postfix_expression"));
  grammar_current_rule_symbol_append(symbol_get("postfix_expression"));
  grammar_current_rule_symbol_append(symbol_get("DOT"));
  grammar_current_rule_symbol_append(symbol_get("IDENTIFIER"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("postfix_expression"));
  grammar_current_rule_symbol_append(symbol_get("postfix_expression"));
  grammar_current_rule_symbol_append(symbol_get("INC_OP"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("postfix_expression"));
  grammar_current_rule_symbol_append(symbol_get("postfix_expression"));
  grammar_current_rule_symbol_append(symbol_get("DEC_OP"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("integer_expression"));
  grammar_current_rule_symbol_append(symbol_get("expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("function_call"));
  grammar_current_rule_symbol_append(symbol_get("function_call_or_method"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("function_call_or_method"));
  grammar_current_rule_symbol_append(symbol_get("function_call_generic"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("function_call_generic"));
  grammar_current_rule_symbol_append(symbol_get("function_call_header_with_parameters"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_PAREN"));
  grammar_current_rule_end();
 
  grammar_current_rule_begin(symbol_get("function_call_generic"));
  grammar_current_rule_symbol_append(symbol_get("function_call_header_no_parameters"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_PAREN"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("function_call_header_no_parameters"));
  grammar_current_rule_symbol_append(symbol_get("function_call_header"));
  grammar_current_rule_symbol_append(symbol_get("VOID"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("function_call_header_no_parameters"));
  grammar_current_rule_symbol_append(symbol_get("function_call_header"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("function_call_header_with_parameters"));
  grammar_current_rule_symbol_append(symbol_get("function_call_header"));
  grammar_current_rule_symbol_append(symbol_get("assignment_expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("function_call_header_with_parameters"));
  grammar_current_rule_symbol_append(symbol_get("function_call_header_with_parameters"));
  grammar_current_rule_symbol_append(symbol_get("COMMA"));
  grammar_current_rule_symbol_append(symbol_get("assignment_expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("function_call_header"));
  grammar_current_rule_symbol_append(symbol_get("function_identifier"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_BRACKET"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("function_identifier"));
  grammar_current_rule_symbol_append(symbol_get("type_specifier"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("function_identifier"));
  grammar_current_rule_symbol_append(symbol_get("postfix_expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("function_identifier"));
  grammar_current_rule_symbol_append(symbol_get("non_uniform_qualifier"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("unary_expression"));
  grammar_current_rule_symbol_append(symbol_get("postfix_expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("unary_expression"));
  grammar_current_rule_symbol_append(symbol_get("INC_OP"));
  grammar_current_rule_symbol_append(symbol_get("unary_expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("unary_expression"));
  grammar_current_rule_symbol_append(symbol_get("DEC_OP"));
  grammar_current_rule_symbol_append(symbol_get("unary_expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("unary_expression"));
  grammar_current_rule_symbol_append(symbol_get("unary_expression"));
  grammar_current_rule_symbol_append(symbol_get("unary_expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("unary_operator"));
  grammar_current_rule_symbol_append(symbol_get("PLUS"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("unary_operator"));
  grammar_current_rule_symbol_append(symbol_get("DASH"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("unary_operator"));
  grammar_current_rule_symbol_append(symbol_get("BANG"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("unary_operator"));
  grammar_current_rule_symbol_append(symbol_get("TILDE"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("multiplicative_expression"));
  grammar_current_rule_symbol_append(symbol_get("unary_expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("multiplicative_expression"));
  grammar_current_rule_symbol_append(symbol_get("multiplicative_expression"));
  grammar_current_rule_symbol_append(symbol_get("STAR"));
  grammar_current_rule_symbol_append(symbol_get("unary_expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("multiplicative_expression"));
  grammar_current_rule_symbol_append(symbol_get("multiplicative_expression"));
  grammar_current_rule_symbol_append(symbol_get("SLASH"));
  grammar_current_rule_symbol_append(symbol_get("unary_expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("multiplicative_expression"));
  grammar_current_rule_symbol_append(symbol_get("multiplicative_expression"));
  grammar_current_rule_symbol_append(symbol_get("PERCENT"));
  grammar_current_rule_symbol_append(symbol_get("unary_expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("additive_expression"));
  grammar_current_rule_symbol_append(symbol_get("multiplicative_expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("additive_expression"));
  grammar_current_rule_symbol_append(symbol_get("additive_expression"));
  grammar_current_rule_symbol_append(symbol_get("PLUS"));
  grammar_current_rule_symbol_append(symbol_get("multiplicative_expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("additive_expression"));
  grammar_current_rule_symbol_append(symbol_get("additive_expression"));
  grammar_current_rule_symbol_append(symbol_get("DASH"));
  grammar_current_rule_symbol_append(symbol_get("multiplicative_expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("shift_expression"));
  grammar_current_rule_symbol_append(symbol_get("additive_expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("shift_expression"));
  grammar_current_rule_symbol_append(symbol_get("shift_expression"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_OP"));
  grammar_current_rule_symbol_append(symbol_get("additive_expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("shift_expression"));
  grammar_current_rule_symbol_append(symbol_get("shift_expression"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_OP"));
  grammar_current_rule_symbol_append(symbol_get("additive_expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("relational_expression"));
  grammar_current_rule_symbol_append(symbol_get("shift_expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("relational_expression"));
  grammar_current_rule_symbol_append(symbol_get("relational_expression"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_ANGLE"));
  grammar_current_rule_symbol_append(symbol_get("shift_expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("relational_expression"));
  grammar_current_rule_symbol_append(symbol_get("relational_expression"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_ANGLE"));
  grammar_current_rule_symbol_append(symbol_get("shift_expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("relational_expression"));
  grammar_current_rule_symbol_append(symbol_get("relational_expression"));
  grammar_current_rule_symbol_append(symbol_get("LE_OP"));
  grammar_current_rule_symbol_append(symbol_get("shift_expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("relational_expression"));
  grammar_current_rule_symbol_append(symbol_get("relational_expression"));
  grammar_current_rule_symbol_append(symbol_get("GE_OP"));
  grammar_current_rule_symbol_append(symbol_get("shift_expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("equality_expression"));
  grammar_current_rule_symbol_append(symbol_get("relational_expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("equality_expression"));
  grammar_current_rule_symbol_append(symbol_get("equality_expression"));
  grammar_current_rule_symbol_append(symbol_get("EQ_OP"));
  grammar_current_rule_symbol_append(symbol_get("relational_expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("equality_expression"));
  grammar_current_rule_symbol_append(symbol_get("equality_expression"));
  grammar_current_rule_symbol_append(symbol_get("NE_OP"));
  grammar_current_rule_symbol_append(symbol_get("relational_expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("and_expression"));
  grammar_current_rule_symbol_append(symbol_get("equality_expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("and_expression"));
  grammar_current_rule_symbol_append(symbol_get("and_expression"));
  grammar_current_rule_symbol_append(symbol_get("AMPERSAND"));
  grammar_current_rule_symbol_append(symbol_get("equality_expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("exclusive_or_expression"));
  grammar_current_rule_symbol_append(symbol_get("and_expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("exclusive_or_expression"));
  grammar_current_rule_symbol_append(symbol_get("exclusive_or_expression"));
  grammar_current_rule_symbol_append(symbol_get("CARET"));
  grammar_current_rule_symbol_append(symbol_get("and_expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("inclusive_or_expression"));
  grammar_current_rule_symbol_append(symbol_get("exclusive_or_expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("inclusive_or_expression"));
  grammar_current_rule_symbol_append(symbol_get("inclusive_or_expression"));
  grammar_current_rule_symbol_append(symbol_get("VERTICAL_BAR"));
  grammar_current_rule_symbol_append(symbol_get("exclusive_or_expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("logical_and_expression"));
  grammar_current_rule_symbol_append(symbol_get("inclusive_or_expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("logical_and_expression"));
  grammar_current_rule_symbol_append(symbol_get("logical_and_expression"));
  grammar_current_rule_symbol_append(symbol_get("AND_OP"));
  grammar_current_rule_symbol_append(symbol_get("inclusive_or_expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("logical_xor_expression"));
  grammar_current_rule_symbol_append(symbol_get("logical_and_expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("logical_xor_expression"));
  grammar_current_rule_symbol_append(symbol_get("logical_xor_expression"));
  grammar_current_rule_symbol_append(symbol_get("XOR_OP"));
  grammar_current_rule_symbol_append(symbol_get("logical_and_expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("logical_or_expression"));
  grammar_current_rule_symbol_append(symbol_get("logical_xor_expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("logical_or_expression"));
  grammar_current_rule_symbol_append(symbol_get("logical_or_expression"));
  grammar_current_rule_symbol_append(symbol_get("OR_OP"));
  grammar_current_rule_symbol_append(symbol_get("logical_xor_expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("conditional_expression"));
  grammar_current_rule_symbol_append(symbol_get("logical_or_expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("conditional_expression"));
  grammar_current_rule_symbol_append(symbol_get("logical_or_expression"));
  grammar_current_rule_symbol_append(symbol_get("QUESTION"));
  grammar_current_rule_symbol_append(symbol_get("expression"));
  grammar_current_rule_symbol_append(symbol_get("COLON"));
  grammar_current_rule_symbol_append(symbol_get("assignment_expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("assignment_expression"));
  grammar_current_rule_symbol_append(symbol_get("conditional_expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("assignment_expression"));
  grammar_current_rule_symbol_append(symbol_get("unary_expression"));
  grammar_current_rule_symbol_append(symbol_get("assignment_operator"));
  grammar_current_rule_symbol_append(symbol_get("assignment_expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("assignment_operator"));
  grammar_current_rule_symbol_append(symbol_get("EQUAL"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("assignment_operator"));
  grammar_current_rule_symbol_append(symbol_get("MUL_ASSIGN"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("assignment_operator"));
  grammar_current_rule_symbol_append(symbol_get("DIV_ASSIGN"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("assignment_operator"));
  grammar_current_rule_symbol_append(symbol_get("MOD_ASSIGN"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("assignment_operator"));
  grammar_current_rule_symbol_append(symbol_get("ADD_ASSIGN"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("assignment_operator"));
  grammar_current_rule_symbol_append(symbol_get("SUB_ASSIGN"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("assignment_operator"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_ASSIGN"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("assignment_operator"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_ASSIGN"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("assignment_operator"));
  grammar_current_rule_symbol_append(symbol_get("AND_ASSIGN"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("assignment_operator"));
  grammar_current_rule_symbol_append(symbol_get("XOR_ASSIGN"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("assignment_operator"));
  grammar_current_rule_symbol_append(symbol_get("OR_ASSIGN"));
  grammar_current_rule_end();

  

}
