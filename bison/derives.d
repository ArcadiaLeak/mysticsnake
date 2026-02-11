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

  for (int r = nrules - 1; r >= 0; --r) {
    symbol_number lhs = rules[r].lhs.number;
    rule_list[] p = delts[r..$];

    p[0].next = dset[lhs - ntokens];
    p[0].value = rules[r..$];

    dset[lhs - ntokens] = p;
  }

  derives = new rule[][][nnterms];
  rule[][] dvs_storage = new rule[][nnterms + nrules];

  for (int i = ntokens; i < nsyms; ++i) {
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

  for (int i = ntokens; i < nsyms; ++i) {
    writef("  %s derives\n", symbols[i].tag);
    for (rule[][] rp = derives[i - ntokens]; rp.front; rp.popFront) {
      writef("    %3d ", rp.front.front.number);
      if (rp.front.front.rhs.front >= 0)
        for (item_number[] rhsp = rp.front.front.rhs; rhsp.front >= 0; rhsp.popFront)
          writef(" %s", symbols[rhsp.front].tag);
      else
        writef(" %s", cast(dchar) 0x03b5);
      write("\n");
    }
  }

  write("\n\n");
}
