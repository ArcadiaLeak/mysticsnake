module glslang.machine_independent.initialize;

import glslang;

import std.traits;

class TBuiltInParseables {
  protected {
    string commonBuiltins;
    string[EnumMembers!glslang_stage_t.length] stageBuiltins;
  }

  abstract void initialize(
    int version_, glslang_profile_t, in SpvVersion spvVersion);
  abstract void initialize(
    TBuiltInResource resources, int version_, glslang_profile_t,
    in SpvVersion spvVersion, glslang_stage_t);
}

class TBuiltIns : TBuiltInParseables {
  protected {
    string[5] postfixes;
    string[TBasicType.EbtNumTypes] prefixes;
    int[TSamplerDim.EsdNumDims] dimMap;
  }

  override void initialize(
    int version_, glslang_profile_t,
    in SpvVersion spvVersion
  ) {
    throw new Exception("unimplemented");
  }

  override void initialize(
    TBuiltInResource resources, int version_, glslang_profile_t,
    in SpvVersion spvVersion, glslang_stage_t
  ) {
    throw new Exception("unimplemented");
  }
}
