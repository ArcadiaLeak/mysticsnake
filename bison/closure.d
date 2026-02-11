module bison.closure;
import bison;

bool[][] fderives;
bool[][] firsts;

void closure_new(int n) {
  set_fderives();
}

void set_fderives() {
  import std.range.primitives;

  bool[] buffer = new bool[nnterms * nrules];
  fderives = new bool[][nnterms];
  {
    size_t j;
    for (size_t i = 0; i < nnterms; i++) {
      j = i + 1;
      fderives[i] = buffer[i * nrules..j * nrules];
    }
  }

  set_firsts(firsts);

  for (symbol_number_t i = ntokens; i < nsyms; ++i)
    for (symbol_number_t j = ntokens; j < nsyms; ++j)
      if (firsts[i - ntokens][j - ntokens])
        for (rule_number_t k = 0; derives[j - ntokens][k]; ++k)
          fderives[i - ntokens][derives[j - ntokens][k].front.number] = true;
}

void set_firsts(out bool[][] firsts) {
  import std.range.primitives;

  bool[] buffer = new bool[nnterms * nnterms];
  firsts = new bool[][nnterms];
  {
    size_t j;
    for (size_t i = 0; i < nnterms; i++) {
      j = i + 1;
      firsts[i] = buffer[i * nnterms..j * nnterms];
    }
  }
  
  for (symbol_number_t i = ntokens; i < nsyms; ++i)
    for (symbol_number_t j = 0; derives[i - ntokens][j]; ++j) {
      item_number_t sym = derives[i - ntokens][j].front.rhs.front;
      if(sym >= ntokens)
        firsts[i - ntokens][sym - ntokens] = true;
    }
  
  for (size_t i = 0; i < firsts.length; i++)
    for (size_t j = 0; j < firsts.length; j++)
      if (firsts[j][i])
        for (size_t k = 0; k < firsts[j].length; k++)
          firsts[j][k] = firsts[j][k] || firsts[i][k];

  for (size_t i = 0; i < firsts.length; i++)
    firsts[i][i] = true;
}

void print_firsts(in bool[][] firsts) {
  import std.stdio;

  write("FIRSTS\n");

  for (symbol_number_t i = ntokens; i < nsyms; ++i) {
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

  for (symbol_number_t i = ntokens; i < nsyms; ++i) {
    writef("  %s derives\n", symbols[i].tag);
    foreach (r, flag; fderives[i - ntokens])
      if (flag) {
        writef("    %3d ", r);
        if (rules[r].rhs.front >= 0)
          for (item_number_t[] rhsp = rules[r].rhs; rhsp.front >= 0; rhsp.popFront)
            writef(" %s", symbols[rhsp.front].tag);
        else
          writef(" %s", cast(dchar) 0x03b5);
        write("\n");
      }
  }

  write("\n\n");
}
