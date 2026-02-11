module bison;

import bison.glslgram;

package import bison.closure;
package import bison.derives;
package import bison.gram;
package import bison.lr0;
package import bison.reader;
package import bison.symlist;
package import bison.symtab;

static this() {
  gram_init_pre();
  glslgram();
  gram_init_post();
  derives_compute();
  generate_states();
}

void main() {
  import std.stdio;

  writeln(ntokens);
  writeln(nnterms);
  writeln(nrules);
  writeln(nritems);
}
