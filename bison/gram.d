module bison.gram;
import bison;

item_number_t[] ritem;
int nritems = 0;

rule_t[] rules;
rule_number_t nrules = 0;

symbol_t[] symbols;
int nsyms = 0;
int ntokens = 1;
int nnterms = 0;

alias item_number_t = int;

alias item_index_t = uint;

alias rule_number_t = int;

struct rule_t {
  rule_number_t number;
  sym_content_t lhs;
  item_number_t[] rhs;
}
