module bison;

private import bison.glslgram;
package import bison.closure;
package import bison.derives;
package import bison.gram;
package import bison.lr0;
package import bison.reader;
package import bison.state;
package import bison.symlist;
package import bison.symtab;

enum bool TRACE_SETS = 0;
enum bool TRACE_CLOSURE = 0;
enum bool TRACE_AUTOMATON = 0;

void main() {
  gram_init_pre();
  glslgram();
  gram_init_post();
  derives_compute();
  generate_states();

  {
    import std.stdio;

    writeln(ntokens);
    writeln(nnterms);
    writeln(nrules);
    writeln(nritems);
  }
}
