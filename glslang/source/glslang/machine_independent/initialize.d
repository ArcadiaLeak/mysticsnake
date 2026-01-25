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

  this() {
    prefixes[TBasicType.EbtFloat] =  "";
    prefixes[TBasicType.EbtInt] = "i";
    prefixes[TBasicType.EbtUint] = "u";
    prefixes[TBasicType.EbtFloat16] = "f16";
    prefixes[TBasicType.EbtInt8] = "i8";
    prefixes[TBasicType.EbtUint8] = "u8";
    prefixes[TBasicType.EbtInt16] = "i16";
    prefixes[TBasicType.EbtUint16] = "u16";
    prefixes[TBasicType.EbtInt64] = "i64";
    prefixes[TBasicType.EbtUint64] = "u64";

    postfixes[2] = "2";
    postfixes[3] = "3";
    postfixes[4] = "4";

    dimMap[TSamplerDim.Esd2D] = 2;
    dimMap[TSamplerDim.Esd3D] = 3;
    dimMap[TSamplerDim.EsdCube] = 3;
    dimMap[TSamplerDim.Esd1D] = 1;
    dimMap[TSamplerDim.EsdRect] = 2;
    dimMap[TSamplerDim.EsdBuffer] = 1;
    dimMap[TSamplerDim.EsdSubpass] = 2;
    dimMap[TSamplerDim.EsdAttachmentEXT] = 2;
  }

  void addTabledBuiltins(
    int version_, glslang_profile_t profile,
    in SpvVersion spvVersion
  ) {
    auto foreachFunction(string decls, const(BuiltInFunction[]) functions) {

    }
  }

  override void initialize(
    int version_, glslang_profile_t profile,
    in SpvVersion spvVersion
  ) {
    addTabledBuiltins(version_, profile, spvVersion);
  }

  override void initialize(
    TBuiltInResource resources, int version_, glslang_profile_t,
    in SpvVersion spvVersion, glslang_stage_t
  ) {
    throw new Exception("unimplemented");
  }
}

struct BuiltInFunction {
  TOperator op;
  string name;
  int numArguments;
}
