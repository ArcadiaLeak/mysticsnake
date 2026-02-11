module bison.derives;
import bison;

rule_t[][][] derives;

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
