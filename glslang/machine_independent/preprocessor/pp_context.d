module glslang.machine_independent.preprocessor.pp_context;

import glslang;

class TPpContext {
  static class tInput {
    protected {
      bool done;
      TPpContext pp;
    }

    this(TPpContext p) { done = false; pp = p; }
  }

  static class tStringInput : tInput {
    protected TInputScanner input;

    this(TPpContext pp, TInputScanner i) { super(pp); input = i; }
  }

  protected {
    string preamble;
    string[] strings;
    int currentString;

    int previous_token;
    TParseContextBase parseContext;

    enum int maxIfNesting = 65;

    bool ifdepth;
    bool[maxIfNesting] elseSeen;
    int elsetracker;

    TShader.Includer includer;

    bool inComment;
    string rootFileName;
    string currentSourceFile;

    bool disableEscapeSequences;
    bool inElseSkip;
  }
  
  this(
    TParseContextBase pc, string rootFileName, TShader.Includer inclr
  ) @safe {
    preamble = null; strings = null; previous_token = '\n'; parseContext = pc;
    includer = inclr; inComment = false; this.rootFileName = rootFileName;
    currentSourceFile = rootFileName; disableEscapeSequences = false;
    inElseSkip = false;

    ifdepth = 0;
    for (elsetracker = 0; elsetracker < maxIfNesting; elsetracker++)
      elseSeen[elsetracker] = false;
    elsetracker = 0;
  }
}
