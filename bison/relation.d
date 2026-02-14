module bison.relation;
import bison;

void relation_print_default(size_t i) {
  import std.stdio;
  writef("%3d", i);
}

void relation_print(alias Print, Relation)(string title, Relation r) {
  import std.stdio;
  writef("%s:\n", title);
  foreach (i; 0..r.length)
    if (r[i]) {
      write("    ");
      Print(i);
      write(":");
      for (size_t j = 0; r[i][j] != -1; ++j) {
        write(" ");
        Print(r[i][j]);
      }
      write("\n");
    }
  write("\n");
}

void relation_digraph(Relation)(Relation r, bool[][] function_) {
  size_t infinity = r.length + 2;
  size_t[] indexes = new size_t[r.length + 1];
  size_t[] vertices = new size_t[r.length + 1];
  size_t top = 0;

  Relation R = r;
  bool[][] F = function_;

  void traverse(size_t i) {
    vertices[++top] = i;
    size_t height = indexes[i] = top;

    if (R[i])
      for (size_t j = 0; R[i][j] != -1; ++j) {
        if (indexes[R[i][j]] == 0)
          traverse(R[i][j]);
        
        if (indexes[i] > indexes[R[i][j]])
          indexes[i] = indexes[R[i][j]];

        F[i][] |= F[R[i][j]][];
      }

    if (indexes[i] == height)
      while (true) {
        size_t j = vertices[top--];
        indexes[j] = infinity;

        if (i == j)
          break;

        F[j][] = F[i][];
      }
  }

  foreach (k; 0..r.length)
    if (indexes[k] == 0 && R[k])
      traverse(k);
}

void relation_transpose(Relation)(Relation r) {
  if (TRACE_SETS)
    relation_print!relation_print_default("relation_transpose", r);
}
