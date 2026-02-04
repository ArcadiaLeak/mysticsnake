module genmake;

import std.array;
import std.algorithm.iteration;
import std.conv;
import std.file;
import std.stdio : writeln;
import std.path;
import std.string;

enum string prjname = "mysticsnake";

void main() {
  string Makefile;

  immutable string[] libtargets = ["glslang"];

  Makefile ~= "all:";

  foreach (target; libtargets) {
    Makefile ~= i" build/$(target)".text;
  }

  Makefile ~= "\n";

  foreach (libname; libtargets) {
    string srcPaths = libname
      .dirEntries("*.d", SpanMode.breadth, false)
      .map!(e => e.name)
      .join(" ");

    Makefile ~= "\n" ~ i"build/$(libname): $(srcPaths)\n".text ~
      "\t" ~ "dmd -dip1000 -debug $^ -of=$@\n";
  }

  write("Makefile", Makefile);
}
