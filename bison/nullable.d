module bison.nullable;
import bison;

struct rule_list {
  rule_list[] next;
  rule[] value;
}

bool[] nullable;

void nullable_compute() {
  nullable = new bool[nnterms];

  size_t[] rcount = new size_t[nrules];
  rule_list[][] rsets = new rule_list[][nnterms];
  rule_list[] relts = new rule_list[nritems + nnterms + 1];

  symbol_number[] squeue = new symbol_number[nnterms];
  symbol_number[] s2 = squeue;
  {
    rule_list[] p = relts;
    foreach (ruleno, r; rules)
      if (r.rhs[0] >= 0) {
        bool any_tokens = false;
        foreach (rp; r.rhs)
          if (rp < 0) {
            any_tokens = true;
            break;
          }

        if (!any_tokens)
          foreach (rp; r.rhs) {
            rcount[ruleno]++;
            p[0].next = rsets[rp - ntokens];
            p[0].value = rules[ruleno..$];
            rsets[rp - ntokens] = p;
            p = p[1..$];
          }
      } else {
        if (!nullable[r.lhs.number - ntokens]) {
          nullable[r.lhs.number - ntokens] = true;
          s2[0] = r.lhs.number;
          s2 = s2[1..$];
        }
      }
  }

  symbol_number[] s1 = squeue;
  while (s1.length > s2.length) {
    rule_list[] p = rsets[s1[0] - ntokens];
    s1 = s1[1..$];
    while (p) {
      rule[] r = p[0].value;
      if (--rcount[r[0].number] == 0)
        if (!nullable[r[0].lhs.number - ntokens]) {
          nullable[r[0].lhs.number - ntokens] = true;
          s2[0] = r[0].lhs.number;
          s2 = s2[1..$];
        }
      p = p[0].next;
    }
  }

  if (TRACE_AUTOMATON)
    nullable_print;
}

void nullable_print() {
  import std.stdio;
  write("NULLABLE\n");
  foreach (i; ntokens..nsyms)
    writef(
      "  %s: %s\n",
      symbols[i].tag,
      nullable[i - ntokens] ? "yes" : "no"
    );
  write("\n\n");
}
