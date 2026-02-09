import { walk } from "jsr:@std/fs/walk";

const targets = ["bison", "glslang"];

let Makefile = "";

Makefile += "all:";
for (const target of targets) {
  Makefile += ` build/lib${target}.a`;
}
Makefile += "\n";

for (const target of targets) {
  const srcEntries = await Array.fromAsync(walk(target, { exts: ["d"] }));
  const srcPaths = srcEntries.map(e => e.path).join(" ");

  Makefile += "\n" + `build/lib${target}.a: ${srcPaths}\n` +
    "\t" + "dmd -debug -lib -of=$@ $^\n";
}

Deno.writeTextFile("Makefile", Makefile);
