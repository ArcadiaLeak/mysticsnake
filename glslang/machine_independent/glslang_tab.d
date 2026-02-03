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

  grammar_current_rule_begin(symbol_get("expression"));
  grammar_current_rule_symbol_append(symbol_get("assignment_expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("expression"));
  grammar_current_rule_symbol_append(symbol_get("expression"));
  grammar_current_rule_symbol_append(symbol_get("COMMA"));
  grammar_current_rule_symbol_append(symbol_get("assignment_expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("constant_expression"));
  grammar_current_rule_symbol_append(symbol_get("conditional_expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("declaration"));
  grammar_current_rule_symbol_append(symbol_get("function_prototype"));
  grammar_current_rule_symbol_append(symbol_get("SEMICOLON"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("declaration"));
  grammar_current_rule_symbol_append(symbol_get("spirv_instruction_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("function_prototype"));
  grammar_current_rule_symbol_append(symbol_get("SEMICOLON"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("declaration"));
  grammar_current_rule_symbol_append(symbol_get("spirv_execution_mode_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("SEMICOLON"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("declaration"));
  grammar_current_rule_symbol_append(symbol_get("init_declarator_list"));
  grammar_current_rule_symbol_append(symbol_get("SEMICOLON"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("declaration"));
  grammar_current_rule_symbol_append(symbol_get("PRECISION"));
  grammar_current_rule_symbol_append(symbol_get("precision_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("type_specifier"));
  grammar_current_rule_symbol_append(symbol_get("SEMICOLON"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("declaration"));
  grammar_current_rule_symbol_append(symbol_get("block_structure"));
  grammar_current_rule_symbol_append(symbol_get("SEMICOLON"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("declaration"));
  grammar_current_rule_symbol_append(symbol_get("block_structure"));
  grammar_current_rule_symbol_append(symbol_get("IDENTIFIER"));
  grammar_current_rule_symbol_append(symbol_get("SEMICOLON"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("declaration"));
  grammar_current_rule_symbol_append(symbol_get("block_structure"));
  grammar_current_rule_symbol_append(symbol_get("IDENTIFIER"));
  grammar_current_rule_symbol_append(symbol_get("array_specifier"));
  grammar_current_rule_symbol_append(symbol_get("SEMICOLON"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("declaration"));
  grammar_current_rule_symbol_append(symbol_get("type_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("SEMICOLON"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("declaration"));
  grammar_current_rule_symbol_append(symbol_get("type_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("identifier_list"));
  grammar_current_rule_symbol_append(symbol_get("SEMICOLON"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("block_structure"));
  grammar_current_rule_symbol_append(symbol_get("type_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("IDENTIFIER"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_BRACE"));
  grammar_current_rule_symbol_append(symbol_get("struct_declaration_list"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_BRACE"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("identifier_list"));
  grammar_current_rule_symbol_append(symbol_get("IDENTIFIER"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("identifier_list"));
  grammar_current_rule_symbol_append(symbol_get("identifier_list"));
  grammar_current_rule_symbol_append(symbol_get("COMMA"));
  grammar_current_rule_symbol_append(symbol_get("IDENTIFIER"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("function_prototype"));
  grammar_current_rule_symbol_append(symbol_get("function_declarator"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_PAREN"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("function_prototype"));
  grammar_current_rule_symbol_append(symbol_get("function_declarator"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_PAREN"));
  grammar_current_rule_symbol_append(symbol_get("attribute"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("function_prototype"));
  grammar_current_rule_symbol_append(symbol_get("attribute"));
  grammar_current_rule_symbol_append(symbol_get("function_declarator"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_PAREN"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("function_prototype"));
  grammar_current_rule_symbol_append(symbol_get("attribute"));
  grammar_current_rule_symbol_append(symbol_get("function_declarator"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_PAREN"));
  grammar_current_rule_symbol_append(symbol_get("attribute"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("function_declarator"));
  grammar_current_rule_symbol_append(symbol_get("function_header"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("function_declarator"));
  grammar_current_rule_symbol_append(symbol_get("function_header_with_parameters"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("function_header_with_parameters"));
  grammar_current_rule_symbol_append(symbol_get("function_header"));
  grammar_current_rule_symbol_append(symbol_get("parameter_declaration"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("function_header_with_parameters"));
  grammar_current_rule_symbol_append(symbol_get("function_header_with_parameters"));
  grammar_current_rule_symbol_append(symbol_get("COMMA"));
  grammar_current_rule_symbol_append(symbol_get("parameter_declaration"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("function_header_with_parameters"));
  grammar_current_rule_symbol_append(symbol_get("function_header_with_parameters"));
  grammar_current_rule_symbol_append(symbol_get("COMMA"));
  grammar_current_rule_symbol_append(symbol_get("DOT"));
  grammar_current_rule_symbol_append(symbol_get("DOT"));
  grammar_current_rule_symbol_append(symbol_get("DOT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("function_header"));
  grammar_current_rule_symbol_append(symbol_get("fully_specified_type"));
  grammar_current_rule_symbol_append(symbol_get("IDENTIFIER"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_PAREN"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("parameter_declarator"));
  grammar_current_rule_symbol_append(symbol_get("type_specifier"));
  grammar_current_rule_symbol_append(symbol_get("IDENTIFIER"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("parameter_declarator"));
  grammar_current_rule_symbol_append(symbol_get("type_specifier"));
  grammar_current_rule_symbol_append(symbol_get("IDENTIFIER"));
  grammar_current_rule_symbol_append(symbol_get("array_specifier"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("parameter_declarator"));
  grammar_current_rule_symbol_append(symbol_get("type_specifier"));
  grammar_current_rule_symbol_append(symbol_get("IDENTIFIER"));
  grammar_current_rule_symbol_append(symbol_get("EQUAL"));
  grammar_current_rule_symbol_append(symbol_get("initializer"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("parameter_declaration"));
  grammar_current_rule_symbol_append(symbol_get("type_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("parameter_declarator"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("parameter_declaration"));
  grammar_current_rule_symbol_append(symbol_get("parameter_declarator"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("parameter_declaration"));
  grammar_current_rule_symbol_append(symbol_get("type_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("parameter_type_specifier"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("parameter_declaration"));
  grammar_current_rule_symbol_append(symbol_get("parameter_type_specifier"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("parameter_type_specifier"));
  grammar_current_rule_symbol_append(symbol_get("type_specifier"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("init_declarator_list"));
  grammar_current_rule_symbol_append(symbol_get("single_declaration"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("init_declarator_list"));
  grammar_current_rule_symbol_append(symbol_get("init_declarator_list"));
  grammar_current_rule_symbol_append(symbol_get("COMMA"));
  grammar_current_rule_symbol_append(symbol_get("IDENTIFIER"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("init_declarator_list"));
  grammar_current_rule_symbol_append(symbol_get("init_declarator_list"));
  grammar_current_rule_symbol_append(symbol_get("COMMA"));
  grammar_current_rule_symbol_append(symbol_get("IDENTIFIER"));
  grammar_current_rule_symbol_append(symbol_get("array_specifier"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("init_declarator_list"));
  grammar_current_rule_symbol_append(symbol_get("init_declarator_list"));
  grammar_current_rule_symbol_append(symbol_get("COMMA"));
  grammar_current_rule_symbol_append(symbol_get("IDENTIFIER"));
  grammar_current_rule_symbol_append(symbol_get("array_specifier"));
  grammar_current_rule_symbol_append(symbol_get("EQUAL"));
  grammar_current_rule_symbol_append(symbol_get("initializer"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("init_declarator_list"));
  grammar_current_rule_symbol_append(symbol_get("init_declarator_list"));
  grammar_current_rule_symbol_append(symbol_get("COMMA"));
  grammar_current_rule_symbol_append(symbol_get("IDENTIFIER"));
  grammar_current_rule_symbol_append(symbol_get("EQUAL"));
  grammar_current_rule_symbol_append(symbol_get("initializer"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("single_declaration"));
  grammar_current_rule_symbol_append(symbol_get("fully_specified_type"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("single_declaration"));
  grammar_current_rule_symbol_append(symbol_get("fully_specified_type"));
  grammar_current_rule_symbol_append(symbol_get("IDENTIFIER"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("single_declaration"));
  grammar_current_rule_symbol_append(symbol_get("fully_specified_type"));
  grammar_current_rule_symbol_append(symbol_get("IDENTIFIER"));
  grammar_current_rule_symbol_append(symbol_get("array_specifier"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("single_declaration"));
  grammar_current_rule_symbol_append(symbol_get("fully_specified_type"));
  grammar_current_rule_symbol_append(symbol_get("IDENTIFIER"));
  grammar_current_rule_symbol_append(symbol_get("array_specifier"));
  grammar_current_rule_symbol_append(symbol_get("EQUAL"));
  grammar_current_rule_symbol_append(symbol_get("initializer"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("single_declaration"));
  grammar_current_rule_symbol_append(symbol_get("fully_specified_type"));
  grammar_current_rule_symbol_append(symbol_get("IDENTIFIER"));
  grammar_current_rule_symbol_append(symbol_get("EQUAL"));
  grammar_current_rule_symbol_append(symbol_get("initializer"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("fully_specified_type"));
  grammar_current_rule_symbol_append(symbol_get("type_specifier"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("fully_specified_type"));
  grammar_current_rule_symbol_append(symbol_get("type_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("type_specifier"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("invariant_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("INVARIANT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("interpolation_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("SMOOTH"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("interpolation_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("FLAT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("interpolation_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("NOPERSPECTIVE"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("interpolation_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("EXPLICITINTERPAMD"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("interpolation_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("PERVERTEXNV"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("interpolation_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("PERVERTEXEXT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("interpolation_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("PERPRIMITIVENV"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("interpolation_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("PERPRIMITIVEEXT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("interpolation_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("PERVIEWNV"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("interpolation_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("PERTASKNV"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("layout_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("LAYOUT"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_PAREN"));
  grammar_current_rule_symbol_append(symbol_get("layout_qualifier_id_list"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_PAREN"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("layout_qualifier_id_list"));
  grammar_current_rule_symbol_append(symbol_get("layout_qualifier_id"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("layout_qualifier_id_list"));
  grammar_current_rule_symbol_append(symbol_get("layout_qualifier_id_list"));
  grammar_current_rule_symbol_append(symbol_get("COMMA"));
  grammar_current_rule_symbol_append(symbol_get("layout_qualifier_id"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("layout_qualifier_id"));
  grammar_current_rule_symbol_append(symbol_get("IDENTIFIER"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("layout_qualifier_id"));
  grammar_current_rule_symbol_append(symbol_get("IDENTIFIER"));
  grammar_current_rule_symbol_append(symbol_get("EQUAL"));
  grammar_current_rule_symbol_append(symbol_get("constant_expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("layout_qualifier_id"));
  grammar_current_rule_symbol_append(symbol_get("SHARED"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("precise_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("PRECISE"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("single_type_qualifier"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("type_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("single_type_qualifier"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("single_type_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("storage_qualifier"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("single_type_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("layout_qualifier"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("single_type_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("precision_qualifier"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("single_type_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("interpolation_qualifier"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("single_type_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("invariant_qualifier"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("single_type_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("precise_qualifier"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("single_type_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("non_uniform_qualifier"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("single_type_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("spirv_storage_class_qualifier"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("single_type_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("spirv_decorate_qualifier"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("single_type_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("SPIRV_BY_REFERENCE"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("single_type_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("SPIRV_LITERAL"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("storage_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("CONST"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("storage_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("INOUT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("storage_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("IN"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("storage_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("OUT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("storage_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("CENTROID"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("storage_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("UNIFORM"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("storage_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("TILEIMAGEEXT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("storage_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("SHARED"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("storage_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("BUFFER"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("storage_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("ATTRIBUTE"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("storage_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("VARYING"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("storage_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("PATCH"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("storage_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("SAMPLE"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("storage_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("HITATTRNV"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("storage_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("HITOBJECTATTRNV"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("storage_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("HITOBJECTATTREXT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("storage_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("HITATTREXT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("storage_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("PAYLOADNV"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("storage_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("PAYLOADEXT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("storage_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("PAYLOADINNV"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("storage_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("PAYLOADINEXT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("storage_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("CALLDATANV"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("storage_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("CALLDATAEXT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("storage_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("CALLDATAINNV"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("storage_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("CALLDATAINEXT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("storage_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("COHERENT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("storage_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("DEVICECOHERENT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("storage_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("QUEUEFAMILYCOHERENT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("storage_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("WORKGROUPCOHERENT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("storage_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("SUBGROUPCOHERENT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("storage_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("NONPRIVATE"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("storage_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("SHADERCALLCOHERENT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("storage_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("VOLATILE"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("storage_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("RESTRICT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("storage_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("READONLY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("storage_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("WRITEONLY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("storage_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("NONTEMPORAL"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("storage_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("SUBROUTINE"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("storage_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("SUBROUTINE"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_PAREN"));
  grammar_current_rule_symbol_append(symbol_get("type_name_list"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_PAREN"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("storage_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("TASKPAYLOADWORKGROUPEXT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("non_uniform_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("NONUNIFORM"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_name_list"));
  grammar_current_rule_symbol_append(symbol_get("IDENTIFIER"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_name_list"));
  grammar_current_rule_symbol_append(symbol_get("type_name_list"));
  grammar_current_rule_symbol_append(symbol_get("COMMA"));
  grammar_current_rule_symbol_append(symbol_get("IDENTIFIER"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier"));
  grammar_current_rule_symbol_append(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("type_parameter_specifier_opt"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier"));
  grammar_current_rule_symbol_append(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("type_parameter_specifier_opt"));
  grammar_current_rule_symbol_append(symbol_get("array_specifier"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("array_specifier"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_BRACKET"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_BRACKET"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("array_specifier"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_BRACKET"));
  grammar_current_rule_symbol_append(symbol_get("conditional_expression"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_BRACKET"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("array_specifier"));
  grammar_current_rule_symbol_append(symbol_get("array_specifier"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_BRACKET"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_BRACKET"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("array_specifier"));
  grammar_current_rule_symbol_append(symbol_get("array_specifier"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_BRACKET"));
  grammar_current_rule_symbol_append(symbol_get("conditional_expression"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_BRACKET"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_parameter_specifier_opt"));
  grammar_current_rule_symbol_append(symbol_get("type_parameter_specifier"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_parameter_specifier_opt"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_parameter_specifier"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_ANGLE"));
  grammar_current_rule_symbol_append(symbol_get("type_parameter_specifier_list"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_ANGLE"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_parameter_specifier_list"));
  grammar_current_rule_symbol_append(symbol_get("type_specifier"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_parameter_specifier_list"));
  grammar_current_rule_symbol_append(symbol_get("unary_expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_parameter_specifier_list"));
  grammar_current_rule_symbol_append(symbol_get("type_parameter_specifier_list"));
  grammar_current_rule_symbol_append(symbol_get("COMMA"));
  grammar_current_rule_symbol_append(symbol_get("unary_expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("VOID"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("FLOAT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("INT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UINT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("BOOL"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("VEC2"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("VEC3"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("VEC4"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("BVEC2"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("BVEC3"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("BVEC4"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("IVEC2"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("IVEC3"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("IVEC4"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UVEC2"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UVEC3"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UVEC4"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("MAT2"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("MAT3"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("MAT4"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("MAT2X2"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("MAT2X3"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("MAT2X4"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("MAT3X2"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("MAT3X3"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("MAT3X4"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("MAT4X2"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("MAT4X3"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("MAT4X4"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("DOUBLE"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("BFLOAT16_T"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("FLOATE5M2_T"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("FLOATE4M3_T"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("FLOAT16_T"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("FLOAT32_T"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("FLOAT64_T"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("INT8_T"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UINT8_T"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("INT16_T"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UINT16_T"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("INT32_T"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UINT32_T"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("INT64_T"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UINT64_T"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("DVEC2"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("DVEC3"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("DVEC4"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("BF16VEC2"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("BF16VEC3"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("BF16VEC4"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("FE5M2VEC2"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("FE5M2VEC3"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("FE5M2VEC4"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("FE4M3VEC2"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("FE4M3VEC3"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("FE4M3VEC4"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16VEC2"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16VEC3"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16VEC4"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F32VEC2"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F32VEC3"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F32VEC4"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F64VEC2"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F64VEC3"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F64VEC4"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("I8VEC2"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("I8VEC3"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("I8VEC4"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("I16VEC2"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("I16VEC3"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("I16VEC4"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("I32VEC2"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("I32VEC3"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("I32VEC4"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("I64VEC2"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("I64VEC3"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("I64VEC4"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("U8VEC2"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("U8VEC3"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("U8VEC4"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("U16VEC2"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("U16VEC3"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("U16VEC4"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("U32VEC2"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("U32VEC3"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("U32VEC4"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("U64VEC2"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("U64VEC3"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("U64VEC4"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("DMAT2"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("DMAT3"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("DMAT4"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("DMAT2X2"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("DMAT2X3"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("DMAT2X4"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("DMAT3X2"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("DMAT3X3"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("DMAT3X4"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("DMAT4X2"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("DMAT4X3"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("DMAT4X4"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16MAT2"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16MAT3"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16MAT4"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16MAT2X2"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16MAT2X3"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16MAT2X4"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16MAT3X2"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16MAT3X3"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16MAT3X4"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16MAT4X2"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16MAT4X3"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16MAT4X4"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F32MAT2"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F32MAT3"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F32MAT4"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F32MAT2X2"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F32MAT2X3"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F32MAT2X4"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F32MAT3X2"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F32MAT3X3"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F32MAT3X4"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F32MAT4X2"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F32MAT4X3"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F32MAT4X4"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F64MAT2"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F64MAT3"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F64MAT4"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F64MAT2X2"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F64MAT2X3"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F64MAT2X4"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F64MAT3X2"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F64MAT3X3"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F64MAT3X4"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F64MAT4X2"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F64MAT4X3"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F64MAT4X4"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("ACCSTRUCTNV"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("ACCSTRUCTEXT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("RAYQUERYEXT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("ATOMIC_UINT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("SAMPLER1D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("SAMPLER2D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("SAMPLER3D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("SAMPLERCUBE"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("SAMPLER2DSHADOW"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("SAMPLERCUBESHADOW"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("SAMPLER2DARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("SAMPLER2DARRAYSHADOW"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("SAMPLER1DSHADOW"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("SAMPLER1DARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("SAMPLER1DARRAYSHADOW"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("SAMPLERCUBEARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("SAMPLERCUBEARRAYSHADOW"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16SAMPLER1D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16SAMPLER2D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16SAMPLER3D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16SAMPLERCUBE"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16SAMPLER1DSHADOW"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16SAMPLER2DSHADOW"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16SAMPLERCUBESHADOW"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16SAMPLER1DARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16SAMPLER2DARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16SAMPLER1DARRAYSHADOW"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16SAMPLER2DARRAYSHADOW"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16SAMPLERCUBEARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16SAMPLERCUBEARRAYSHADOW"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("ISAMPLER1D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("ISAMPLER2D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("ISAMPLER3D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("ISAMPLERCUBE"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("ISAMPLER2DARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("USAMPLER2D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("USAMPLER3D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("USAMPLERCUBE"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("ISAMPLER1DARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("ISAMPLERCUBEARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("USAMPLER1D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("USAMPLER1DARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("USAMPLERCUBEARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("TEXTURECUBEARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("ITEXTURECUBEARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UTEXTURECUBEARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("USAMPLER2DARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("TEXTURE2D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("TEXTURE3D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("TEXTURE2DARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("TEXTURECUBE"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("ITEXTURE2D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("ITEXTURE3D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("ITEXTURECUBE"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("ITEXTURE2DARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UTEXTURE2D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UTEXTURE3D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UTEXTURECUBE"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UTEXTURE2DARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("SAMPLER"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("SAMPLERSHADOW"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("SAMPLER2DRECT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("SAMPLER2DRECTSHADOW"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16SAMPLER2DRECT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16SAMPLER2DRECT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16SAMPLER2DRECTSHADOW"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("ISAMPLER2DRECT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("USAMPLER2DRECT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("SAMPLERBUFFER"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16SAMPLERBUFFER"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("ISAMPLERBUFFER"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("USAMPLERBUFFER"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("SAMPLER2DMS"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16SAMPLER2DMS"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("ISAMPLER2DMS"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("USAMPLER2DMS"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("SAMPLER2DMSARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16SAMPLER2DMSARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("ISAMPLER2DMSARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("USAMPLER2DMSARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("TEXTURE1D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16TEXTURE1D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16TEXTURE2D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16TEXTURE3D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16TEXTURECUBE"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("TEXTURE1DARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16TEXTURE1DARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16TEXTURE2DARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16TEXTURECUBEARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("ITEXTURE1D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("ITEXTURE1DARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UTEXTURE1D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UTEXTURE1DARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("TEXTURE2DRECT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16TEXTURE2DRECT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("ITEXTURE2DRECT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UTEXTURE2DRECT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("TEXTUREBUFFER"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16TEXTUREBUFFER"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("ITEXTUREBUFFER"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UTEXTUREBUFFER"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("TEXTURE2DMS"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16TEXTURE2DMS"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("ITEXTURE2DMS"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UTEXTURE2DMS"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("TEXTURE2DMSARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16TEXTURE2DMSARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("ITEXTURE2DMSARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UTEXTURE2DMSARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("IMAGE1D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16IMAGE1D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("IIMAGE1D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UIMAGE1D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("IMAGE2D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16IMAGE2D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("IIMAGE2D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UIMAGE2D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("IMAGE3D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16IMAGE3D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("IIMAGE3D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UIMAGE3D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("IMAGE2DRECT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16IMAGE2DRECT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("IIMAGE2DRECT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UIMAGE2DRECT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("IMAGECUBE"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16IMAGECUBE"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("IIMAGECUBE"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UIMAGECUBE"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("IMAGEBUFFER"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16IMAGEBUFFER"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("IIMAGEBUFFER"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UIMAGEBUFFER"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("IMAGE1DARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16IMAGE1DARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("IIMAGE1DARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UIMAGE1DARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("IMAGE2DARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16IMAGE2DARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("IIMAGE2DARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UIMAGE2DARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("IMAGECUBEARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16IMAGECUBEARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("IIMAGECUBEARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UIMAGECUBEARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("IMAGE2DMS"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16IMAGE2DMS"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("IIMAGE2DMS"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UIMAGE2DMS"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("IMAGE2DMSARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16IMAGE2DMSARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("IIMAGE2DMSARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UIMAGE2DMSARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("I64IMAGE1D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("U64IMAGE1D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("I64IMAGE2D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("U64IMAGE2D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("I64IMAGE3D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("U64IMAGE3D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("I64IMAGE2DRECT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("U64IMAGE2DRECT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("I64IMAGECUBE"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("U64IMAGECUBE"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("I64IMAGEBUFFER"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("U64IMAGEBUFFER"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("I64IMAGE1DARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("U64IMAGE1DARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("I64IMAGE2DARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("U64IMAGE2DARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("I64IMAGECUBEARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("U64IMAGECUBEARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("I64IMAGE2DMS"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("U64IMAGE2DMS"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("I64IMAGE2DMSARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("U64IMAGE2DMSARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("SAMPLEREXTERNALOES"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("SAMPLEREXTERNAL2DY2YEXT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("ATTACHMENTEXT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("ATTACHMENTEXT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("IATTACHMENTEXT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UATTACHMENTEXT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("SUBPASSINPUT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("SUBPASSINPUTMS"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16SUBPASSINPUT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("ISUBPASSINPUT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("ISUBPASSINPUTMS"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("USUBPASSINPUT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("USUBPASSINPUTMS"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("FCOOPMATNV"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("ICOOPMATNV"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UCOOPMATNV"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("COOPMAT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("TENSORLAYOUTNV"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("TENSORVIEWNV"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("FUNCTION"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("COOPVECNV"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("TENSORARM"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("spirv_type_specifier"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("HITOBJECTNV"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("HITOBJECTEXT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("struct_specifier"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("TYPE_NAME"));
  grammar_current_rule_end();






















}
