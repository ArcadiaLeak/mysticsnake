module bison.derives;
import bison;

rule[][][] derives;

void derives_compute() {
  import std.range;

  struct rule_list {
    rule_list[] next;
    rule[] value;
  }

  rule_list[][] dset = new rule_list[][nnterms];
  rule_list[] delts = new rule_list[nrules];

  for (rule_number r = nrules - 1; r >= 0; --r) {
    symbol_number lhs = rules[r].lhs.number;
    rule_list[] p = delts[r..$];

    p.front.next = dset[lhs - ntokens];
    p.front.value = rules[r..$];

    dset[lhs - ntokens] = p;
  }

  derives = new rule[][][nnterms];
  rule[][] q = new rule[][nnterms + nrules];

  for (symbol_number i = ntokens; i < nsyms; ++i) {
    rule_list[] p = dset[i - ntokens];
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

  for (symbol_number i = ntokens; i < nsyms; ++i) {
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
