import { walk } from "jsr:@std/fs/walk";

const prjname = "mysticsnake";
const libtargets = ["glslang"];

let Makefile;

Makefile += "all:";
for (const target of libtargets) {
  Makefile += ` build/${target}`;
}
Makefile += "\n";

for (const libname of libtargets) {
  const srcEntries = await Array.fromAsync(walk(libname, { exts: ["d"] }));
  const srcPaths = srcEntries.map(e => e.path).join(" ");

  Makefile += "\n" + `build/${libname}: ${srcPaths}\n` +
    "\t" + "dmd -dip1000 -debug $^ -of=$@\n";
}

Deno.writeTextFile("Makefile", Makefile);
