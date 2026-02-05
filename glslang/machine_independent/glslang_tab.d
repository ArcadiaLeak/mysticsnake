module glslang.machine_independent.glslang_tab;

symbol_t acceptsymbol;
symbol_t errtoken;
symbol_t undeftoken;
symbol_t eoftoken;

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

int nnterms = 0;
int ntokens = 1;
int nsyms = 0;

item_index_t[][] kernel_base;
item_index_t[] kernel_items;

static this() {
  gram_init_pre();
  gram_init();
  gram_init_post();
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

struct rule_t {
  sym_content_t lhs;
  item_number_t[] rhs;
}

void generate_states() {
  allocate_storage();
}

void allocate_storage() {
  allocate_itemsets();
}

void allocate_itemsets() {
  size_t count = 0;
  size_t[] symbol_count = new size_t[nsyms];
}

void gram_init_pre() {
  acceptsymbol = symbol_get("$accept");
  acceptsymbol.content.class_ = symbol_class_t.nonterm_sym;
  acceptsymbol.content.number = nnterms++;

  errtoken = symbol_get("YYerror");
  errtoken.content.class_ = symbol_class_t.token_sym;
  errtoken.content.number = ntokens++;
  {
    symbol_t alias_ = symbol_get("error");
    alias_.content.class_ = symbol_class_t.token_sym;
    errtoken.make_alias(alias_);
  }

  undeftoken = symbol_get("YYUNDEF");
  undeftoken.content.class_ = symbol_class_t.token_sym;
  undeftoken.content.number = ntokens++;
  {
    symbol_t alias_ = symbol_get("$undefined");
    alias_.content.class_ = symbol_class_t.token_sym;
    undeftoken.make_alias(alias_);
  }
}

void gram_init_post() {
  eoftoken = symbol_get("YYEOF");
  eoftoken.content.class_ = symbol_class_t.token_sym;
  eoftoken.content.number = 0;
  {
    symbol_t alias_ = symbol_get("$end");
    alias_.content.class_ = symbol_class_t.token_sym;
    eoftoken.make_alias(alias_);
  }

  symbol_t start = start_symbols.sym;
  create_start_rule(null, start);

  foreach (sym; symbol_table.byValue) {
    sym_content_t s = sym.content;

    if (s.number == NUMBER_UNDEFINED)
      s.number = s.class_ == symbol_class_t.token_sym ? ntokens++ : nnterms++;
  }

  nsyms = ntokens + nnterms;

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

void symbol_class_set(symbol_t sym, symbol_class_t class_, bool declaring) {
  sym_content_t s = sym.content;
  s.class_ = class_;
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

void grammar_start_symbols_add(symbol_list_t syms) {
  start_symbols = syms;
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

    rules[ruleno].lhs = lhs.sym.content;
    rules[ruleno].rhs = ritem[itemno..$];

    size_t rule_length = 0;
    for (p = lhs.next; p.sym; p = p.next) {
      ++rule_length;
      ritem[itemno++] = p.sym.content.number;
    }

    ritem[itemno++] = ruleno;
    ++ruleno;
  }
}

void gram_init() {
  symbol_class_set(symbol_get("CONST"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("BOOL"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("INT"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("UINT"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("FLOAT"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("BVEC2"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("BVEC3"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("BVEC4"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("IVEC2"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("IVEC3"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("IVEC4"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("UVEC2"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("UVEC3"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("UVEC4"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("VEC2"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("VEC3"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("VEC4"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("MAT2"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("MAT3"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("MAT4"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("MAT2X2"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("MAT2X3"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("MAT2X4"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("MAT3X2"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("MAT3X3"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("MAT3X4"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("MAT4X2"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("MAT4X3"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("MAT4X4"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("SAMPLER2D"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("SAMPLER3D"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("SAMPLERCUBE"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("SAMPLER2DSHADOW"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("SAMPLERCUBESHADOW"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("SAMPLER2DARRAY"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("SAMPLER2DARRAYSHADOW"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("ISAMPLER2D"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("ISAMPLER3D"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("ISAMPLERCUBE"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("ISAMPLER2DARRAY"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("USAMPLER2D"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("USAMPLER3D"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("USAMPLERCUBE"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("USAMPLER2DARRAY"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("SAMPLER"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("SAMPLERSHADOW"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("TEXTURE2D"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("TEXTURE3D"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("TEXTURECUBE"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("TEXTURE2DARRAY"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("ITEXTURE2D"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("ITEXTURE3D"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("ITEXTURECUBE"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("ITEXTURE2DARRAY"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("UTEXTURE2D"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("UTEXTURE3D"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("UTEXTURECUBE"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("UTEXTURE2DARRAY"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("ATTRIBUTE"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("VARYING"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("FLOATE5M2_T"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("FLOATE4M3_T"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("BFLOAT16_T"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("FLOAT16_T"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("FLOAT32_T"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("DOUBLE"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("FLOAT64_T"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("INT64_T"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("UINT64_T"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("INT32_T"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("UINT32_T"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("INT16_T"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("UINT16_T"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("INT8_T"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("UINT8_T"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("I64VEC2"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("I64VEC3"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("I64VEC4"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("U64VEC2"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("U64VEC3"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("U64VEC4"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("I32VEC2"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("I32VEC3"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("I32VEC4"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("U32VEC2"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("U32VEC3"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("U32VEC4"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("I16VEC2"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("I16VEC3"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("I16VEC4"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("U16VEC2"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("U16VEC3"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("U16VEC4"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("I8VEC2"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("I8VEC3"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("I8VEC4"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("U8VEC2"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("U8VEC3"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("U8VEC4"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("DVEC2"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("DVEC3"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("DVEC4"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("DMAT2"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("DMAT3"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("DMAT4"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("BF16VEC2"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("BF16VEC3"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("BF16VEC4"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("FE5M2VEC2"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("FE5M2VEC3"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("FE5M2VEC4"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("FE4M3VEC2"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("FE4M3VEC3"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("FE4M3VEC4"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("F16VEC2"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F16VEC3"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F16VEC4"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F16MAT2"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F16MAT3"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F16MAT4"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("F32VEC2"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F32VEC3"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F32VEC4"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F32MAT2"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F32MAT3"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F32MAT4"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("F64VEC2"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F64VEC3"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F64VEC4"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F64MAT2"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F64MAT3"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F64MAT4"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("DMAT2X2"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("DMAT2X3"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("DMAT2X4"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("DMAT3X2"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("DMAT3X3"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("DMAT3X4"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("DMAT4X2"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("DMAT4X3"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("DMAT4X4"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("F16MAT2X2"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F16MAT2X3"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F16MAT2X4"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("F16MAT3X2"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F16MAT3X3"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F16MAT3X4"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("F16MAT4X2"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F16MAT4X3"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F16MAT4X4"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("F32MAT2X2"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F32MAT2X3"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F32MAT2X4"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("F32MAT3X2"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F32MAT3X3"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F32MAT3X4"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("F32MAT4X2"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F32MAT4X3"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F32MAT4X4"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("F64MAT2X2"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F64MAT2X3"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F64MAT2X4"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("F64MAT3X2"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F64MAT3X3"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F64MAT3X4"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("F64MAT4X2"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F64MAT4X3"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F64MAT4X4"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("ATOMIC_UINT"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("ACCSTRUCTNV"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("ACCSTRUCTEXT"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("RAYQUERYEXT"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("FCOOPMATNV"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("ICOOPMATNV"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("UCOOPMATNV"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("COOPMAT"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("COOPVECNV"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("HITOBJECTNV"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("HITOBJECTATTRNV"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("HITOBJECTEXT"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("HITOBJECTATTREXT"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("TENSORLAYOUTNV"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("TENSORVIEWNV"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("TENSORARM"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("SAMPLERCUBEARRAY"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("SAMPLERCUBEARRAYSHADOW"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("ISAMPLERCUBEARRAY"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("USAMPLERCUBEARRAY"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("SAMPLER1D"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("SAMPLER1DARRAY"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("SAMPLER1DARRAYSHADOW"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("ISAMPLER1D"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("SAMPLER1DSHADOW"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("SAMPLER2DRECT"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("SAMPLER2DRECTSHADOW"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("ISAMPLER2DRECT"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("USAMPLER2DRECT"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("SAMPLERBUFFER"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("ISAMPLERBUFFER"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("USAMPLERBUFFER"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("SAMPLER2DMS"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("ISAMPLER2DMS"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("USAMPLER2DMS"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("SAMPLER2DMSARRAY"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("ISAMPLER2DMSARRAY"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("USAMPLER2DMSARRAY"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("SAMPLEREXTERNALOES"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("SAMPLEREXTERNAL2DY2YEXT"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("ISAMPLER1DARRAY"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("USAMPLER1D"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("USAMPLER1DARRAY"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("F16SAMPLER1D"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F16SAMPLER2D"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F16SAMPLER3D"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F16SAMPLER2DRECT"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F16SAMPLERCUBE"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("F16SAMPLER1DARRAY"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F16SAMPLER2DARRAY"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F16SAMPLERCUBEARRAY"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("F16SAMPLERBUFFER"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F16SAMPLER2DMS"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F16SAMPLER2DMSARRAY"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("F16SAMPLER1DSHADOW"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F16SAMPLER2DSHADOW"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F16SAMPLER1DARRAYSHADOW"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F16SAMPLER2DARRAYSHADOW"), symbol_class_t.token_sym, true);
  
  symbol_class_set(symbol_get("F16SAMPLER2DRECTSHADOW"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F16SAMPLERCUBESHADOW"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F16SAMPLERCUBEARRAYSHADOW"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("IMAGE1D"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("IIMAGE1D"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("UIMAGE1D"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("IMAGE2D"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("IIMAGE2D"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("UIMAGE2D"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("IMAGE3D"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("IIMAGE3D"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("UIMAGE3D"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("IMAGE2DRECT"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("IIMAGE2DRECT"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("UIMAGE2DRECT"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("IMAGECUBE"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("IIMAGECUBE"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("UIMAGECUBE"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("IMAGEBUFFER"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("IIMAGEBUFFER"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("UIMAGEBUFFER"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("IMAGE1DARRAY"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("IIMAGE1DARRAY"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("UIMAGE1DARRAY"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("IMAGE2DARRAY"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("IIMAGE2DARRAY"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("UIMAGE2DARRAY"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("IMAGECUBEARRAY"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("IIMAGECUBEARRAY"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("UIMAGECUBEARRAY"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("IMAGE2DMS"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("IIMAGE2DMS"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("UIMAGE2DMS"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("IMAGE2DMSARRAY"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("IIMAGE2DMSARRAY"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("UIMAGE2DMSARRAY"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("F16IMAGE1D"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F16IMAGE2D"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F16IMAGE3D"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F16IMAGE2DRECT"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("F16IMAGECUBE"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F16IMAGE1DARRAY"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F16IMAGE2DARRAY"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F16IMAGECUBEARRAY"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("F16IMAGEBUFFER"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F16IMAGE2DMS"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F16IMAGE2DMSARRAY"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("I64IMAGE1D"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("U64IMAGE1D"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("I64IMAGE2D"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("U64IMAGE2D"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("I64IMAGE3D"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("U64IMAGE3D"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("I64IMAGE2DRECT"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("U64IMAGE2DRECT"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("I64IMAGECUBE"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("U64IMAGECUBE"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("I64IMAGEBUFFER"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("U64IMAGEBUFFER"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("I64IMAGE1DARRAY"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("U64IMAGE1DARRAY"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("I64IMAGE2DARRAY"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("U64IMAGE2DARRAY"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("I64IMAGECUBEARRAY"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("U64IMAGECUBEARRAY"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("I64IMAGE2DMS"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("U64IMAGE2DMS"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("I64IMAGE2DMSARRAY"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("U64IMAGE2DMSARRAY"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("TEXTURECUBEARRAY"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("ITEXTURECUBEARRAY"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("UTEXTURECUBEARRAY"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("TEXTURE1D"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("ITEXTURE1D"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("UTEXTURE1D"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("TEXTURE1DARRAY"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("ITEXTURE1DARRAY"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("UTEXTURE1DARRAY"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("TEXTURE2DRECT"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("ITEXTURE2DRECT"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("UTEXTURE2DRECT"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("TEXTUREBUFFER"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("ITEXTUREBUFFER"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("UTEXTUREBUFFER"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("TEXTURE2DMS"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("ITEXTURE2DMS"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("UTEXTURE2DMS"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("TEXTURE2DMSARRAY"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("ITEXTURE2DMSARRAY"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("UTEXTURE2DMSARRAY"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("F16TEXTURE1D"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F16TEXTURE2D"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F16TEXTURE3D"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F16TEXTURE2DRECT"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F16TEXTURECUBE"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("F16TEXTURE1DARRAY"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F16TEXTURE2DARRAY"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F16TEXTURECUBEARRAY"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("F16TEXTUREBUFFER"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F16TEXTURE2DMS"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F16TEXTURE2DMSARRAY"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("SUBPASSINPUT"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("SUBPASSINPUTMS"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("ISUBPASSINPUT"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("ISUBPASSINPUTMS"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("USUBPASSINPUT"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("USUBPASSINPUTMS"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("F16SUBPASSINPUT"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("F16SUBPASSINPUTMS"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("SPIRV_INSTRUCTION"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("SPIRV_EXECUTION_MODE"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("SPIRV_EXECUTION_MODE_ID"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("SPIRV_DECORATE"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("SPIRV_DECORATE_ID"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("SPIRV_DECORATE_STRING"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("SPIRV_TYPE"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("SPIRV_STORAGE_CLASS"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("SPIRV_BY_REFERENCE"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("SPIRV_LITERAL"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("ATTACHMENTEXT"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("IATTACHMENTEXT"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("UATTACHMENTEXT"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("LEFT_OP"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("RIGHT_OP"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("INC_OP"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("DEC_OP"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("LE_OP"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("GE_OP"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("EQ_OP"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("NE_OP"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("AND_OP"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("OR_OP"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("XOR_OP"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("MUL_ASSIGN"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("DIV_ASSIGN"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("ADD_ASSIGN"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("MOD_ASSIGN"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("LEFT_ASSIGN"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("RIGHT_ASSIGN"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("AND_ASSIGN"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("XOR_ASSIGN"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("OR_ASSIGN"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("SUB_ASSIGN"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("STRING_LITERAL"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("LEFT_PAREN"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("RIGHT_PAREN"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("LEFT_BRACKET"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("RIGHT_BRACKET"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("LEFT_BRACE"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("RIGHT_BRACE"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("DOT"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("COMMA"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("COLON"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("EQUAL"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("SEMICOLON"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("BANG"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("DASH"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("TILDE"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("PLUS"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("STAR"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("SLASH"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("PERCENT"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("LEFT_ANGLE"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("RIGHT_ANGLE"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("VERTICAL_BAR"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("CARET"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("AMPERSAND"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("QUESTION"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("INVARIANT"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("HIGH_PRECISION"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("MEDIUM_PRECISION"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("LOW_PRECISION"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("PRECISION"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("PACKED"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("RESOURCE"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("SUPERP"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("FLOATCONSTANT"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("INTCONSTANT"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("UINTCONSTANT"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("BOOLCONSTANT"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("IDENTIFIER"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("TYPE_NAME"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("CENTROID"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("IN"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("OUT"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("INOUT"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("STRUCT"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("VOID"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("WHILE"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("BREAK"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("CONTINUE"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("DO"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("ELSE"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("FOR"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("IF"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("DISCARD"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("RETURN"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("SWITCH"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("CASE"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("DEFAULT"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("TERMINATE_INVOCATION"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("TERMINATE_RAY"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("IGNORE_INTERSECTION"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("UNIFORM"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("SHARED"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("BUFFER"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("TILEIMAGEEXT"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("FLAT"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("SMOOTH"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("LAYOUT"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("DOUBLECONSTANT"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("INT16CONSTANT"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("UINT16CONSTANT"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("FLOAT16CONSTANT"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("INT32CONSTANT"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("UINT32CONSTANT"), symbol_class_t.token_sym, true);
  
  symbol_class_set(symbol_get("INT64CONSTANT"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("UINT64CONSTANT"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("SUBROUTINE"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("DEMOTE"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("FUNCTION"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("PAYLOADNV"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("PAYLOADINNV"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("HITATTRNV"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("CALLDATANV"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("CALLDATAINNV"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("PAYLOADEXT"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("PAYLOADINEXT"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("HITATTREXT"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("CALLDATAEXT"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("CALLDATAINEXT"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("PATCH"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("SAMPLE"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("NONUNIFORM"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("COHERENT"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("VOLATILE"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("RESTRICT"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("READONLY"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("WRITEONLY"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("NONTEMPORAL"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("DEVICECOHERENT"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("QUEUEFAMILYCOHERENT"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("WORKGROUPCOHERENT"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("SUBGROUPCOHERENT"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("NONPRIVATE"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("SHADERCALLCOHERENT"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("NOPERSPECTIVE"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("EXPLICITINTERPAMD"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("PERVERTEXEXT"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("PERVERTEXNV"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("PERPRIMITIVENV"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("PERVIEWNV"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("PERTASKNV"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("PERPRIMITIVEEXT"), symbol_class_t.token_sym, true);
  symbol_class_set(symbol_get("TASKPAYLOADWORKGROUPEXT"), symbol_class_t.token_sym, true);

  symbol_class_set(symbol_get("PRECISE"), symbol_class_t.token_sym, true);

  grammar_start_symbols_add(new symbol_list_t(symbol_get("translation_unit")));

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
  grammar_midrule_action();
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
  grammar_midrule_action();
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
  grammar_current_rule_symbol_append(symbol_get("F16SUBPASSINPUTMS"));
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

  grammar_current_rule_begin(symbol_get("precision_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("HIGH_PRECISION"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("precision_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("MEDIUM_PRECISION"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("precision_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("LOW_PRECISION"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("struct_specifier"));
  grammar_current_rule_symbol_append(symbol_get("STRUCT"));
  grammar_current_rule_symbol_append(symbol_get("IDENTIFIER"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_BRACE"));
  grammar_midrule_action();
  grammar_current_rule_symbol_append(symbol_get("struct_declaration_list"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_BRACE"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("struct_specifier"));
  grammar_current_rule_symbol_append(symbol_get("STRUCT"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_BRACE"));
  grammar_midrule_action();
  grammar_current_rule_symbol_append(symbol_get("struct_declaration_list"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_BRACE"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("struct_declaration_list"));
  grammar_current_rule_symbol_append(symbol_get("struct_declaration"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("struct_declaration_list"));
  grammar_current_rule_symbol_append(symbol_get("struct_declaration_list"));
  grammar_current_rule_symbol_append(symbol_get("struct_declaration"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("struct_declaration"));
  grammar_current_rule_symbol_append(symbol_get("type_specifier"));
  grammar_current_rule_symbol_append(symbol_get("struct_declarator_list"));
  grammar_current_rule_symbol_append(symbol_get("SEMICOLON"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("struct_declaration"));
  grammar_current_rule_symbol_append(symbol_get("type_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("type_specifier"));
  grammar_current_rule_symbol_append(symbol_get("struct_declarator_list"));
  grammar_current_rule_symbol_append(symbol_get("SEMICOLON"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("struct_declarator_list"));
  grammar_current_rule_symbol_append(symbol_get("struct_declarator"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("struct_declarator_list"));
  grammar_current_rule_symbol_append(symbol_get("struct_declarator_list"));
  grammar_current_rule_symbol_append(symbol_get("COMMA"));
  grammar_current_rule_symbol_append(symbol_get("struct_declarator"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("struct_declarator"));
  grammar_current_rule_symbol_append(symbol_get("IDENTIFIER"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("struct_declarator"));
  grammar_current_rule_symbol_append(symbol_get("IDENTIFIER"));
  grammar_current_rule_symbol_append(symbol_get("array_specifier"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("initializer"));
  grammar_current_rule_symbol_append(symbol_get("assignment_expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("initializer"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_BRACE"));
  grammar_current_rule_symbol_append(symbol_get("initializer_list"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_BRACE"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("initializer"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_BRACE"));
  grammar_current_rule_symbol_append(symbol_get("initializer_list"));
  grammar_current_rule_symbol_append(symbol_get("COMMA"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_BRACE"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("initializer"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_BRACE"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_BRACE"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("initializer_list"));
  grammar_current_rule_symbol_append(symbol_get("initializer"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("initializer_list"));
  grammar_current_rule_symbol_append(symbol_get("initializer_list"));
  grammar_current_rule_symbol_append(symbol_get("COMMA"));
  grammar_current_rule_symbol_append(symbol_get("initializer"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("declaration_statement"));
  grammar_current_rule_symbol_append(symbol_get("declaration"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("statement"));
  grammar_current_rule_symbol_append(symbol_get("compound_statement"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("statement"));
  grammar_current_rule_symbol_append(symbol_get("simple_statement"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("simple_statement"));
  grammar_current_rule_symbol_append(symbol_get("declaration_statement"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("simple_statement"));
  grammar_current_rule_symbol_append(symbol_get("expression_statement"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("simple_statement"));
  grammar_current_rule_symbol_append(symbol_get("selection_statement"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("simple_statement"));
  grammar_current_rule_symbol_append(symbol_get("switch_statement"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("simple_statement"));
  grammar_current_rule_symbol_append(symbol_get("case_label"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("simple_statement"));
  grammar_current_rule_symbol_append(symbol_get("iteration_statement"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("simple_statement"));
  grammar_current_rule_symbol_append(symbol_get("jump_statement"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("simple_statement"));
  grammar_current_rule_symbol_append(symbol_get("demote_statement"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("demote_statement"));
  grammar_current_rule_symbol_append(symbol_get("DEMOTE"));
  grammar_current_rule_symbol_append(symbol_get("SEMICOLON"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("compound_statement"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_BRACE"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_BRACE"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("compound_statement"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_BRACE"));
  grammar_midrule_action();
  grammar_current_rule_symbol_append(symbol_get("statement_list"));
  grammar_midrule_action();
  grammar_current_rule_symbol_append(symbol_get("RIGHT_BRACE"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("statement_no_new_scope"));
  grammar_current_rule_symbol_append(symbol_get("compound_statement_no_new_scope"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("statement_no_new_scope"));
  grammar_current_rule_symbol_append(symbol_get("simple_statement"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("statement_scoped"));
  grammar_midrule_action();
  grammar_current_rule_symbol_append(symbol_get("compound_statement"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("statement_scoped"));
  grammar_midrule_action();
  grammar_current_rule_symbol_append(symbol_get("simple_statement"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("compound_statement_no_new_scope"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_BRACE"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_BRACE"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("compound_statement_no_new_scope"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_BRACE"));
  grammar_current_rule_symbol_append(symbol_get("statement_list"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_BRACE"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("statement_list"));
  grammar_current_rule_symbol_append(symbol_get("statement"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("statement_list"));
  grammar_current_rule_symbol_append(symbol_get("statement_list"));
  grammar_current_rule_symbol_append(symbol_get("statement"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("expression_statement"));
  grammar_current_rule_symbol_append(symbol_get("SEMICOLON"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("expression_statement"));
  grammar_current_rule_symbol_append(symbol_get("expression"));
  grammar_current_rule_symbol_append(symbol_get("SEMICOLON"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("selection_statement"));
  grammar_current_rule_symbol_append(symbol_get("selection_statement_nonattributed"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("selection_statement"));
  grammar_current_rule_symbol_append(symbol_get("attribute"));
  grammar_current_rule_symbol_append(symbol_get("selection_statement_nonattributed"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("selection_statement_nonattributed"));
  grammar_current_rule_symbol_append(symbol_get("IF"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_PAREN"));
  grammar_current_rule_symbol_append(symbol_get("expression"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_PAREN"));
  grammar_current_rule_symbol_append(symbol_get("selection_rest_statement"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("selection_rest_statement"));
  grammar_current_rule_symbol_append(symbol_get("statement_scoped"));
  grammar_current_rule_symbol_append(symbol_get("ELSE"));
  grammar_current_rule_symbol_append(symbol_get("statement_scoped"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("selection_rest_statement"));
  grammar_current_rule_symbol_append(symbol_get("statement_scoped"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("condition"));
  grammar_current_rule_symbol_append(symbol_get("expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("condition"));
  grammar_current_rule_symbol_append(symbol_get("fully_specified_type"));
  grammar_current_rule_symbol_append(symbol_get("IDENTIFIER"));
  grammar_current_rule_symbol_append(symbol_get("EQUAL"));
  grammar_current_rule_symbol_append(symbol_get("initializer"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("switch_statement"));
  grammar_current_rule_symbol_append(symbol_get("switch_statement_nonattributed"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("switch_statement"));
  grammar_current_rule_symbol_append(symbol_get("attribute"));
  grammar_current_rule_symbol_append(symbol_get("switch_statement_nonattributed"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("switch_statement_nonattributed"));
  grammar_current_rule_symbol_append(symbol_get("SWITCH"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_PAREN"));
  grammar_current_rule_symbol_append(symbol_get("expression"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_PAREN"));
  grammar_midrule_action();
  grammar_current_rule_symbol_append(symbol_get("LEFT_BRACE"));
  grammar_current_rule_symbol_append(symbol_get("switch_statement_list"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_BRACE"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("switch_statement_list"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("switch_statement_list"));
  grammar_current_rule_symbol_append(symbol_get("statement_list"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("case_label"));
  grammar_current_rule_symbol_append(symbol_get("CASE"));
  grammar_current_rule_symbol_append(symbol_get("expression"));
  grammar_current_rule_symbol_append(symbol_get("COLON"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("case_label"));
  grammar_current_rule_symbol_append(symbol_get("DEFAULT"));
  grammar_current_rule_symbol_append(symbol_get("COLON"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("iteration_statement"));
  grammar_current_rule_symbol_append(symbol_get("iteration_statement_nonattributed"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("iteration_statement"));
  grammar_current_rule_symbol_append(symbol_get("attribute"));
  grammar_current_rule_symbol_append(symbol_get("iteration_statement_nonattributed"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("iteration_statement_nonattributed"));
  grammar_current_rule_symbol_append(symbol_get("WHILE"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_PAREN"));
  grammar_midrule_action();
  grammar_current_rule_symbol_append(symbol_get("condition"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_PAREN"));
  grammar_current_rule_symbol_append(symbol_get("statement_no_new_scope"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("iteration_statement_nonattributed"));
  grammar_current_rule_symbol_append(symbol_get("DO"));
  grammar_midrule_action();
  grammar_current_rule_symbol_append(symbol_get("statement"));
  grammar_current_rule_symbol_append(symbol_get("WHILE"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_PAREN"));
  grammar_current_rule_symbol_append(symbol_get("expression"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_PAREN"));
  grammar_current_rule_symbol_append(symbol_get("SEMICOLON"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("iteration_statement_nonattributed"));
  grammar_current_rule_symbol_append(symbol_get("FOR"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_PAREN"));
  grammar_midrule_action();
  grammar_current_rule_symbol_append(symbol_get("for_init_statement"));
  grammar_current_rule_symbol_append(symbol_get("for_rest_statement"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_PAREN"));
  grammar_current_rule_symbol_append(symbol_get("statement_no_new_scope"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("for_init_statement"));
  grammar_current_rule_symbol_append(symbol_get("expression_statement"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("for_init_statement"));
  grammar_current_rule_symbol_append(symbol_get("declaration_statement"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("conditionopt"));
  grammar_current_rule_symbol_append(symbol_get("condition"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("conditionopt"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("for_rest_statement"));
  grammar_current_rule_symbol_append(symbol_get("conditionopt"));
  grammar_current_rule_symbol_append(symbol_get("SEMICOLON"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("for_rest_statement"));
  grammar_current_rule_symbol_append(symbol_get("conditionopt"));
  grammar_current_rule_symbol_append(symbol_get("SEMICOLON"));
  grammar_current_rule_symbol_append(symbol_get("expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("jump_statement"));
  grammar_current_rule_symbol_append(symbol_get("CONTINUE"));
  grammar_current_rule_symbol_append(symbol_get("SEMICOLON"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("jump_statement"));
  grammar_current_rule_symbol_append(symbol_get("BREAK"));
  grammar_current_rule_symbol_append(symbol_get("SEMICOLON"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("jump_statement"));
  grammar_current_rule_symbol_append(symbol_get("RETURN"));
  grammar_current_rule_symbol_append(symbol_get("SEMICOLON"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("jump_statement"));
  grammar_current_rule_symbol_append(symbol_get("RETURN"));
  grammar_current_rule_symbol_append(symbol_get("expression"));
  grammar_current_rule_symbol_append(symbol_get("SEMICOLON"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("jump_statement"));
  grammar_current_rule_symbol_append(symbol_get("DISCARD"));
  grammar_current_rule_symbol_append(symbol_get("SEMICOLON"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("jump_statement"));
  grammar_current_rule_symbol_append(symbol_get("TERMINATE_INVOCATION"));
  grammar_current_rule_symbol_append(symbol_get("SEMICOLON"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("jump_statement"));
  grammar_current_rule_symbol_append(symbol_get("TERMINATE_RAY"));
  grammar_current_rule_symbol_append(symbol_get("SEMICOLON"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("jump_statement"));
  grammar_current_rule_symbol_append(symbol_get("IGNORE_INTERSECTION"));
  grammar_current_rule_symbol_append(symbol_get("SEMICOLON"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("translation_unit"));
  grammar_current_rule_symbol_append(symbol_get("external_declaration"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("translation_unit"));
  grammar_current_rule_symbol_append(symbol_get("translation_unit"));
  grammar_current_rule_symbol_append(symbol_get("external_declaration"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("external_declaration"));
  grammar_current_rule_symbol_append(symbol_get("function_definition"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("external_declaration"));
  grammar_current_rule_symbol_append(symbol_get("declaration"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("external_declaration"));
  grammar_current_rule_symbol_append(symbol_get("SEMICOLON"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("function_definition"));
  grammar_current_rule_symbol_append(symbol_get("function_prototype"));
  grammar_midrule_action();
  grammar_current_rule_symbol_append(symbol_get("compound_statement_no_new_scope"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("attribute"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_BRACKET"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_BRACKET"));
  grammar_current_rule_symbol_append(symbol_get("attribute_list"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_BRACKET"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_BRACKET"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("attribute_list"));
  grammar_current_rule_symbol_append(symbol_get("single_attribute"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("attribute_list"));
  grammar_current_rule_symbol_append(symbol_get("attribute_list"));
  grammar_current_rule_symbol_append(symbol_get("COMMA"));
  grammar_current_rule_symbol_append(symbol_get("single_attribute"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("single_attribute"));
  grammar_current_rule_symbol_append(symbol_get("IDENTIFIER"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("single_attribute"));
  grammar_current_rule_symbol_append(symbol_get("IDENTIFIER"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_PAREN"));
  grammar_current_rule_symbol_append(symbol_get("constant_expression"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_PAREN"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_requirements_list"));
  grammar_current_rule_symbol_append(symbol_get("spirv_requirements_parameter"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_requirements_list"));
  grammar_current_rule_symbol_append(symbol_get("spirv_requirements_list"));
  grammar_current_rule_symbol_append(symbol_get("COMMA"));
  grammar_current_rule_symbol_append(symbol_get("spirv_requirements_parameter"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_requirements_parameter"));
  grammar_current_rule_symbol_append(symbol_get("IDENTIFIER"));
  grammar_current_rule_symbol_append(symbol_get("EQUAL"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_BRACKET"));
  grammar_current_rule_symbol_append(symbol_get("spirv_extension_list"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_BRACKET"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_requirements_parameter"));
  grammar_current_rule_symbol_append(symbol_get("IDENTIFIER"));
  grammar_current_rule_symbol_append(symbol_get("EQUAL"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_BRACKET"));
  grammar_current_rule_symbol_append(symbol_get("spirv_capability_list"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_BRACKET"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_extension_list"));
  grammar_current_rule_symbol_append(symbol_get("STRING_LITERAL"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_extension_list"));
  grammar_current_rule_symbol_append(symbol_get("spirv_extension_list"));
  grammar_current_rule_symbol_append(symbol_get("COMMA"));
  grammar_current_rule_symbol_append(symbol_get("STRING_LITERAL"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_capability_list"));
  grammar_current_rule_symbol_append(symbol_get("INTCONSTANT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_capability_list"));
  grammar_current_rule_symbol_append(symbol_get("spirv_capability_list"));
  grammar_current_rule_symbol_append(symbol_get("COMMA"));
  grammar_current_rule_symbol_append(symbol_get("INTCONSTANT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_execution_mode_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("SPIRV_EXECUTION_MODE"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_PAREN"));
  grammar_current_rule_symbol_append(symbol_get("INTCONSTANT"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_PAREN"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_execution_mode_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("SPIRV_EXECUTION_MODE"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_PAREN"));
  grammar_current_rule_symbol_append(symbol_get("spirv_requirements_list"));
  grammar_current_rule_symbol_append(symbol_get("COMMA"));
  grammar_current_rule_symbol_append(symbol_get("INTCONSTANT"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_PAREN"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_execution_mode_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("SPIRV_EXECUTION_MODE"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_PAREN"));
  grammar_current_rule_symbol_append(symbol_get("INTCONSTANT"));
  grammar_current_rule_symbol_append(symbol_get("COMMA"));
  grammar_current_rule_symbol_append(symbol_get("spirv_execution_mode_parameter_list"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_PAREN"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_execution_mode_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("SPIRV_EXECUTION_MODE"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_PAREN"));
  grammar_current_rule_symbol_append(symbol_get("spirv_requirements_list"));
  grammar_current_rule_symbol_append(symbol_get("COMMA"));
  grammar_current_rule_symbol_append(symbol_get("INTCONSTANT"));
  grammar_current_rule_symbol_append(symbol_get("COMMA"));
  grammar_current_rule_symbol_append(symbol_get("spirv_execution_mode_parameter_list"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_PAREN"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_execution_mode_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("SPIRV_EXECUTION_MODE_ID"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_PAREN"));
  grammar_current_rule_symbol_append(symbol_get("INTCONSTANT"));
  grammar_current_rule_symbol_append(symbol_get("COMMA"));
  grammar_current_rule_symbol_append(symbol_get("spirv_execution_mode_id_parameter_list"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_PAREN"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_execution_mode_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("SPIRV_EXECUTION_MODE_ID"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_PAREN"));
  grammar_current_rule_symbol_append(symbol_get("spirv_requirements_list"));
  grammar_current_rule_symbol_append(symbol_get("COMMA"));
  grammar_current_rule_symbol_append(symbol_get("INTCONSTANT"));
  grammar_current_rule_symbol_append(symbol_get("COMMA"));
  grammar_current_rule_symbol_append(symbol_get("spirv_execution_mode_id_parameter_list"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_PAREN"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_execution_mode_parameter_list"));
  grammar_current_rule_symbol_append(symbol_get("spirv_execution_mode_parameter"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_execution_mode_parameter_list"));
  grammar_current_rule_symbol_append(symbol_get("spirv_execution_mode_parameter_list"));
  grammar_current_rule_symbol_append(symbol_get("COMMA"));
  grammar_current_rule_symbol_append(symbol_get("spirv_execution_mode_parameter"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_execution_mode_parameter"));
  grammar_current_rule_symbol_append(symbol_get("FLOATCONSTANT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_execution_mode_parameter"));
  grammar_current_rule_symbol_append(symbol_get("INTCONSTANT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_execution_mode_parameter"));
  grammar_current_rule_symbol_append(symbol_get("UINTCONSTANT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_execution_mode_parameter"));
  grammar_current_rule_symbol_append(symbol_get("BOOLCONSTANT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_execution_mode_parameter"));
  grammar_current_rule_symbol_append(symbol_get("STRING_LITERAL"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_execution_mode_id_parameter_list"));
  grammar_current_rule_symbol_append(symbol_get("constant_expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_execution_mode_id_parameter_list"));
  grammar_current_rule_symbol_append(symbol_get("spirv_execution_mode_id_parameter_list"));
  grammar_current_rule_symbol_append(symbol_get("COMMA"));
  grammar_current_rule_symbol_append(symbol_get("constant_expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_storage_class_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("SPIRV_STORAGE_CLASS"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_PAREN"));
  grammar_current_rule_symbol_append(symbol_get("INTCONSTANT"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_PAREN"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_storage_class_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("SPIRV_STORAGE_CLASS"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_PAREN"));
  grammar_current_rule_symbol_append(symbol_get("spirv_requirements_list"));
  grammar_current_rule_symbol_append(symbol_get("COMMA"));
  grammar_current_rule_symbol_append(symbol_get("INTCONSTANT"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_PAREN"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_decorate_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("SPIRV_DECORATE"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_PAREN"));
  grammar_current_rule_symbol_append(symbol_get("INTCONSTANT"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_PAREN"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_decorate_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("SPIRV_DECORATE"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_PAREN"));
  grammar_current_rule_symbol_append(symbol_get("spirv_requirements_list"));
  grammar_current_rule_symbol_append(symbol_get("COMMA"));
  grammar_current_rule_symbol_append(symbol_get("INTCONSTANT"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_PAREN"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_decorate_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("SPIRV_DECORATE"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_PAREN"));
  grammar_current_rule_symbol_append(symbol_get("INTCONSTANT"));
  grammar_current_rule_symbol_append(symbol_get("COMMA"));
  grammar_current_rule_symbol_append(symbol_get("spirv_decorate_parameter_list"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_PAREN"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_decorate_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("SPIRV_DECORATE"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_PAREN"));
  grammar_current_rule_symbol_append(symbol_get("spirv_requirements_list"));
  grammar_current_rule_symbol_append(symbol_get("COMMA"));
  grammar_current_rule_symbol_append(symbol_get("INTCONSTANT"));
  grammar_current_rule_symbol_append(symbol_get("COMMA"));
  grammar_current_rule_symbol_append(symbol_get("spirv_decorate_parameter_list"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_PAREN"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_decorate_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("SPIRV_DECORATE_ID"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_PAREN"));
  grammar_current_rule_symbol_append(symbol_get("INTCONSTANT"));
  grammar_current_rule_symbol_append(symbol_get("COMMA"));
  grammar_current_rule_symbol_append(symbol_get("spirv_decorate_id_parameter_list"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_PAREN"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_decorate_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("SPIRV_DECORATE_ID"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_PAREN"));
  grammar_current_rule_symbol_append(symbol_get("spirv_requirements_list"));
  grammar_current_rule_symbol_append(symbol_get("COMMA"));
  grammar_current_rule_symbol_append(symbol_get("INTCONSTANT"));
  grammar_current_rule_symbol_append(symbol_get("COMMA"));
  grammar_current_rule_symbol_append(symbol_get("spirv_decorate_id_parameter_list"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_PAREN"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_decorate_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("SPIRV_DECORATE_STRING"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_PAREN"));
  grammar_current_rule_symbol_append(symbol_get("INTCONSTANT"));
  grammar_current_rule_symbol_append(symbol_get("COMMA"));
  grammar_current_rule_symbol_append(symbol_get("spirv_decorate_string_parameter_list"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_PAREN"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_decorate_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("SPIRV_DECORATE_STRING"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_PAREN"));
  grammar_current_rule_symbol_append(symbol_get("spirv_requirements_list"));
  grammar_current_rule_symbol_append(symbol_get("COMMA"));
  grammar_current_rule_symbol_append(symbol_get("INTCONSTANT"));
  grammar_current_rule_symbol_append(symbol_get("COMMA"));
  grammar_current_rule_symbol_append(symbol_get("spirv_decorate_string_parameter_list"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_PAREN"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_decorate_parameter_list"));
  grammar_current_rule_symbol_append(symbol_get("spirv_decorate_parameter"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_decorate_parameter_list"));
  grammar_current_rule_symbol_append(symbol_get("spirv_decorate_parameter_list"));
  grammar_current_rule_symbol_append(symbol_get("COMMA"));
  grammar_current_rule_symbol_append(symbol_get("spirv_decorate_parameter"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_decorate_parameter"));
  grammar_current_rule_symbol_append(symbol_get("FLOATCONSTANT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_decorate_parameter"));
  grammar_current_rule_symbol_append(symbol_get("INTCONSTANT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_decorate_parameter"));
  grammar_current_rule_symbol_append(symbol_get("UINTCONSTANT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_decorate_parameter"));
  grammar_current_rule_symbol_append(symbol_get("BOOLCONSTANT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_decorate_id_parameter_list"));
  grammar_current_rule_symbol_append(symbol_get("spirv_decorate_id_parameter"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_decorate_id_parameter_list"));
  grammar_current_rule_symbol_append(symbol_get("spirv_decorate_id_parameter_list"));
  grammar_current_rule_symbol_append(symbol_get("COMMA"));
  grammar_current_rule_symbol_append(symbol_get("spirv_decorate_id_parameter"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_decorate_id_parameter"));
  grammar_current_rule_symbol_append(symbol_get("variable_identifier"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_decorate_id_parameter"));
  grammar_current_rule_symbol_append(symbol_get("FLOATCONSTANT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_decorate_id_parameter"));
  grammar_current_rule_symbol_append(symbol_get("INTCONSTANT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_decorate_id_parameter"));
  grammar_current_rule_symbol_append(symbol_get("UINTCONSTANT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_decorate_id_parameter"));
  grammar_current_rule_symbol_append(symbol_get("BOOLCONSTANT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_decorate_string_parameter_list"));
  grammar_current_rule_symbol_append(symbol_get("STRING_LITERAL"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_decorate_string_parameter_list"));
  grammar_current_rule_symbol_append(symbol_get("spirv_decorate_string_parameter_list"));
  grammar_current_rule_symbol_append(symbol_get("COMMA"));
  grammar_current_rule_symbol_append(symbol_get("STRING_LITERAL"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_type_specifier"));
  grammar_current_rule_symbol_append(symbol_get("SPIRV_TYPE"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_PAREN"));
  grammar_current_rule_symbol_append(symbol_get("spirv_instruction_qualifier_list"));
  grammar_current_rule_symbol_append(symbol_get("COMMA"));
  grammar_current_rule_symbol_append(symbol_get("spirv_type_parameter_list"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_PAREN"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_type_specifier"));
  grammar_current_rule_symbol_append(symbol_get("SPIRV_TYPE"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_PAREN"));
  grammar_current_rule_symbol_append(symbol_get("spirv_requirements_list"));
  grammar_current_rule_symbol_append(symbol_get("COMMA"));
  grammar_current_rule_symbol_append(symbol_get("spirv_instruction_qualifier_list"));
  grammar_current_rule_symbol_append(symbol_get("COMMA"));
  grammar_current_rule_symbol_append(symbol_get("spirv_type_parameter_list"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_PAREN"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_type_specifier"));
  grammar_current_rule_symbol_append(symbol_get("SPIRV_TYPE"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_PAREN"));
  grammar_current_rule_symbol_append(symbol_get("spirv_instruction_qualifier_list"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_PAREN"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_type_specifier"));
  grammar_current_rule_symbol_append(symbol_get("SPIRV_TYPE"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_PAREN"));
  grammar_current_rule_symbol_append(symbol_get("spirv_requirements_list"));
  grammar_current_rule_symbol_append(symbol_get("COMMA"));
  grammar_current_rule_symbol_append(symbol_get("spirv_instruction_qualifier_list"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_PAREN"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_type_parameter_list"));
  grammar_current_rule_symbol_append(symbol_get("spirv_type_parameter"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_type_parameter_list"));
  grammar_current_rule_symbol_append(symbol_get("spirv_type_parameter_list"));
  grammar_current_rule_symbol_append(symbol_get("COMMA"));
  grammar_current_rule_symbol_append(symbol_get("spirv_type_parameter"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_type_parameter"));
  grammar_current_rule_symbol_append(symbol_get("constant_expression"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_type_parameter"));
  grammar_current_rule_symbol_append(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_instruction_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("SPIRV_INSTRUCTION"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_PAREN"));
  grammar_current_rule_symbol_append(symbol_get("spirv_instruction_qualifier_list"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_PAREN"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_instruction_qualifier"));
  grammar_current_rule_symbol_append(symbol_get("SPIRV_INSTRUCTION"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_PAREN"));
  grammar_current_rule_symbol_append(symbol_get("spirv_requirements_list"));
  grammar_current_rule_symbol_append(symbol_get("COMMA"));
  grammar_current_rule_symbol_append(symbol_get("spirv_instruction_qualifier_list"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_PAREN"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_instruction_qualifier_list"));
  grammar_current_rule_symbol_append(symbol_get("spirv_instruction_qualifier_id"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_instruction_qualifier_list"));
  grammar_current_rule_symbol_append(symbol_get("spirv_instruction_qualifier_list"));
  grammar_current_rule_symbol_append(symbol_get("COMMA"));
  grammar_current_rule_symbol_append(symbol_get("spirv_instruction_qualifier_id"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_instruction_qualifier_id"));
  grammar_current_rule_symbol_append(symbol_get("IDENTIFIER"));
  grammar_current_rule_symbol_append(symbol_get("EQUAL"));
  grammar_current_rule_symbol_append(symbol_get("STRING_LITERAL"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("spirv_instruction_qualifier_id"));
  grammar_current_rule_symbol_append(symbol_get("IDENTIFIER"));
  grammar_current_rule_symbol_append(symbol_get("EQUAL"));
  grammar_current_rule_symbol_append(symbol_get("INTCONSTANT"));
  grammar_current_rule_end();
}
