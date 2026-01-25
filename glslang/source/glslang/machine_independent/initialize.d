module glslang.machine_independent.initialize;

import glslang;

import std.range;
import std.traits;

enum string[] TypeString = [
  "bool", "bvec2", "bvec3", "bvec4",
  "float", "vec2", "vec3", "vec4",
  "int", "ivec2", "ivec3", "ivec4",
  "uint", "uvec2", "uvec3", "uvec4",
];
enum int TypeStringCount = TypeString.length;
enum int TypeStringRowShift = 2;
enum int TypeStringColumnMask = (1 << TypeStringRowShift) - 1;
enum int TypeStringScalarMask = ~TypeStringColumnMask;

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
    auto foreachFunction(ref string decls, const(BuiltInFunction[]) functions) {
      foreach (const ref fn; functions) {
        if (ValidVersion(fn, version_, profile, spvVersion))
          AddTabledBuiltin(decls, fn);
      }
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
  ArgType types;
  ArgClass classes;
  const(Versioning[]) versioning;
}

enum ArgType {
  TypeB = 1 << 0,
  TypeF = 1 << 1,
  TypeI = 1 << 2,
  TypeU = 1 << 3,
  TypeF16 = 1 << 4,
  TypeF64 = 1 << 5,
  TypeI8 = 1 << 6,
  TypeI16 = 1 << 7,
  TypeI64 = 1 << 8,
  TypeU8 = 1 << 9,
  TypeU16 = 1 << 10,
  TypeU64 = 1 << 11,
}

enum ArgClass {
  ClassRegular = 0,
  ClassLS = 1 << 0,
  ClassXLS = 1 << 1,
  ClassLS2 = 1 << 2,
  ClassFS = 1 << 3,
  ClassFS2 = 1 << 4,
  ClassLO = 1 << 5,
  ClassB = 1 << 6,
  ClassLB = 1 << 7,
  ClassV1 = 1 << 8,
  ClassFIO = 1 << 9,
  ClassRS = 1 << 10,
  ClassNS = 1 << 11,
  ClassCVN = 1 << 12,
  ClassFO = 1 << 13,
  ClassV3 = 1 << 14,
}

struct Versioning {
  glslang_profile_t profiles;
  int minExtendedVersion;
  int minCoreVersion;
  int numExtensions;
  string[] extensions;
}

bool ValidVersion(
  in BuiltInFunction func, int version_,
  glslang_profile_t profile, in SpvVersion
) {
  if (func.versioning.empty) return true;

  foreach (const ref v; func.versioning) {
    if ((v.profiles & profile) != 0) {
      if (v.minCoreVersion <= version_ ||
        (v.numExtensions > 0 && v.minExtendedVersion <= version_))
        return true;
    }
  }

  return false;
}

void AddTabledBuiltin(ref string decls, in BuiltInFunction func) {
  static auto isScalarType(int type) {
    return (type & TypeStringColumnMask) == 0;
  }

  const ArgClass ClassFixed = 
    ArgClass.ClassLS | ArgClass.ClassXLS | ArgClass.ClassLS2 |
    ArgClass.ClassFS | ArgClass.ClassFS2;
  for (int fixed = 0; fixed < ((func.classes & ClassFixed) > 0 ? 2 : 1); ++fixed) {
    if (fixed == 0 && (func.classes & ArgClass.ClassXLS))
      continue;

    for (int type = 0; type < TypeStringCount; ++type) {
      if ((func.types & (1 << (type >> TypeStringRowShift))) == 0)
        continue;

      if ((func.classes & ArgClass.ClassV1) && !isScalarType(type))
        continue;

      if ((func.classes & ArgClass.ClassV3) && (type & TypeStringColumnMask) != 2)
        continue;

      if (fixed == 1 && type == (type & TypeStringScalarMask) &&
        (func.classes & ArgClass.ClassXLS) == 0)
        continue;

      if ((func.classes & ArgClass.ClassNS) && isScalarType(type))
        continue;

      if (func.classes & ArgClass.ClassB)
        decls ~= TypeString[type & TypeStringColumnMask];
      else if (func.classes & ArgClass.ClassRS)
        decls ~= TypeString[type & TypeStringScalarMask];
      else
        decls ~= TypeString[type];
      decls ~= " ";
      decls ~= func.name;
      decls ~= "(";

      for (int arg = 0; arg < func.numArguments; ++arg) {
        if (arg == func.numArguments - 1 && (func.classes & ArgClass.ClassLO))
          decls ~= "out ";
        if (arg == 0) {
          if (func.classes & ArgClass.ClassCVN)
              decls ~= "coherent volatile nontemporal ";
          if (func.classes & ArgClass.ClassFIO)
              decls ~= "inout ";
          if (func.classes & ArgClass.ClassFO)
              decls ~= "out ";
        }
        if ((func.classes & ArgClass.ClassLB) && arg == func.numArguments - 1)
          decls ~= TypeString[type & TypeStringColumnMask];
        else if (fixed && (
          (arg == func.numArguments - 1 && (func.classes & (ArgClass.ClassLS | ArgClass.ClassXLS | ArgClass.ClassLS2))) ||
          (arg == func.numArguments - 2 && (func.classes & ArgClass.ClassLS2)) ||
          (arg == 0 && (func.classes & (ArgClass.ClassFS | ArgClass.ClassFS2))) ||
          (arg == 1 && (func.classes & ArgClass.ClassFS2))))
          decls ~= TypeString[type & TypeStringScalarMask];
        else
          decls ~= TypeString[type];
        if (arg < func.numArguments - 1)
          decls ~= ",";
      }
      decls ~= ");\n";
    }
  }
}
