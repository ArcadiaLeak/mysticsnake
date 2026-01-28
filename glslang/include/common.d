module glslang.include.common;

struct TSourceLoc {
  string name;
  int string_;
  int line;
  int column;

  void init() @safe {
    name = null;
    string_ = 0;
    line = 0;
    column = 0;
  }

  void init(int stringNum) @safe {
    init();
    string_ = stringNum;
  }
}

struct TPragmaTable {}
