module bison.derives;
import bison;

rule[][][] derives;

void derives_compute() {
  struct rule_list {
    rule_list[] next;
    rule[] value;
  }

  rule_list[][] dset = new rule_list[][nnterms];
  rule_list[] delts = new rule_list[nrules];

  foreach_reverse (r; 0..nrules) {
    symbol_number lhs = rules[r].lhs.number;
    rule_list[] p = delts[r..$];

    p[0].next = dset[lhs - ntokens];
    p[0].value = rules[r..$];

    dset[lhs - ntokens] = p;
  }

  derives = new rule[][][nnterms];
  rule[][] dvs_storage = new rule[][nnterms + nrules];

  foreach (i; ntokens..nsyms) {
    rule_list[] p = dset[i - ntokens];
    derives[i - ntokens] = dvs_storage;

    while (p) {
      dvs_storage[0] = p[0].value;
      dvs_storage = dvs_storage[1..$];
      p = p[0].next;
    }

    dvs_storage[0] = null;
    dvs_storage = dvs_storage[1..$];
  }

  if (TRACE_SETS)
    print_derives();
}

void print_derives() {
  import std.range.primitives;
  import std.stdio;

  write("DERIVES\n");

  foreach (i; ntokens..nsyms) {
    writef("  %s derives\n", symbols[i].tag);
    for (rule[][] rp = derives[i - ntokens]; rp.front; rp.popFront) {
      writef("    %3d ", rp.front.front.number);
      rp.front.front.rule_rhs_print;
      write("\n");
    }
  }

  write("\n\n");
}
