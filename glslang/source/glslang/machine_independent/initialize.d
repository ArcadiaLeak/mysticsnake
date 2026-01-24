module glslang.machine_independent.initialize;

import glslang;

import std.traits;

class TBuiltInParseables {
  protected {
    string commonBuiltins;
    string[EnumMembers!glslang_stage_t.length] stageBuiltins;
  }
}
