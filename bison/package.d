module bison;

import bison.glslgram;

symbol_t acceptsymbol;
symbol_t errtoken;
symbol_t undeftoken;
symbol_t eoftoken;
symbol_t[] symbols;
symbol_t[] symbols_sorted;
symbol_t[string] symbol_table;

symbol_list_t grammar;
symbol_list_t grammar_end;
symbol_list_t start_symbols;
symbol_list_t current_rule;
symbol_list_t previous_rule_end;

item_number_t[] ritem;
int nritems = 0;

rule_t[] rules;
rule_number_t nrules = 0;
rule_t[][][] derives;

int nnterms = 0;
int ntokens = 1;
int nsyms = 0;

item_index_t[][] kernel_base;
item_index_t[] kernel_items;

bool[][] fderives;

static this() {
  gram_init_pre();
  glslgram();
  gram_init_post();
  derives_compute();
  generate_states();
}

void main() {
  import std.stdio;

  writeln(ntokens);
  writeln(nnterms);
  writeln(nrules);
  writeln(nritems);
}

alias symbol_number_t = int;
alias rule_number_t = int;
alias item_number_t = int;

alias item_index_t = uint;

enum symbol_class_t {
  unknown_sym,
  percent_type_sym,
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

class symbol_list_t {
  symbol_t sym;
  symbol_list_t next;

  this(symbol_t sym) {
    this.sym = sym;
  }
}

struct rule_t {
  rule_number_t number;
  sym_content_t lhs;
  item_number_t[] rhs;
}

void derives_compute() {
  import std.range;

  struct rule_list_t {
    rule_list_t[] next;
    rule_t[] value;
  }

  rule_list_t[][] dset = new rule_list_t[][nnterms];
  rule_list_t[] delts = new rule_list_t[nrules];

  for (rule_number_t r = nrules - 1; r >= 0; --r) {
    symbol_number_t lhs = rules[r].lhs.number;
    rule_list_t[] p = delts[r..$];

    p.front.next = dset[lhs - ntokens];
    p.front.value = rules[r..$];

    dset[lhs - ntokens] = p;
  }

  derives = new rule_t[][][nnterms];
  rule_t[][] q = new rule_t[][nnterms + nrules];

  for (symbol_number_t i = ntokens; i < nsyms; ++i) {
    rule_list_t[] p = dset[i - ntokens];
    derives[i - ntokens] = q;

    while (p) {
      q.front = p.front.value;
      q.popFront;
      p = p.front.next;
    }

    q.front = null;
    q.popFront;
  }
}

void print_derives() {
  import std.range.primitives;
  import std.stdio;

  write("DERIVES\n");

  for (symbol_number_t i = ntokens; i < nsyms; ++i) {
    writef("  %s derives\n", symbols[i].tag);
    for (rule_t[][] rp = derives[i - ntokens]; rp.front; rp.popFront) {
      writef("    %3d ", rp.front.front.number);
      if (rp.front.front.rhs.front >= 0)
        for (item_number_t[] rhsp = rp.front.front.rhs; rhsp.front >= 0; rhsp.popFront)
          writef(" %s", symbols[rhsp.front].tag);
      else
        writef(" %s", cast(dchar) 0x03b5);
      write("\n");
    }
  }

  write("\n\n");
}

void generate_states() {
  allocate_storage();
  closure_new(nritems);
}

void closure_new(int n) {
  set_fderives();
}

void set_fderives() {
  import std.range.primitives;

  bool[] buffer = new bool[nnterms * nrules];
  fderives = new bool[][nnterms];
  {
    size_t j;
    for (size_t i = 0; i < nnterms; i++) {
      j = i + 1;
      fderives[i] = buffer[i * nrules..j * nrules];
    }
  }

  bool[][] firsts;
  set_firsts(firsts);

  for (symbol_number_t i = ntokens; i < nsyms; ++i)
    for (symbol_number_t j = ntokens; j < nsyms; ++j)
      if (firsts[i - ntokens][j - ntokens])
        for (rule_number_t k = 0; derives[j - ntokens][k]; ++k)
          fderives[i - ntokens][derives[j - ntokens][k].front.number] = true;
}

void print_fderives() {
  import std.range.primitives;
  import std.stdio;

  write("FDERIVES\n");

  for (symbol_number_t i = ntokens; i < nsyms; ++i) {
    writef("  %s derives\n", symbols[i].tag);
    foreach (r, flag; fderives[i - ntokens])
      if (flag) {
        writef("    %3d ", r);
        if (rules[r].rhs.front >= 0)
          for (item_number_t[] rhsp = rules[r].rhs; rhsp.front >= 0; rhsp.popFront)
            writef(" %s", symbols[rhsp.front].tag);
        else
          writef(" %s", cast(dchar) 0x03b5);
        write("\n");
      }
  }

  write("\n\n");
}

void set_firsts(out bool[][] firsts) {
  import std.range.primitives;

  bool[] buffer = new bool[nnterms * nnterms];
  firsts = new bool[][nnterms];
  {
    size_t j;
    for (size_t i = 0; i < nnterms; i++) {
      j = i + 1;
      firsts[i] = buffer[i * nnterms..j * nnterms];
    }
  }
  
  for (symbol_number_t i = ntokens; i < nsyms; ++i)
    for (symbol_number_t j = 0; derives[i - ntokens][j]; ++j) {
      item_number_t sym = derives[i - ntokens][j].front.rhs.front;
      if(sym >= ntokens)
        firsts[i - ntokens][sym - ntokens] = true;
    }
  
  for (size_t i = 0; i < firsts.length; i++)
    for (size_t j = 0; j < firsts.length; j++)
      if (firsts[j][i])
        for (size_t k = 0; k < firsts[j].length; k++)
          firsts[j][k] = firsts[j][k] || firsts[i][k];

  for (size_t i = 0; i < firsts.length; i++)
    firsts[i][i] = true;
}

void print_firsts(in bool[][] firsts) {
  import std.stdio;

  write("FIRSTS\n");

  for (symbol_number_t i = ntokens; i < nsyms; ++i) {
    writef("  %s firsts\n", symbols[i].tag);
    foreach (j, flag; firsts[i - ntokens])
      if (flag) writef("    %s\n", symbols[j + ntokens].tag);
  }

  write("\n\n");
}

void allocate_storage() {
  allocate_itemsets();
}

void allocate_itemsets() {
  size_t count = 0;
  size_t[] symbol_count = new size_t[nsyms];

  for (rule_number_t r = 0; r < nrules; ++r)
    for (size_t i = 0; rules[r].rhs[i] >= 0; i++) {
      symbol_number_t sym = rules[r].rhs[i];
      count += 1;
      symbol_count[sym] += 1;
    }

  kernel_base = new item_index_t[][nsyms];
  kernel_items = new item_index_t[count];

  count = 0;
  for (symbol_number_t i = 0; i < nsyms; i++) {
    kernel_base[i] = kernel_items[count..$];
    count += symbol_count[i];
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
