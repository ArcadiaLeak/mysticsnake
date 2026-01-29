module glslang.include.common;

struct TSourceLoc {
  string name;
  int string_;
  int line;
  int column;

  void init(int stringNum) @safe {
    string_ = stringNum;
  }
}

struct TPragmaTable {}
