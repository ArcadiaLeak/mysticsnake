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
        firsts[j][] = firsts[j][] || firsts[i][];

  for (size_t i = 0; i < firsts.length; i++)
    firsts[i][i] = true;
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
  import std.range.primitives;
  import std.stdio;

  write("FDERIVES\n");

  for (int i = ntokens; i < nsyms; ++i) {
    writef("  %s derives\n", symbols[i].tag);
    foreach (r, flag; fderives[i - ntokens])
      if (flag) {
        writef("    %3d ", r);
        if (rules[r].rhs.front >= 0)
          for (item_number[] rhsp = rules[r].rhs; rhsp.front >= 0; rhsp.popFront)
            writef(" %s", symbols[rhsp.front].tag);
        else
          writef(" %s", cast(dchar) 0x03b5);
        write("\n");
      }
  }

  write("\n\n");
}

void closure(const item_index[] core) {
  ruleset[] = 0;

  foreach (c; core)
    if (ritem[c] >= ntokens)
      ruleset[] = ruleset[] || fderives[ritem[c] - ntokens][];

  nitemset = 0;
  size_t c = 0;

  foreach (ruleno, rul; ruleset) {
    size_t itemno = ritem.length - rules[ruleno].rhs.length;
    while (c < core.length && core[c] < itemno) {
      itemset[nitemset] = core[c];
      nitemset++;
      c++;
    }
    itemset[nitemset] = itemno;
    nitemset++;
  }

  while (c < core.length) {
    itemset[nitemset] = core[c];
    nitemset++;
    c++;
  }
}
