module glslang.machine_independent.intermediate;

import std.container.dlist;
import glslang;

struct TCall {
  this(string pCaller, string pCallee) {
    caller = pCaller;
    callee = pCallee;
    visited = false;
    currentPath = false;
    errorGiven = false;
  }

  string caller;
  string callee;
  bool visited;
  bool currentPath;
  bool errorGiven;
  int calleeBodyPosition;
}

class TIntermediate {
  protected {
    const EShLanguage language;
    string entryPointName;
    string entryPointMangledName;
    DList!TCall callGraph;

    EProfile profile;
    int version_;
    SpvVersion spvVersion;
  }

  this(EShLanguage l, int v = 0, EProfile p = EProfile.ENoProfile) {
    language = l;
  }
}
