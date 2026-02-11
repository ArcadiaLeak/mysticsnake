module bison.closure;
import bison;

import std.range.interfaces;

item_index[] itemset;
size_t nitemset;

bool[] ruleset;

bool[][] fderives;
bool[][] firsts;

void closure_new(int n) {
  itemset = new item_index[n];
  ruleset = new bool[nrules];


  set_fderives();
}

void set_fderives() {
  import std.array;
  import std.range;

  bool[] buffer = new bool[nnterms * nrules];
  fderives = buffer.chunks(nrules).array;

  set_firsts();

  for (int i = ntokens; i < nsyms; ++i)
    for (int j = ntokens; j < nsyms; ++j)
      if (firsts[i - ntokens][j - ntokens])
        for (int k = 0; derives[j - ntokens][k]; ++k)
          fderives[i - ntokens][derives[j - ntokens][k].front.number] = true;

  if (TRACE_SETS)
    print_fderives();
}

void set_firsts() {
  import std.array;
  import std.range;

  bool[] buffer = new bool[nnterms * nnterms];
  firsts = buffer.chunks(nnterms).array;
  
  for (int i = ntokens; i < nsyms; ++i)
    for (int j = 0; derives[i - ntokens][j]; ++j) {
      item_number sym = derives[i - ntokens][j].front.rhs.front;
      if(sym >= ntokens)
        firsts[i - ntokens][sym - ntokens] = true;
    }
  
  for (size_t i = 0; i < firsts.length; i++)
    for (size_t j = 0; j < firsts.length; j++)
      if (firsts[j][i])
        firsts[j][] |= firsts[i][];

  for (size_t i = 0; i < firsts.length; i++)
    firsts[i][i] = true;

  if (TRACE_SETS)
    print_firsts();
}

void print_firsts() {
  import std.stdio;

  write("FIRSTS\n");

  for (int i = ntokens; i < nsyms; ++i) {
    writef("  %s firsts\n", symbols[i].tag);
    foreach (j, flag; firsts[i - ntokens])
      if (flag) writef("    %s\n", symbols[j + ntokens].tag);
  }

  write("\n\n");
}

void print_fderives() {
  import std.stdio;

  write("FDERIVES\n");

  for (int i = ntokens; i < nsyms; ++i) {
    writef("  %s derives\n", symbols[i].tag);
    foreach (r, flag; fderives[i - ntokens])
      if (flag) {
        writef("    %3d ", r);
        if (rules[r].rhs[0] >= 0)
          for (int k = 0; rules[r].rhs[k] >= 0; k++)
            writef(" %s", symbols[rules[r].rhs[k]].tag);
        else
          writef(" %s", cast(dchar) 0x03b5);
        write("\n");
      }
  }

  write("\n\n");
}

void closure(const state s) {
  if (TRACE_CLOSURE)
    closure_print("input", s.items);

  ruleset[] = 0;

  foreach (c; s.items)
    if (ritem[c] >= ntokens)
      ruleset[] |= fderives[ritem[c] - ntokens][];

  nitemset = 0;
  size_t c = 0;

  foreach (ruleno, flag; ruleset)
    if (flag) {
      size_t itemno = ritem.length - rules[ruleno].rhs.length;
      while (c < s.items.length && s.items[c] < itemno) {
        itemset[nitemset] = s.items[c];
        nitemset++;
        c++;
      }
      itemset[nitemset] = itemno;
      nitemset++;
    }

  while (c < s.items.length) {
    itemset[nitemset] = s.items[c];
    nitemset++;
    c++;
  }

  if (TRACE_CLOSURE)
    closure_print("output", itemset[0..nitemset]);
}

void closure_print(string title, const item_index[] arr) {
  import std.stdio;

  writef("Closure: %s\n", title);

  foreach (i; arr) {
    writef("  %2d: .", i);
    item_number[] rp = ritem[i..$];
    size_t r;
    for (r = 0; rp[r] >= 0; r++)
      writef(" %s", symbols[rp[r]].tag);
    writef("  (rule %d)\n", -1 - rp[r]);
  }

  write("\n\n");
}
