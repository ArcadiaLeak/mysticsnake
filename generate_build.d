module genmake;

import std.array;
import std.algorithm.iteration;
import std.conv;
import std.file;
import std.stdio : writeln;

string fromFilepaths(Range)(string libname, Range filepaths) {
  return i"artifacts/libmysticsnake_$(libname).a: $(filepaths.join(" "))\n".text ~
    "\t" ~ "dmd -of=$@ -debug $^ -lib -dip1000";
}

void main() {
  string Makefile;

  foreach (libname; ["glslang"]) {
    auto filepaths = libname
      .dirEntries("*.d", SpanMode.breadth, false)
      .map!(e => e.name);

    Makefile ~= fromFilepaths(libname, filepaths);
  }

  write("Makefile", Makefile);
}
