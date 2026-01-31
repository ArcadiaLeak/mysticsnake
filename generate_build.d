module genmake;

import std.array;
import std.algorithm.iteration;
import std.conv;
import std.file;
import std.stdio : writeln;
import std.path;
import std.string;

void main() {
  string Makefile;

  immutable string[] libtargets = ["glslang"];

  Makefile ~= "all: build/libmysticsnake_glslang.a\n";

  foreach (libname; libtargets) {
    string[] srcPaths = libname
      .dirEntries("*.d", SpanMode.breadth, false)
      .map!(e => e.name)
      .array;
    string[] hdrPaths;
    string[] objPaths;

    foreach (srcPath; srcPaths) {
      string hdrPath = "build/interface/" ~ srcPath.setExtension(".di");
      hdrPaths ~= hdrPath;

      Makefile ~= "\n" ~ i"$(hdrPath): $(srcPath)\n".text ~
        "\t" ~ "dmd $^ -Hf=$@ -o- -dip1000\n";
    }

    foreach (srcPath; srcPaths) {
      string objPath = "build/" ~ srcPath.setExtension(".o");
      objPaths ~= objPath;

      string dependencyPath(string hdrPath) {
        if(
          hdrPath.chompPrefix("build/interface/").stripExtension ==
          srcPath.stripExtension
        ) {
          return srcPath;
        }

        return hdrPath;
      }

      string dependencyStr = hdrPaths.map!(dependencyPath).join(" ");

      Makefile ~= "\n" ~ i"$(objPath): $(dependencyStr)\n".text ~
        "\t" ~ "dmd $^ -of=$@ -c -dip1000\n";
    }

    Makefile ~= "\n" ~ i"build/libmysticsnake_$(libname).a: $(objPaths.join(" "))\n".text ~
      "\t" ~ "dmd $^ -of=$@ -debug -lib -dip1000\n";
  }

  write("Makefile", Makefile);
}
