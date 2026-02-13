module bison.relation;
import bison;

void relation_print(alias Print, R)(string title, R r) {
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


