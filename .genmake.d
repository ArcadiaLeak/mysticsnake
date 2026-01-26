module genmake;

import std.array;
import std.algorithm.iteration;
import std.conv;
import std.file;
import std.stdio : writeln;

void main() {

string glslangEntries = "glslang".dirEntries("*.d", SpanMode.breadth, false)
	.map!(e => e.name)
	.join(" ");

string Makefile = i`

artifacts/mysticsnake: $(glslangEntries)
	dmd -od=artifacts -of=$@ -debug $^ -main

`.text;

write("Makefile", Makefile);

}
