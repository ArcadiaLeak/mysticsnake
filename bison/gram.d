module bison.gram;
import bison;

item_number[] ritem;
int nritems = 0;

rule[] rules;
rule_number nrules = 0;

symbol[] symbols;
int nsyms = 0;
int ntokens = 1;
int nnterms = 0;

alias item_number = int;

alias item_index = uint;

alias rule_number = int;

struct rule {
  rule_number number;
  sym_content lhs;
  item_number[] rhs;
}
