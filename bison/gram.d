module bison.gram;
import bison;

item_number[] ritem;
int nritems = 0;

rule[] rules;
rule_number nrules = rule_number(0);

symbol[] symbols;
int nsyms = 0;
int ntokens = 1;
int nnterms = 0;

struct item_number {
  int _;
  alias _ this;
}

struct item_index {
  size_t _;
  alias _ this;
}

struct rule_number {
  int _;
  alias _ this;
}

struct rule {
  rule_number number;
  sym_content lhs;
  item_number[] rhs;
}
