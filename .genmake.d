module genmake;

import std.array;
import std.algorithm.iteration;
import std.conv;
import std.file;
import std.stdio : writeln;

void main() {

string glslangSources = "glslang"
	.dirEntries("*.d", SpanMode.breadth, false)
	.map!(e => e.name)
	.join(" ");

string Makefile = i`

artifacts/libmysticsnake_glslang.a: $(glslangSources)
	dmd -of=$@ -debug $^ -lib

`.text;

write("Makefile", Makefile);

}
