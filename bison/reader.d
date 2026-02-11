module bison.reader;
import bison;

symbol_list_t grammar;
symbol_list_t start_symbols;

symbol_list_t grammar_end;

symbol_list_t current_rule;
symbol_list_t previous_rule_end;

void create_start_rule(symbol_t swtok, symbol_t start) {
  symbol_list_t initial_rule = new symbol_list_t(acceptsymbol);
  symbol_list_t p = initial_rule;
  p.next = new symbol_list_t(start);
  p = p.next;
  p.next = new symbol_list_t(eoftoken);
  p = p.next;
  p.next = new symbol_list_t(null);
  p = p.next;
  p.next = grammar;
  nrules += 1;
  nritems += 3;
  grammar = initial_rule;
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

void grammar_start_symbols_add(symbol_list_t syms) {
  start_symbols = syms;
}

void grammar_current_rule_begin(symbol_t lhs) {
  ++nrules;
  previous_rule_end = grammar_end;

  current_rule = grammar_symbol_append(lhs);

  if (lhs.content.class_ == symbol_class_t.unknown_sym ||
    lhs.content.class_ == symbol_class_t.percent_type_sym) {
    lhs.content.class_ = symbol_class_t.nterm_sym;
  }
}

void grammar_current_rule_symbol_append(symbol_t sym) {
  grammar_symbol_append(sym);
}

void grammar_current_rule_end() {
  grammar_symbol_append(null);
}

void grammar_midrule_action() {
  symbol_t dummy = dummy_symbol_get();
  symbol_list_t midrule = new symbol_list_t(dummy);

  ++nrules;
  ++nritems;
  
  if (previous_rule_end)
    previous_rule_end.next = midrule;
  else
    grammar = midrule;

  midrule.next = new symbol_list_t(null);
  midrule.next.next = current_rule;

  previous_rule_end = midrule.next;

  grammar_current_rule_symbol_append(dummy);
}

void packgram() {
  import std.range.primitives;

  int itemno = 0;
  ritem = new item_number_t[nritems];

  rule_number_t ruleno = 0;
  rules = new rule_t[nrules];

  for (symbol_list_t p = grammar; p; p = p.next) {
    symbol_list_t lhs = p;

    rules[ruleno].number = ruleno;
    rules[ruleno].lhs = lhs.sym.content;
    rules[ruleno].rhs = ritem[itemno..$];

    size_t rule_length = 0;
    for (p = lhs.next; p.sym; p = p.next) {
      ++rule_length;
      ritem[itemno++] = p.sym.content.number;
    }

    ritem[itemno++] = -1 - ruleno;
    ++ruleno;
  }
}

void gram_init_pre() {
  acceptsymbol = symbol_get("$accept");
  acceptsymbol.order_of_appearance = 0;
  acceptsymbol.content.class_ = symbol_class_t.nterm_sym;
  acceptsymbol.content.number = nnterms++;

  errtoken = symbol_get("YYerror");
  errtoken.order_of_appearance = 0;
  errtoken.content.class_ = symbol_class_t.token_sym;
  errtoken.content.number = ntokens++;
  {
    symbol_t alias_ = symbol_get("error");
    alias_.order_of_appearance = 0;
    alias_.content.class_ = symbol_class_t.token_sym;
    errtoken.make_alias(alias_);
  }

  undeftoken = symbol_get("YYUNDEF");
  undeftoken.order_of_appearance = 0;
  undeftoken.content.class_ = symbol_class_t.token_sym;
  undeftoken.content.number = ntokens++;
  {
    symbol_t alias_ = symbol_get("$undefined");
    alias_.order_of_appearance = 0;
    alias_.content.class_ = symbol_class_t.token_sym;
    undeftoken.make_alias(alias_);
  }
}

void gram_init_post() {
  import std.algorithm.sorting;
  import std.array;

  eoftoken = symbol_get("YYEOF");
  eoftoken.order_of_appearance = 0;
  eoftoken.content.class_ = symbol_class_t.token_sym;
  eoftoken.content.number = 0;
  {
    symbol_t alias_ = symbol_get("$end");
    alias_.order_of_appearance = 0;
    alias_.content.class_ = symbol_class_t.token_sym;
    eoftoken.make_alias(alias_);
  }

  symbol_t start = start_symbols.sym;
  create_start_rule(null, start);

  symbols_sorted = symbol_table.values
    .sort!("a.order_of_appearance < b.order_of_appearance")
    .array;
  foreach (sym; symbols_sorted) {
    sym_content_t s = sym.content;

    if (s.number == NUMBER_UNDEFINED)
      s.number = s.class_ == symbol_class_t.token_sym ? ntokens++ : nnterms++;
  }

  nsyms = ntokens + nnterms;
  symbols = new symbol_t[nsyms];

  foreach (sym; symbols_sorted) {
    if (sym.content.class_ == symbol_class_t.nterm_sym)
      sym.content.number += ntokens;

    symbols[sym.content.number] = sym.content.symbol;
  }

  packgram();
}
