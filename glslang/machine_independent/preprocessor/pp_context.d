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

    int getch() {
      int ch = input.takeFront;

      if (ch == '\\') {
        do {
          if (input.front == '\r' || input.front == '\n') {
            bool allowed = pp.parseContext.lineContinuationCheck(
              input.getSourceLoc, pp.inComment);
            if (!allowed && pp.inComment)
              return '\\';
            
            ch = input.front;
            int nextch = input.front;
            if (ch == '\r' && nextch == '\n')
              ch = input.front;
            else
              ch = nextch;
          } else
            return '\\';
        } while (ch == '\\');
      }

      if (ch == '\r' || ch == '\n') {
        if (ch == '\r' && input.front == '\n')
          return input.front;
        return '\n';
      }

      return ch;
    }

    int scan(TPpToken ppToken) {
      int AlreadyComplained = 0;
      int len = 0;
      int ch = 0;
      int ii = 0;
      ulong ival = 0;

      bool floatingPointChar(int ch) {
        return ch == '.' || ch == 'e' || ch == 'E' ||
          ch == 'f' || ch == 'F' ||
          ch == 'h' || ch == 'H';
      }

      static immutable string[] Int64_Extensions = [
        E_GL_ARB_gpu_shader_int64,
        E_GL_EXT_shader_explicit_arithmetic_types,
        E_GL_NV_gpu_shader5,
        E_GL_EXT_shader_explicit_arithmetic_types_int64
      ];

      static immutable string[] Int16_Extensions = [
        E_GL_AMD_gpu_shader_int16,
        E_GL_EXT_shader_explicit_arithmetic_types,
        E_GL_EXT_shader_explicit_arithmetic_types_int16
      ];

      ppToken.clear();
      ch = getch();
      while (true) {
        while (ch == ' ' || ch == '\t') {
          ppToken.space = true;
          ch = getch();
        }

        ppToken.loc = pp.parseContext.getCurrentLoc;
        len = 0;
        switch (ch) {
          default:
            if (ch > EFixedAtoms.PpAtomMaxSingle)
              ch = EFixedAtoms.PpAtomBadToken;
            return ch;

          case 'A': case 'B': case 'C': case 'D': case 'E':
          case 'F': case 'G': case 'H': case 'I': case 'J':
          case 'K': case 'L': case 'M': case 'N': case 'O':
          case 'P': case 'Q': case 'R': case 'S': case 'T':
          case 'U': case 'V': case 'W': case 'X': case 'Y':
          case 'Z': case '_':
          case 'a': case 'b': case 'c': case 'd': case 'e':
          case 'f': case 'g': case 'h': case 'i': case 'j':
          case 'k': case 'l': case 'm': case 'n': case 'o':
          case 'p': case 'q': case 'r': case 's': case 't':
          case 'u': case 'v': case 'w': case 'x': case 'y':
          case 'z':
            do {
              if (len < MaxTokenLength) {
                ppToken.name[len++] = cast(char) ch;
                ch = getch();
              } else {
                if (!AlreadyComplained) {
                  pp.parseContext.ppError(ppToken.loc, "name too long", "", "");
                  AlreadyComplained = 1;
                }
                ch = getch();
              }
            } while (
              (ch >= 'a' && ch <= 'z') ||
              (ch >= 'A' && ch <= 'Z') ||
              (ch >= '0' && ch <= '9') ||
              ch == '_'
            );

            if (len == 0) continue;

            ppToken.name[len] = '\0';
            ungetch();
            return EFixedAtoms.PpAtomIdentifier;
        }

        ch = getch();
      }
    }
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

class TPpToken {
  string name;
  union {
    int val;
    double dval;
    long i64val;
  }
  bool space;
  bool fullyExpanded;
  TSourceLoc loc;

  void clear() {
    space = false;
    i64val = 0;
    loc.init();
    name = "";
    fullyExpanded = false;
  }
}
