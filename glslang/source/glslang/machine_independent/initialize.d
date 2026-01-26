module glslang.machine_independent.initialize;

import glslang;

import std.algorithm.searching;
import std.conv;
import std.format;
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

enum ArgClass ClassV1FIOCVN = ArgClass.ClassV1 | ArgClass.ClassFIO | ArgClass.ClassCVN;
enum ArgClass ClassBNS = ArgClass.ClassB | ArgClass.ClassNS;
enum ArgClass ClassRSNS = ArgClass.ClassRS | ArgClass.ClassNS;

enum ArgType TypeFI = ArgType.TypeF | ArgType.TypeI;
enum ArgType TypeFIB = ArgType.TypeF | ArgType.TypeI | ArgType.TypeB;
enum ArgType TypeIU = ArgType.TypeI | ArgType.TypeU;

enum BuiltInFunction[] BaseFunctions = [
  BuiltInFunction(TOperator.EOpRadians, "radians", 1, ArgType.TypeF, ArgClass.ClassRegular, []),
  BuiltInFunction(TOperator.EOpDegrees, "degrees", 1, ArgType.TypeF, ArgClass.ClassRegular, []),
  BuiltInFunction(TOperator.EOpSin, "sin", 1, ArgType.TypeF, ArgClass.ClassRegular, []),
  BuiltInFunction(TOperator.EOpTan, "tan", 1, ArgType.TypeF, ArgClass.ClassRegular, []),
  BuiltInFunction(TOperator.EOpAsin, "asin", 1, ArgType.TypeF, ArgClass.ClassRegular, []),
  BuiltInFunction(TOperator.EOpAcos, "acos", 1, ArgType.TypeF, ArgClass.ClassRegular, []),
  BuiltInFunction(TOperator.EOpAtan, "atan", 2, ArgType.TypeF, ArgClass.ClassRegular, []),
  BuiltInFunction(TOperator.EOpAtan, "atan", 1, ArgType.TypeF, ArgClass.ClassRegular, []),
  BuiltInFunction(TOperator.EOpPow, "pow", 2, ArgType.TypeF, ArgClass.ClassRegular, []),
  BuiltInFunction(TOperator.EOpExp, "exp", 1, ArgType.TypeF, ArgClass.ClassRegular, []),
  BuiltInFunction(TOperator.EOpLog, "log", 1, ArgType.TypeF, ArgClass.ClassRegular, []),
  BuiltInFunction(TOperator.EOpExp2, "exp2", 1, ArgType.TypeF, ArgClass.ClassRegular, []),
  BuiltInFunction(TOperator.EOpLog2, "log2", 1, ArgType.TypeF, ArgClass.ClassRegular, []),
  BuiltInFunction(TOperator.EOpSqrt, "sqrt", 1, ArgType.TypeF, ArgClass.ClassRegular, []),
  BuiltInFunction(TOperator.EOpInverseSqrt, "inversesqrt", 1, ArgType.TypeF, ArgClass.ClassRegular, []),
  BuiltInFunction(TOperator.EOpAbs, "abs", 1, ArgType.TypeF, ArgClass.ClassRegular, []),
  BuiltInFunction(TOperator.EOpSign, "sign", 1, ArgType.TypeF, ArgClass.ClassRegular, []),
  BuiltInFunction(TOperator.EOpFloor, "floor", 1, ArgType.TypeF, ArgClass.ClassRegular, []),
  BuiltInFunction(TOperator.EOpCeil, "ceil", 1, ArgType.TypeF, ArgClass.ClassRegular, []),
  BuiltInFunction(TOperator.EOpFract, "fract", 1, ArgType.TypeF, ArgClass.ClassRegular, []),
  BuiltInFunction(TOperator.EOpMod, "mod", 2, ArgType.TypeF, ArgClass.ClassLS, []),
  BuiltInFunction(TOperator.EOpMin, "min", 2, ArgType.TypeF, ArgClass.ClassLS, []),
  BuiltInFunction(TOperator.EOpMax, "max", 2, ArgType.TypeF, ArgClass.ClassLS, []),
  BuiltInFunction(TOperator.EOpClamp, "clamp", 3, ArgType.TypeF, ArgClass.ClassLS2, []),
  BuiltInFunction(TOperator.EOpMix, "mix", 3, ArgType.TypeF, ArgClass.ClassLS, []),
  BuiltInFunction(TOperator.EOpStep, "step", 2, ArgType.TypeF, ArgClass.ClassFS, []),
  BuiltInFunction(TOperator.EOpSmoothStep, "smoothstep", 3, ArgType.TypeF, ArgClass.ClassFS2, []),
  BuiltInFunction(TOperator.EOpNormalize, "normalize", 1, ArgType.TypeF, ArgClass.ClassRegular, []),
  BuiltInFunction(TOperator.EOpFaceForward, "faceforward", 3, ArgType.TypeF, ArgClass.ClassRegular, []),
  BuiltInFunction(TOperator.EOpReflect, "reflect", 2, ArgType.TypeF, ArgClass.ClassRegular, []),
  BuiltInFunction(TOperator.EOpRefract, "refract", 3, ArgType.TypeF, ArgClass.ClassXLS, []),
  BuiltInFunction(TOperator.EOpLength, "length", 1, ArgType.TypeF, ArgClass.ClassRS, []),
  BuiltInFunction(TOperator.EOpDistance, "distance", 2, ArgType.TypeF, ArgClass.ClassRS, []),
  BuiltInFunction(TOperator.EOpDot, "dot", 2, ArgType.TypeF, ArgClass.ClassRS, []),
  BuiltInFunction(TOperator.EOpCross, "cross", 2, ArgType.TypeF, ArgClass.ClassV3, []),
  BuiltInFunction(TOperator.EOpLessThan, "lessThan", 2, TypeFI, ClassBNS, []),
  BuiltInFunction(TOperator.EOpLessThanEqual, "lessThanEqual", 2, TypeFI, ClassBNS, []),
  BuiltInFunction(TOperator.EOpGreaterThan, "greaterThan", 2, TypeFI, ClassBNS, []),
  BuiltInFunction(TOperator.EOpGreaterThanEqual, "greaterThanEqual", 2, TypeFI, ClassBNS, []),
  BuiltInFunction(TOperator.EOpVectorEqual, "equal", 2, TypeFIB, ClassBNS, []),
  BuiltInFunction(TOperator.EOpAny, "any", 1, ArgType.TypeB, ClassRSNS, []),
  BuiltInFunction(TOperator.EOpAll, "all", 1, ArgType.TypeB, ClassRSNS, []),
  BuiltInFunction(TOperator.EOpVectorLogicalNot, "not", 1, ArgType.TypeB, ArgClass.ClassNS, []),
  BuiltInFunction(TOperator.EOpSinh, "sinh", 1, ArgType.TypeF, ArgClass.ClassRegular, Es300Desktop130Version),
  BuiltInFunction(TOperator.EOpCosh, "cosh", 1, ArgType.TypeF, ArgClass.ClassRegular, Es300Desktop130Version),
  BuiltInFunction(TOperator.EOpTanh, "tanh", 1, ArgType.TypeF, ArgClass.ClassRegular, Es300Desktop130Version),
  BuiltInFunction(TOperator.EOpAsinh, "asinh", 1, ArgType.TypeF, ArgClass.ClassRegular, Es300Desktop130Version),
  BuiltInFunction(TOperator.EOpAcosh, "acosh", 1, ArgType.TypeF, ArgClass.ClassRegular, Es300Desktop130Version),
  BuiltInFunction(TOperator.EOpAtanh, "atanh", 1, ArgType.TypeF, ArgClass.ClassRegular, Es300Desktop130Version),
  BuiltInFunction(TOperator.EOpAbs, "abs", 1, ArgType.TypeI, ArgClass.ClassRegular, Es300Desktop130Version),
  BuiltInFunction(TOperator.EOpSign, "sign", 1, ArgType.TypeI, ArgClass.ClassRegular, Es300Desktop130Version),
  BuiltInFunction(TOperator.EOpTrunc, "trunc", 1, ArgType.TypeF, ArgClass.ClassRegular, Es300Desktop130Version),
  BuiltInFunction(TOperator.EOpRound, "round", 1, ArgType.TypeF, ArgClass.ClassRegular, Es300Desktop130Version),
  BuiltInFunction(TOperator.EOpRoundEven, "roundEven", 1, ArgType.TypeF, ArgClass.ClassRegular, Es300Desktop130Version),
  BuiltInFunction(TOperator.EOpModf, "modf", 2, ArgType.TypeF, ArgClass.ClassLO, Es300Desktop130Version),
  BuiltInFunction(TOperator.EOpMin, "min", 2, TypeIU, ArgClass.ClassLS, Es300Desktop130Version),
  BuiltInFunction(TOperator.EOpMax, "max", 2, TypeIU, ArgClass.ClassLS, Es300Desktop130Version),
  BuiltInFunction(TOperator.EOpClamp, "clamp", 3, TypeIU, ArgClass.ClassLS2, Es300Desktop130Version),
  BuiltInFunction(TOperator.EOpMix, "mix", 3, ArgType.TypeF, ArgClass.ClassLB, Es300Desktop130Version),
  BuiltInFunction(TOperator.EOpIsInf, "isinf", 1, ArgType.TypeF, ArgClass.ClassB, Es300Desktop130Version),
  BuiltInFunction(TOperator.EOpIsNan, "isnan", 1, ArgType.TypeF, ArgClass.ClassB, Es300Desktop130Version),
  BuiltInFunction(TOperator.EOpLessThan, "lessThan", 2, ArgType.TypeU, ClassBNS, Es300Desktop130Version),
  BuiltInFunction(TOperator.EOpLessThanEqual, "lessThanEqual", 2, ArgType.TypeU, ClassBNS, Es300Desktop130Version),
  BuiltInFunction(TOperator.EOpGreaterThan, "greaterThan", 2, ArgType.TypeU, ClassBNS, Es300Desktop130Version),
  BuiltInFunction(TOperator.EOpGreaterThanEqual, "greaterThanEqual", 2, ArgType.TypeU, ClassBNS, Es300Desktop130Version),
  BuiltInFunction(TOperator.EOpVectorEqual, "equal", 2, ArgType.TypeU, ClassBNS, Es300Desktop130Version),
  BuiltInFunction(TOperator.EOpVectorNotEqual, "notEqual", 2, ArgType.TypeU, ClassBNS, Es300Desktop130Version),
  BuiltInFunction(TOperator.EOpAtomicAdd, "atomicAdd", 2, TypeIU, ClassV1FIOCVN, Es310Desktop400Version),
  BuiltInFunction(TOperator.EOpAtomicMin, "atomicMin", 2, TypeIU, ClassV1FIOCVN, Es310Desktop400Version),
  BuiltInFunction(TOperator.EOpAtomicMax, "atomicMax", 2, TypeIU, ClassV1FIOCVN, Es310Desktop400Version),
  BuiltInFunction(TOperator.EOpAtomicAnd, "atomicAnd", 2, TypeIU, ClassV1FIOCVN, Es310Desktop400Version),
  BuiltInFunction(TOperator.EOpAtomicOr, "atomicOr", 2, TypeIU, ClassV1FIOCVN, Es310Desktop400Version),
  BuiltInFunction(TOperator.EOpAtomicExchange, "atomicExchange", 2, TypeIU, ClassV1FIOCVN, Es310Desktop400Version),
  BuiltInFunction(TOperator.EOpAtomicCompSwap, "atomicCompSwap", 3, TypeIU, ClassV1FIOCVN, Es310Desktop400Version),
  BuiltInFunction(TOperator.EOpMix, "mix", 3, ArgType.TypeB, ArgClass.ClassRegular, Es310Desktop450Version),
  BuiltInFunction(TOperator.EOpMix, "mix", 3, TypeIU, ArgClass.ClassLB, Es310Desktop450Version)
];

enum BuiltInFunction[] DerivativeFunctions = [
  BuiltInFunction(TOperator.EOpDPdx, "dFdx", 1, ArgType.TypeF, ArgClass.ClassRegular, []),
  BuiltInFunction(TOperator.EOpDPdy, "dFdy", 1, ArgType.TypeF, ArgClass.ClassRegular, []),
  BuiltInFunction(TOperator.EOpFwidth, "fwidth", 1, ArgType.TypeF, ArgClass.ClassRegular, [])
];

enum glslang_profile_t EDesktopProfile =
  glslang_profile_t.NO_PROFILE | glslang_profile_t.CORE_PROFILE | glslang_profile_t.COMPATIBILITY_PROFILE;

enum Versioning[] Es300Desktop130Version = [
  Versioning(glslang_profile_t.ES_PROFILE, 0, 300, 0, null),
  Versioning(EDesktopProfile, 0, 130, 0, null),
];

enum Versioning[] Es310Desktop400Version = [
  Versioning(glslang_profile_t.ES_PROFILE, 0, 310, 0, null),
  Versioning(EDesktopProfile, 0, 400, 0, null),
];

enum Versioning[] Es310Desktop450Version = [
  Versioning(glslang_profile_t.ES_PROFILE, 0, 310, 0, null),
  Versioning(EDesktopProfile, 0, 450, 0, null),
];

class TBuiltInParseables {
  protected {
    Appender!(char[]) commonBuiltins;
    Appender!(char[])[EnumMembers!glslang_stage_t.length] stageBuiltins;
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
    auto forEachFunction(ref Appender!(char[]) decls, const(BuiltInFunction[]) functions) {
      foreach (const ref fn; functions) {
        if (ValidVersion(fn, version_, profile, spvVersion))
          AddTabledBuiltin(decls, fn);
      }
    }

    forEachFunction(commonBuiltins, BaseFunctions);
    forEachFunction(stageBuiltins[glslang_stage_t.STAGE_FRAGMENT], DerivativeFunctions);

    if ((profile == glslang_profile_t.ES_PROFILE && version_ >= 320) ||
      (profile != glslang_profile_t.ES_PROFILE && version_ >= 450))
      forEachFunction(stageBuiltins[glslang_stage_t.STAGE_COMPUTE], DerivativeFunctions);
  }

  override void initialize(
    int version_, glslang_profile_t profile,
    in SpvVersion spvVersion
  ) {
    addTabledBuiltins(version_, profile, spvVersion);

    string derivativeControls = q{
      float dFdxFine(float p);
      vec2 dFdxFine(vec2 p);
      vec3 dFdxFine(vec3 p);
      vec4 dFdxFine(vec4 p);

      float dFdyFine(float p);
      vec2 dFdyFine(vec2 p);
      vec3 dFdyFine(vec3 p);
      vec4 dFdyFine(vec4 p);

      float fwidthFine(float p);
      vec2 fwidthFine(vec2 p);
      vec3 fwidthFine(vec3 p);
      vec4 fwidthFine(vec4 p);

      float dFdxCoarse(float p);
      vec2 dFdxCoarse(vec2 p);
      vec3 dFdxCoarse(vec3 p);
      vec4 dFdxCoarse(vec4 p);

      float dFdyCoarse(float p);
      vec2 dFdyCoarse(vec2 p);
      vec3 dFdyCoarse(vec3 p);
      vec4 dFdyCoarse(vec4 p);

      float fwidthCoarse(float p);
      vec2 fwidthCoarse(vec2 p);
      vec3 fwidthCoarse(vec3 p);
      vec4 fwidthCoarse(vec4 p);
    };

    string derivativesAndControl16bits = q{
      float16_t dFdx(float16_t);
      f16vec2 dFdx(f16vec2);
      f16vec3 dFdx(f16vec3);
      f16vec4 dFdx(f16vec4);

      float16_t dFdy(float16_t);
      f16vec2 dFdy(f16vec2);
      f16vec3 dFdy(f16vec3);
      f16vec4 dFdy(f16vec4);

      float16_t dFdxFine(float16_t);
      f16vec2 dFdxFine(f16vec2);
      f16vec3 dFdxFine(f16vec3);
      f16vec4 dFdxFine(f16vec4);

      float16_t dFdyFine(float16_t);
      f16vec2 dFdyFine(f16vec2);
      f16vec3 dFdyFine(f16vec3);
      f16vec4 dFdyFine(f16vec4);

      float16_t dFdxCoarse(float16_t);
      f16vec2 dFdxCoarse(f16vec2);
      f16vec3 dFdxCoarse(f16vec3);
      f16vec4 dFdxCoarse(f16vec4);

      float16_t dFdyCoarse(float16_t);
      f16vec2 dFdyCoarse(f16vec2);
      f16vec3 dFdyCoarse(f16vec3);
      f16vec4 dFdyCoarse(f16vec4);

      float16_t fwidth(float16_t);
      f16vec2 fwidth(f16vec2);
      f16vec3 fwidth(f16vec3);
      f16vec4 fwidth(f16vec4);

      float16_t fwidthFine(float16_t);
      f16vec2 fwidthFine(f16vec2);
      f16vec3 fwidthFine(f16vec3);
      f16vec4 fwidthFine(f16vec4);

      float16_t fwidthCoarse(float16_t);
      f16vec2 fwidthCoarse(f16vec2);
      f16vec3 fwidthCoarse(f16vec3);
      f16vec4 fwidthCoarse(f16vec4);
    };

    string derivativesAndControl64bits = q{
      float64_t dFdx(float64_t);
      f64vec2 dFdx(f64vec2);
      f64vec3 dFdx(f64vec3);
      f64vec4 dFdx(f64vec4);

      float64_t dFdy(float64_t);
      f64vec2 dFdy(f64vec2);
      f64vec3 dFdy(f64vec3);
      f64vec4 dFdy(f64vec4);

      float64_t dFdxFine(float64_t);
      f64vec2 dFdxFine(f64vec2);
      f64vec3 dFdxFine(f64vec3);
      f64vec4 dFdxFine(f64vec4);

      float64_t dFdyFine(float64_t);
      f64vec2 dFdyFine(f64vec2);
      f64vec3 dFdyFine(f64vec3);
      f64vec4 dFdyFine(f64vec4);

      float64_t dFdxCoarse(float64_t);
      f64vec2 dFdxCoarse(f64vec2);
      f64vec3 dFdxCoarse(f64vec3);
      f64vec4 dFdxCoarse(f64vec4);

      float64_t dFdyCoarse(float64_t);
      f64vec2 dFdyCoarse(f64vec2);
      f64vec3 dFdyCoarse(f64vec3);
      f64vec4 dFdyCoarse(f64vec4);

      float64_t fwidth(float64_t);
      f64vec2 fwidth(f64vec2);
      f64vec3 fwidth(f64vec3);
      f64vec4 fwidth(f64vec4);

      float64_t fwidthFine(float64_t);
      f64vec2 fwidthFine(f64vec2);
      f64vec3 fwidthFine(f64vec3);
      f64vec4 fwidthFine(f64vec4);

      float64_t fwidthCoarse(float64_t);
      f64vec2 fwidthCoarse(f64vec2);
      f64vec3 fwidthCoarse(f64vec3);
      f64vec4 fwidthCoarse(f64vec4);
    };

    if (profile != glslang_profile_t.ES_PROFILE && version_ >= 150) {
      commonBuiltins ~= q{
        double sqrt(double);
        dvec2 sqrt(dvec2);
        dvec3 sqrt(dvec3);
        dvec4 sqrt(dvec4);

        double inversesqrt(double);
        dvec2 inversesqrt(dvec2);
        dvec3 inversesqrt(dvec3);
        dvec4 inversesqrt(dvec4);

        double abs(double);
        dvec2 abs(dvec2);
        dvec3 abs(dvec3);
        dvec4 abs(dvec4);

        double sign(double);
        dvec2 sign(dvec2);
        dvec3 sign(dvec3);
        dvec4 sign(dvec4);

        double floor(double);
        dvec2 floor(dvec2);
        dvec3 floor(dvec3);
        dvec4 floor(dvec4);

        double trunc(double);
        dvec2 trunc(dvec2);
        dvec3 trunc(dvec3);
        dvec4 trunc(dvec4);

        double round(double);
        dvec2 round(dvec2);
        dvec3 round(dvec3);
        dvec4 round(dvec4);

        double roundEven(double);
        dvec2 roundEven(dvec2);
        dvec3 roundEven(dvec3);
        dvec4 roundEven(dvec4);

        double ceil(double);
        dvec2 ceil(dvec2);
        dvec3 ceil(dvec3);
        dvec4 ceil(dvec4);

        double fract(double);
        dvec2 fract(dvec2);
        dvec3 fract(dvec3);
        dvec4 fract(dvec4);

        double mod(double, double);
        dvec2 mod(dvec2, double);
        dvec3 mod(dvec3, double);
        dvec4 mod(dvec4, double);
        dvec2 mod(dvec2, dvec2);
        dvec3 mod(dvec3, dvec3);
        dvec4 mod(dvec4, dvec4);

        double modf(double, out double);
        dvec2 modf(dvec2, out dvec2);
        dvec3 modf(dvec3, out dvec3);
        dvec4 modf(dvec4, out dvec4);

        double min(double, double);
        dvec2 min(dvec2, double);
        dvec3 min(dvec3, double);
        dvec4 min(dvec4, double);
        dvec2 min(dvec2, dvec2);
        dvec3 min(dvec3, dvec3);
        dvec4 min(dvec4, dvec4);

        double max(double, double);
        dvec2 max(dvec2, double);
        dvec3 max(dvec3, double);
        dvec4 max(dvec4, double);
        dvec2 max(dvec2, dvec2);
        dvec3 max(dvec3, dvec3);
        dvec4 max(dvec4, dvec4);

        double clamp(double, double, double);
        dvec2 clamp(dvec2, double, double);
        dvec3 clamp(dvec3, double, double);
        dvec4 clamp(dvec4, double, double);
        dvec2 clamp(dvec2, dvec2, dvec2);
        dvec3 clamp(dvec3, dvec3, dvec3);
        dvec4 clamp(dvec4, dvec4, dvec4);

        double mix(double, double, double);
        dvec2 mix(dvec2, dvec2, double);
        dvec3 mix(dvec3, dvec3, double);
        dvec4 mix(dvec4, dvec4, double);
        dvec2 mix(dvec2, dvec2, dvec2);
        dvec3 mix(dvec3, dvec3, dvec3);
        dvec4 mix(dvec4, dvec4, dvec4);
        double mix(double, double, bool);
        dvec2 mix(dvec2, dvec2, bvec2);
        dvec3 mix(dvec3, dvec3, bvec3);
        dvec4 mix(dvec4, dvec4, bvec4);

        double step(double, double);
        dvec2 step(dvec2, dvec2);
        dvec3 step(dvec3, dvec3);
        dvec4 step(dvec4, dvec4);
        dvec2 step(double, dvec2);
        dvec3 step(double, dvec3);
        dvec4 step(double, dvec4);

        double smoothstep(double, double, double);
        dvec2 smoothstep(dvec2, dvec2, dvec2);
        dvec3 smoothstep(dvec3, dvec3, dvec3);
        dvec4 smoothstep(dvec4, dvec4, dvec4);
        dvec2 smoothstep(double, double, dvec2);
        dvec3 smoothstep(double, double, dvec3);
        dvec4 smoothstep(double, double, dvec4);

        bool isnan(double);
        bvec2 isnan(dvec2);
        bvec3 isnan(dvec3);
        bvec4 isnan(dvec4);

        bool isinf(double);
        bvec2 isinf(dvec2);
        bvec3 isinf(dvec3);
        bvec4 isinf(dvec4);

        double length(double);
        double length(dvec2);
        double length(dvec3);
        double length(dvec4);

        double distance(double, double);
        double distance(dvec2, dvec2);
        double distance(dvec3, dvec3);
        double distance(dvec4, dvec4);

        double dot(double, double);
        double dot(dvec2, dvec2);
        double dot(dvec3, dvec3);
        double dot(dvec4, dvec4);

        dvec3 cross(dvec3, dvec3);

        double normalize(double);
        dvec2 normalize(dvec2);
        dvec3 normalize(dvec3);
        dvec4 normalize(dvec4);

        double faceforward(double, double, double);
        dvec2 faceforward(dvec2, dvec2, dvec2);
        dvec3 faceforward(dvec3, dvec3, dvec3);
        dvec4 faceforward(dvec4, dvec4, dvec4);

        double reflect(double, double);
        dvec2 reflect(dvec2, dvec2);
        dvec3 reflect(dvec3, dvec3);
        dvec4 reflect(dvec4, dvec4);

        double refract(double, double, double);
        dvec2 refract(dvec2, dvec2, double);
        dvec3 refract(dvec3, dvec3, double);
        dvec4 refract(dvec4, dvec4, double);

        dmat2 matrixCompMult(dmat2, dmat2);
        dmat3 matrixCompMult(dmat3, dmat3);
        dmat4 matrixCompMult(dmat4, dmat4);
        dmat2x3 matrixCompMult(dmat2x3, dmat2x3);
        dmat2x4 matrixCompMult(dmat2x4, dmat2x4);
        dmat3x2 matrixCompMult(dmat3x2, dmat3x2);
        dmat3x4 matrixCompMult(dmat3x4, dmat3x4);
        dmat4x2 matrixCompMult(dmat4x2, dmat4x2);
        dmat4x3 matrixCompMult(dmat4x3, dmat4x3);

        dmat2 outerProduct(dvec2, dvec2);
        dmat3 outerProduct(dvec3, dvec3);
        dmat4 outerProduct(dvec4, dvec4);
        dmat2x3 outerProduct(dvec3, dvec2);
        dmat3x2 outerProduct(dvec2, dvec3);
        dmat2x4 outerProduct(dvec4, dvec2);
        dmat4x2 outerProduct(dvec2, dvec4);
        dmat3x4 outerProduct(dvec4, dvec3);
        dmat4x3 outerProduct(dvec3, dvec4);

        dmat2 transpose(dmat2);
        dmat3 transpose(dmat3);
        dmat4 transpose(dmat4);
        dmat2x3 transpose(dmat3x2);
        dmat3x2 transpose(dmat2x3);
        dmat2x4 transpose(dmat4x2);
        dmat4x2 transpose(dmat2x4);
        dmat3x4 transpose(dmat4x3);
        dmat4x3 transpose(dmat3x4);

        double determinant(dmat2);
        double determinant(dmat3);
        double determinant(dmat4);

        dmat2 inverse(dmat2);
        dmat3 inverse(dmat3);
        dmat4 inverse(dmat4);

        bvec2 lessThan(dvec2, dvec2);
        bvec3 lessThan(dvec3, dvec3);
        bvec4 lessThan(dvec4, dvec4);

        bvec2 lessThanEqual(dvec2, dvec2);
        bvec3 lessThanEqual(dvec3, dvec3);
        bvec4 lessThanEqual(dvec4, dvec4);

        bvec2 greaterThan(dvec2, dvec2);
        bvec3 greaterThan(dvec3, dvec3);
        bvec4 greaterThan(dvec4, dvec4);

        bvec2 greaterThanEqual(dvec2, dvec2);
        bvec3 greaterThanEqual(dvec3, dvec3);
        bvec4 greaterThanEqual(dvec4, dvec4);

        bvec2 equal(dvec2, dvec2);
        bvec3 equal(dvec3, dvec3);
        bvec4 equal(dvec4, dvec4);

        bvec2 notEqual(dvec2, dvec2);
        bvec3 notEqual(dvec3, dvec3);
        bvec4 notEqual(dvec4, dvec4);
      };
    }

    if (profile == glslang_profile_t.ES_PROFILE && version_ >= 310) {
      commonBuiltins ~= q{
        float64_t sqrt(float64_t);
        f64vec2 sqrt(f64vec2);
        f64vec3 sqrt(f64vec3);
        f64vec4 sqrt(f64vec4);

        float64_t inversesqrt(float64_t);
        f64vec2 inversesqrt(f64vec2);
        f64vec3 inversesqrt(f64vec3);
        f64vec4 inversesqrt(f64vec4);

        float64_t abs(float64_t);
        f64vec2 abs(f64vec2);
        f64vec3 abs(f64vec3);
        f64vec4 abs(f64vec4);

        float64_t sign(float64_t);
        f64vec2 sign(f64vec2);
        f64vec3 sign(f64vec3);
        f64vec4 sign(f64vec4);

        float64_t floor(float64_t);
        f64vec2 floor(f64vec2);
        f64vec3 floor(f64vec3);
        f64vec4 floor(f64vec4);

        float64_t trunc(float64_t);
        f64vec2 trunc(f64vec2);
        f64vec3 trunc(f64vec3);
        f64vec4 trunc(f64vec4);

        float64_t round(float64_t);
        f64vec2 round(f64vec2);
        f64vec3 round(f64vec3);
        f64vec4 round(f64vec4);

        float64_t roundEven(float64_t);
        f64vec2 roundEven(f64vec2);
        f64vec3 roundEven(f64vec3);
        f64vec4 roundEven(f64vec4);

        float64_t ceil(float64_t);
        f64vec2 ceil(f64vec2);
        f64vec3 ceil(f64vec3);
        f64vec4 ceil(f64vec4);

        float64_t fract(float64_t);
        f64vec2 fract(f64vec2);
        f64vec3 fract(f64vec3);
        f64vec4 fract(f64vec4);

        float64_t mod(float64_t, float64_t);
        f64vec2 mod(f64vec2, float64_t);
        f64vec3 mod(f64vec3, float64_t);
        f64vec4 mod(f64vec4, float64_t);
        f64vec2 mod(f64vec2, f64vec2);
        f64vec3 mod(f64vec3, f64vec3);
        f64vec4 mod(f64vec4, f64vec4);

        float64_t modf(float64_t, out float64_t);
        f64vec2 modf(f64vec2, out f64vec2);
        f64vec3 modf(f64vec3, out f64vec3);
        f64vec4 modf(f64vec4, out f64vec4);

        float64_t min(float64_t, float64_t);
        f64vec2 min(f64vec2, float64_t);
        f64vec3 min(f64vec3, float64_t);
        f64vec4 min(f64vec4, float64_t);
        f64vec2 min(f64vec2, f64vec2);
        f64vec3 min(f64vec3, f64vec3);
        f64vec4 min(f64vec4, f64vec4);

        float64_t max(float64_t, float64_t);
        f64vec2 max(f64vec2, float64_t);
        f64vec3 max(f64vec3, float64_t);
        f64vec4 max(f64vec4, float64_t);
        f64vec2 max(f64vec2, f64vec2);
        f64vec3 max(f64vec3, f64vec3);
        f64vec4 max(f64vec4, f64vec4);

        float64_t clamp(float64_t, float64_t, float64_t);
        f64vec2 clamp(f64vec2, float64_t, float64_t);
        f64vec3 clamp(f64vec3, float64_t, float64_t);
        f64vec4 clamp(f64vec4, float64_t, float64_t);
        f64vec2 clamp(f64vec2, f64vec2, f64vec2);
        f64vec3 clamp(f64vec3, f64vec3, f64vec3);
        f64vec4 clamp(f64vec4, f64vec4, f64vec4);

        float64_t mix(float64_t, float64_t, float64_t);
        f64vec2 mix(f64vec2, f64vec2, float64_t);
        f64vec3 mix(f64vec3, f64vec3, float64_t);
        f64vec4 mix(f64vec4, f64vec4, float64_t);
        f64vec2 mix(f64vec2, f64vec2, f64vec2);
        f64vec3 mix(f64vec3, f64vec3, f64vec3);
        f64vec4 mix(f64vec4, f64vec4, f64vec4);
        float64_t mix(float64_t, float64_t, bool);
        f64vec2 mix(f64vec2, f64vec2, bvec2);
        f64vec3 mix(f64vec3, f64vec3, bvec3);
        f64vec4 mix(f64vec4, f64vec4, bvec4);

        float64_t step(float64_t, float64_t);
        f64vec2 step(f64vec2, f64vec2);
        f64vec3 step(f64vec3, f64vec3);
        f64vec4 step(f64vec4, f64vec4);
        f64vec2 step(float64_t, f64vec2);
        f64vec3 step(float64_t, f64vec3);
        f64vec4 step(float64_t, f64vec4);

        float64_t smoothstep(float64_t, float64_t, float64_t);
        f64vec2 smoothstep(f64vec2, f64vec2, f64vec2);
        f64vec3 smoothstep(f64vec3, f64vec3, f64vec3);
        f64vec4 smoothstep(f64vec4, f64vec4, f64vec4);
        f64vec2 smoothstep(float64_t, float64_t, f64vec2);
        f64vec3 smoothstep(float64_t, float64_t, f64vec3);
        f64vec4 smoothstep(float64_t, float64_t, f64vec4);

        float64_t length(float64_t);
        float64_t length(f64vec2);
        float64_t length(f64vec3);
        float64_t length(f64vec4);

        float64_t distance(float64_t, float64_t);
        float64_t distance(f64vec2, f64vec2);
        float64_t distance(f64vec3, f64vec3);
        float64_t distance(f64vec4, f64vec4);

        float64_t dot(float64_t, float64_t);
        float64_t dot(f64vec2, f64vec2);
        float64_t dot(f64vec3, f64vec3);
        float64_t dot(f64vec4, f64vec4);

        f64vec3 cross(f64vec3, f64vec3);

        float64_t normalize(float64_t);
        f64vec2 normalize(f64vec2);
        f64vec3 normalize(f64vec3);
        f64vec4 normalize(f64vec4);

        float64_t faceforward(float64_t, float64_t, float64_t);
        f64vec2 faceforward(f64vec2, f64vec2, f64vec2);
        f64vec3 faceforward(f64vec3, f64vec3, f64vec3);
        f64vec4 faceforward(f64vec4, f64vec4, f64vec4);

        float64_t reflect(float64_t, float64_t);
        f64vec2 reflect(f64vec2, f64vec2 );
        f64vec3 reflect(f64vec3, f64vec3 );
        f64vec4 reflect(f64vec4, f64vec4 );

        float64_t refract(float64_t, float64_t, float64_t);
        f64vec2 refract(f64vec2, f64vec2, float64_t);
        f64vec3 refract(f64vec3, f64vec3, float64_t);
        f64vec4 refract(f64vec4, f64vec4, float64_t);

        f64mat2 matrixCompMult(f64mat2, f64mat2);
        f64mat3 matrixCompMult(f64mat3, f64mat3);
        f64mat4 matrixCompMult(f64mat4, f64mat4);
        f64mat2x3 matrixCompMult(f64mat2x3, f64mat2x3);
        f64mat2x4 matrixCompMult(f64mat2x4, f64mat2x4);
        f64mat3x2 matrixCompMult(f64mat3x2, f64mat3x2);
        f64mat3x4 matrixCompMult(f64mat3x4, f64mat3x4);
        f64mat4x2 matrixCompMult(f64mat4x2, f64mat4x2);
        f64mat4x3 matrixCompMult(f64mat4x3, f64mat4x3);

        f64mat2 outerProduct(f64vec2, f64vec2);
        f64mat3 outerProduct(f64vec3, f64vec3);
        f64mat4 outerProduct(f64vec4, f64vec4);
        f64mat2x3 outerProduct(f64vec3, f64vec2);
        f64mat3x2 outerProduct(f64vec2, f64vec3);
        f64mat2x4 outerProduct(f64vec4, f64vec2);
        f64mat4x2 outerProduct(f64vec2, f64vec4);
        f64mat3x4 outerProduct(f64vec4, f64vec3);
        f64mat4x3 outerProduct(f64vec3, f64vec4);

        f64mat2 transpose(f64mat2);
        f64mat3 transpose(f64mat3);
        f64mat4 transpose(f64mat4);
        f64mat2x3 transpose(f64mat3x2);
        f64mat3x2 transpose(f64mat2x3);
        f64mat2x4 transpose(f64mat4x2);
        f64mat4x2 transpose(f64mat2x4);
        f64mat3x4 transpose(f64mat4x3);
        f64mat4x3 transpose(f64mat3x4);

        float64_t determinant(f64mat2);
        float64_t determinant(f64mat3);
        float64_t determinant(f64mat4);

        f64mat2 inverse(f64mat2);
        f64mat3 inverse(f64mat3);
        f64mat4 inverse(f64mat4);
      };
    }

    if ((profile != glslang_profile_t.ES_PROFILE && version_ >= 450) ||
      (profile == glslang_profile_t.ES_PROFILE && version_ >= 310)) {
      commonBuiltins ~= q{
        int64_t abs(int64_t);
        i64vec2 abs(i64vec2);
        i64vec3 abs(i64vec3);
        i64vec4 abs(i64vec4);

        int64_t sign(int64_t);
        i64vec2 sign(i64vec2);
        i64vec3 sign(i64vec3);
        i64vec4 sign(i64vec4);

        int64_t min(int64_t, int64_t);
        i64vec2 min(i64vec2, int64_t);
        i64vec3 min(i64vec3, int64_t);
        i64vec4 min(i64vec4, int64_t);
        i64vec2 min(i64vec2, i64vec2);
        i64vec3 min(i64vec3, i64vec3);
        i64vec4 min(i64vec4, i64vec4);
        uint64_t min(uint64_t, uint64_t);
        u64vec2 min(u64vec2, uint64_t);
        u64vec3 min(u64vec3, uint64_t);
        u64vec4 min(u64vec4, uint64_t);
        u64vec2 min(u64vec2, u64vec2);
        u64vec3 min(u64vec3, u64vec3);
        u64vec4 min(u64vec4, u64vec4);

        int64_t max(int64_t, int64_t);
        i64vec2 max(i64vec2, int64_t);
        i64vec3 max(i64vec3, int64_t);
        i64vec4 max(i64vec4, int64_t);
        i64vec2 max(i64vec2, i64vec2);
        i64vec3 max(i64vec3, i64vec3);
        i64vec4 max(i64vec4, i64vec4);
        uint64_t max(uint64_t, uint64_t);
        u64vec2 max(u64vec2, uint64_t);
        u64vec3 max(u64vec3, uint64_t);
        u64vec4 max(u64vec4, uint64_t);
        u64vec2 max(u64vec2, u64vec2);
        u64vec3 max(u64vec3, u64vec3);
        u64vec4 max(u64vec4, u64vec4);

        int64_t clamp(int64_t, int64_t, int64_t);
        i64vec2 clamp(i64vec2, int64_t, int64_t);
        i64vec3 clamp(i64vec3, int64_t, int64_t);
        i64vec4 clamp(i64vec4, int64_t, int64_t);
        i64vec2 clamp(i64vec2, i64vec2, i64vec2);
        i64vec3 clamp(i64vec3, i64vec3, i64vec3);
        i64vec4 clamp(i64vec4, i64vec4, i64vec4);
        uint64_t clamp(uint64_t, uint64_t, uint64_t);
        u64vec2 clamp(u64vec2, uint64_t, uint64_t);
        u64vec3 clamp(u64vec3, uint64_t, uint64_t);
        u64vec4 clamp(u64vec4, uint64_t, uint64_t);
        u64vec2 clamp(u64vec2, u64vec2, u64vec2);
        u64vec3 clamp(u64vec3, u64vec3, u64vec3);
        u64vec4 clamp(u64vec4, u64vec4, u64vec4);

        int64_t mix(int64_t, int64_t, bool);
        i64vec2 mix(i64vec2, i64vec2, bvec2);
        i64vec3 mix(i64vec3, i64vec3, bvec3);
        i64vec4 mix(i64vec4, i64vec4, bvec4);
        uint64_t mix(uint64_t, uint64_t, bool);
        u64vec2 mix(u64vec2, u64vec2, bvec2);
        u64vec3 mix(u64vec3, u64vec3, bvec3);
        u64vec4 mix(u64vec4, u64vec4, bvec4);

        int64_t doubleBitsToInt64(float64_t);
        i64vec2 doubleBitsToInt64(f64vec2);
        i64vec3 doubleBitsToInt64(f64vec3);
        i64vec4 doubleBitsToInt64(f64vec4);

        uint64_t doubleBitsToUint64(float64_t);
        u64vec2 doubleBitsToUint64(f64vec2);
        u64vec3 doubleBitsToUint64(f64vec3);
        u64vec4 doubleBitsToUint64(f64vec4);

        float64_t int64BitsToDouble(int64_t);
        f64vec2 int64BitsToDouble(i64vec2);
        f64vec3 int64BitsToDouble(i64vec3);
        f64vec4 int64BitsToDouble(i64vec4);

        float64_t uint64BitsToDouble(uint64_t);
        f64vec2 uint64BitsToDouble(u64vec2);
        f64vec3 uint64BitsToDouble(u64vec3);
        f64vec4 uint64BitsToDouble(u64vec4);

        int64_t packInt2x32(ivec2);
        uint64_t packUint2x32(uvec2);
        ivec2 unpackInt2x32(int64_t);
        uvec2 unpackUint2x32(uint64_t);

        bvec2 lessThan(i64vec2, i64vec2);
        bvec3 lessThan(i64vec3, i64vec3);
        bvec4 lessThan(i64vec4, i64vec4);
        bvec2 lessThan(u64vec2, u64vec2);
        bvec3 lessThan(u64vec3, u64vec3);
        bvec4 lessThan(u64vec4, u64vec4);

        bvec2 lessThanEqual(i64vec2, i64vec2);
        bvec3 lessThanEqual(i64vec3, i64vec3);
        bvec4 lessThanEqual(i64vec4, i64vec4);
        bvec2 lessThanEqual(u64vec2, u64vec2);
        bvec3 lessThanEqual(u64vec3, u64vec3);
        bvec4 lessThanEqual(u64vec4, u64vec4);

        bvec2 greaterThan(i64vec2, i64vec2);
        bvec3 greaterThan(i64vec3, i64vec3);
        bvec4 greaterThan(i64vec4, i64vec4);
        bvec2 greaterThan(u64vec2, u64vec2);
        bvec3 greaterThan(u64vec3, u64vec3);
        bvec4 greaterThan(u64vec4, u64vec4);

        bvec2 greaterThanEqual(i64vec2, i64vec2);
        bvec3 greaterThanEqual(i64vec3, i64vec3);
        bvec4 greaterThanEqual(i64vec4, i64vec4);
        bvec2 greaterThanEqual(u64vec2, u64vec2);
        bvec3 greaterThanEqual(u64vec3, u64vec3);
        bvec4 greaterThanEqual(u64vec4, u64vec4);

        bvec2 equal(i64vec2, i64vec2);
        bvec3 equal(i64vec3, i64vec3);
        bvec4 equal(i64vec4, i64vec4);
        bvec2 equal(u64vec2, u64vec2);
        bvec3 equal(u64vec3, u64vec3);
        bvec4 equal(u64vec4, u64vec4);

        bvec2 notEqual(i64vec2, i64vec2);
        bvec3 notEqual(i64vec3, i64vec3);
        bvec4 notEqual(i64vec4, i64vec4);
        bvec2 notEqual(u64vec2, u64vec2);
        bvec3 notEqual(u64vec3, u64vec3);
        bvec4 notEqual(u64vec4, u64vec4);

        int64_t bitCount(int64_t);
        i64vec2 bitCount(i64vec2);
        i64vec3 bitCount(i64vec3);
        i64vec4 bitCount(i64vec4);

        int64_t bitCount(uint64_t);
        i64vec2 bitCount(u64vec2);
        i64vec3 bitCount(u64vec3);
        i64vec4 bitCount(u64vec4);

        int64_t findLSB(int64_t);
        i64vec2 findLSB(i64vec2);
        i64vec3 findLSB(i64vec3);
        i64vec4 findLSB(i64vec4);

        int64_t findLSB(uint64_t);
        i64vec2 findLSB(u64vec2);
        i64vec3 findLSB(u64vec3);
        i64vec4 findLSB(u64vec4);

        int64_t findMSB(int64_t);
        i64vec2 findMSB(i64vec2);
        i64vec3 findMSB(i64vec3);
        i64vec4 findMSB(i64vec4);

        int64_t findMSB(uint64_t);
        i64vec2 findMSB(u64vec2);
        i64vec3 findMSB(u64vec3);
        i64vec4 findMSB(u64vec4);
      };
    }

    if (profile != glslang_profile_t.ES_PROFILE && version_ >= 430) {
      commonBuiltins ~= q{
        float min3(float, float, float);
        vec2 min3(vec2, vec2, vec2);
        vec3 min3(vec3, vec3, vec3);
        vec4 min3(vec4, vec4, vec4);

        int min3(int, int, int);
        ivec2 min3(ivec2, ivec2, ivec2);
        ivec3 min3(ivec3, ivec3, ivec3);
        ivec4 min3(ivec4, ivec4, ivec4);

        uint min3(uint, uint, uint);
        uvec2 min3(uvec2, uvec2, uvec2);
        uvec3 min3(uvec3, uvec3, uvec3);
        uvec4 min3(uvec4, uvec4, uvec4);

        float max3(float, float, float);
        vec2 max3(vec2, vec2, vec2);
        vec3 max3(vec3, vec3, vec3);
        vec4 max3(vec4, vec4, vec4);

        int max3(int, int, int);
        ivec2 max3(ivec2, ivec2, ivec2);
        ivec3 max3(ivec3, ivec3, ivec3);
        ivec4 max3(ivec4, ivec4, ivec4);

        uint max3(uint, uint, uint);
        uvec2 max3(uvec2, uvec2, uvec2);
        uvec3 max3(uvec3, uvec3, uvec3);
        uvec4 max3(uvec4, uvec4, uvec4);

        float mid3(float, float, float);
        vec2 mid3(vec2, vec2, vec2);
        vec3 mid3(vec3, vec3, vec3);
        vec4 mid3(vec4, vec4, vec4);

        int mid3(int, int, int);
        ivec2 mid3(ivec2, ivec2, ivec2);
        ivec3 mid3(ivec3, ivec3, ivec3);
        ivec4 mid3(ivec4, ivec4, ivec4);

        uint mid3(uint, uint, uint);
        uvec2 mid3(uvec2, uvec2, uvec2);
        uvec3 mid3(uvec3, uvec3, uvec3);
        uvec4 mid3(uvec4, uvec4, uvec4);

        float16_t min3(float16_t, float16_t, float16_t);
        f16vec2 min3(f16vec2, f16vec2, f16vec2);
        f16vec3 min3(f16vec3, f16vec3, f16vec3);
        f16vec4 min3(f16vec4, f16vec4, f16vec4);

        float16_t max3(float16_t, float16_t, float16_t);
        f16vec2 max3(f16vec2, f16vec2, f16vec2);
        f16vec3 max3(f16vec3, f16vec3, f16vec3);
        f16vec4 max3(f16vec4, f16vec4, f16vec4);

        float16_t mid3(float16_t, float16_t, float16_t);
        f16vec2 mid3(f16vec2, f16vec2, f16vec2);
        f16vec3 mid3(f16vec3, f16vec3, f16vec3);
        f16vec4 mid3(f16vec4, f16vec4, f16vec4);

        int16_t min3(int16_t, int16_t, int16_t);
        i16vec2 min3(i16vec2, i16vec2, i16vec2);
        i16vec3 min3(i16vec3, i16vec3, i16vec3);
        i16vec4 min3(i16vec4, i16vec4, i16vec4);

        int16_t max3(int16_t, int16_t, int16_t);
        i16vec2 max3(i16vec2, i16vec2, i16vec2);
        i16vec3 max3(i16vec3, i16vec3, i16vec3);
        i16vec4 max3(i16vec4, i16vec4, i16vec4);

        int16_t mid3(int16_t, int16_t, int16_t);
        i16vec2 mid3(i16vec2, i16vec2, i16vec2);
        i16vec3 mid3(i16vec3, i16vec3, i16vec3);
        i16vec4 mid3(i16vec4, i16vec4, i16vec4);

        uint16_t min3(uint16_t, uint16_t, uint16_t);
        u16vec2 min3(u16vec2, u16vec2, u16vec2);
        u16vec3 min3(u16vec3, u16vec3, u16vec3);
        u16vec4 min3(u16vec4, u16vec4, u16vec4);

        uint16_t max3(uint16_t, uint16_t, uint16_t);
        u16vec2 max3(u16vec2, u16vec2, u16vec2);
        u16vec3 max3(u16vec3, u16vec3, u16vec3);
        u16vec4 max3(u16vec4, u16vec4, u16vec4);

        uint16_t mid3(uint16_t, uint16_t, uint16_t);
        u16vec2 mid3(u16vec2, u16vec2, u16vec2);
        u16vec3 mid3(u16vec3, u16vec3, u16vec3);
        u16vec4 mid3(u16vec4, u16vec4, u16vec4);
      };
    }

    if ((profile == glslang_profile_t.ES_PROFILE && version_ >= 310) ||
      (profile != glslang_profile_t.ES_PROFILE && version_ >= 430)) {
      commonBuiltins ~= q{
        uint atomicAdd(coherent volatile nontemporal inout uint, uint, int, int, int);
        int atomicAdd(coherent volatile nontemporal inout int, int, int, int, int);

        uint atomicMin(coherent volatile nontemporal inout uint, uint, int, int, int);
        int atomicMin(coherent volatile nontemporal inout int, int, int, int, int);

        uint atomicMax(coherent volatile nontemporal inout uint, uint, int, int, int);
        int atomicMax(coherent volatile nontemporal inout int, int, int, int, int);

        uint atomicAnd(coherent volatile nontemporal inout uint, uint, int, int, int);
        int atomicAnd(coherent volatile nontemporal inout int, int, int, int, int);

        uint atomicOr(coherent volatile nontemporal inout uint, uint, int, int, int);
        int atomicOr(coherent volatile nontemporal inout int, int, int, int, int);

        uint atomicXor(coherent volatile nontemporal inout uint, uint, int, int, int);
        int atomicXor(coherent volatile nontemporal inout int, int, int, int, int);

        uint atomicExchange(coherent volatile nontemporal inout uint, uint, int, int, int);
        int atomicExchange(coherent volatile nontemporal inout int, int, int, int, int);

        uint atomicCompSwap(coherent volatile nontemporal inout uint, uint, uint, int, int, int, int, int);
        int atomicCompSwap(coherent volatile nontemporal inout int, int, int, int, int, int, int, int);

        uint atomicLoad(coherent volatile nontemporal in uint, int, int, int);
        int atomicLoad(coherent volatile nontemporal in int, int, int, int);

        void atomicStore(coherent volatile nontemporal out uint, uint, int, int, int);
        void atomicStore(coherent volatile nontemporal out int, int, int, int, int);
      };
    }

    if (profile != glslang_profile_t.ES_PROFILE && version_ >= 440) {
      commonBuiltins ~= q{
        uint64_t atomicMin(coherent volatile nontemporal inout uint64_t, uint64_t);
        int64_t atomicMin(coherent volatile nontemporal inout int64_t, int64_t);
        uint64_t atomicMin(coherent volatile nontemporal inout uint64_t, uint64_t, int, int, int);
        int64_t atomicMin(coherent volatile nontemporal inout int64_t, int64_t, int, int, int);
        float16_t atomicMin(coherent volatile nontemporal inout float16_t, float16_t);
        float16_t atomicMin(coherent volatile nontemporal inout float16_t, float16_t, int, int, int);
        float atomicMin(coherent volatile nontemporal inout float, float);
        float atomicMin(coherent volatile nontemporal inout float, float, int, int, int);
        double atomicMin(coherent volatile nontemporal inout double, double);
        double atomicMin(coherent volatile nontemporal inout double, double, int, int, int);

        uint64_t atomicMax(coherent volatile nontemporal inout uint64_t, uint64_t);
        int64_t atomicMax(coherent volatile nontemporal inout int64_t, int64_t);
        uint64_t atomicMax(coherent volatile nontemporal inout uint64_t, uint64_t, int, int, int);
        int64_t atomicMax(coherent volatile nontemporal inout int64_t, int64_t, int, int, int);
        float16_t atomicMax(coherent volatile nontemporal inout float16_t, float16_t);
        float16_t atomicMax(coherent volatile nontemporal inout float16_t, float16_t, int, int, int);
        float atomicMax(coherent volatile nontemporal inout float, float);
        float atomicMax(coherent volatile nontemporal inout float, float, int, int, int);
        double atomicMax(coherent volatile nontemporal inout double, double);
        double atomicMax(coherent volatile nontemporal inout double, double, int, int, int);

        uint64_t atomicAnd(coherent volatile nontemporal inout uint64_t, uint64_t);
        int64_t atomicAnd(coherent volatile nontemporal inout int64_t, int64_t);
        uint64_t atomicAnd(coherent volatile nontemporal inout uint64_t, uint64_t, int, int, int);
        int64_t atomicAnd(coherent volatile nontemporal inout int64_t, int64_t, int, int, int);

        uint64_t atomicOr (coherent volatile nontemporal inout uint64_t, uint64_t);
        int64_t atomicOr (coherent volatile nontemporal inout int64_t, int64_t);
        uint64_t atomicOr (coherent volatile nontemporal inout uint64_t, uint64_t, int, int, int);
        int64_t atomicOr (coherent volatile nontemporal inout int64_t, int64_t, int, int, int);

        uint64_t atomicXor(coherent volatile nontemporal inout uint64_t, uint64_t);
        int64_t atomicXor(coherent volatile nontemporal inout int64_t, int64_t);
        uint64_t atomicXor(coherent volatile nontemporal inout uint64_t, uint64_t, int, int, int);
        int64_t atomicXor(coherent volatile nontemporal inout int64_t, int64_t, int, int, int);

        uint64_t atomicAdd(coherent volatile nontemporal inout uint64_t, uint64_t);
        int64_t atomicAdd(coherent volatile nontemporal inout int64_t, int64_t);
        uint64_t atomicAdd(coherent volatile nontemporal inout uint64_t, uint64_t, int, int, int);
        int64_t atomicAdd(coherent volatile nontemporal inout int64_t, int64_t, int, int, int);
        float16_t atomicAdd(coherent volatile nontemporal inout float16_t, float16_t);
        float16_t atomicAdd(coherent volatile nontemporal inout float16_t, float16_t, int, int, int);
        float atomicAdd(coherent volatile nontemporal inout float, float);
        float atomicAdd(coherent volatile nontemporal inout float, float, int, int, int);
        double atomicAdd(coherent volatile nontemporal inout double, double);
        double atomicAdd(coherent volatile nontemporal inout double, double, int, int, int);

        uint64_t atomicExchange(coherent volatile nontemporal inout uint64_t, uint64_t);
        int64_t atomicExchange(coherent volatile nontemporal inout int64_t, int64_t);
        uint64_t atomicExchange(coherent volatile nontemporal inout uint64_t, uint64_t, int, int, int);
        int64_t atomicExchange(coherent volatile nontemporal inout int64_t, int64_t, int, int, int);
        float16_t atomicExchange(coherent volatile nontemporal inout float16_t, float16_t);
        float16_t atomicExchange(coherent volatile nontemporal inout float16_t, float16_t, int, int, int);
        float atomicExchange(coherent volatile nontemporal inout float, float);
        float atomicExchange(coherent volatile nontemporal inout float, float, int, int, int);
        double atomicExchange(coherent volatile nontemporal inout double, double);
        double atomicExchange(coherent volatile nontemporal inout double, double, int, int, int);

        uint64_t atomicCompSwap(coherent volatile nontemporal inout uint64_t, uint64_t, uint64_t);
        int64_t atomicCompSwap(coherent volatile nontemporal inout int64_t, int64_t, int64_t);
        uint64_t atomicCompSwap(coherent volatile nontemporal inout uint64_t, uint64_t, uint64_t, int, int, int, int, int);
        int64_t atomicCompSwap(coherent volatile nontemporal inout int64_t, int64_t, int64_t, int, int, int, int, int);

        uint64_t atomicLoad(coherent volatile nontemporal in uint64_t, int, int, int);
        int64_t atomicLoad(coherent volatile nontemporal in int64_t, int, int, int);
        float16_t atomicLoad(coherent volatile nontemporal in float16_t, int, int, int);
        float atomicLoad(coherent volatile nontemporal in float, int, int, int);
        double atomicLoad(coherent volatile nontemporal in double, int, int, int);

        void atomicStore(coherent volatile nontemporal out uint64_t, uint64_t, int, int, int);
        void atomicStore(coherent volatile nontemporal out int64_t, int64_t, int, int, int);
        void atomicStore(coherent volatile nontemporal out float16_t, float16_t, int, int, int);
        void atomicStore(coherent volatile nontemporal out float, float, int, int, int);
        void atomicStore(coherent volatile nontemporal out double, double, int, int, int);
      };
    }

    if (profile != glslang_profile_t.ES_PROFILE && version_ >= 430) {
      commonBuiltins ~= q{
        f16vec2 atomicAdd(coherent volatile nontemporal inout f16vec2, f16vec2);
        f16vec4 atomicAdd(coherent volatile nontemporal inout f16vec4, f16vec4);
        f16vec2 atomicMin(coherent volatile nontemporal inout f16vec2, f16vec2);
        f16vec4 atomicMin(coherent volatile nontemporal inout f16vec4, f16vec4);
        f16vec2 atomicMax(coherent volatile nontemporal inout f16vec2, f16vec2);
        f16vec4 atomicMax(coherent volatile nontemporal inout f16vec4, f16vec4);
        f16vec2 atomicExchange(coherent volatile nontemporal inout f16vec2, f16vec2);
        f16vec4 atomicExchange(coherent volatile nontemporal inout f16vec4, f16vec4);
      };
    }

    if ((profile == glslang_profile_t.ES_PROFILE && version_ >= 300) ||
      (profile != glslang_profile_t.ES_PROFILE && version_ >= 150)) {
      commonBuiltins ~= q{
        int floatBitsToInt(highp float value);
        ivec2 floatBitsToInt(highp vec2 value);
        ivec3 floatBitsToInt(highp vec3 value);
        ivec4 floatBitsToInt(highp vec4 value);

        uint floatBitsToUint(highp float value);
        uvec2 floatBitsToUint(highp vec2 value);
        uvec3 floatBitsToUint(highp vec3 value);
        uvec4 floatBitsToUint(highp vec4 value);

        float intBitsToFloat(highp int value);
        vec2 intBitsToFloat(highp ivec2 value);
        vec3 intBitsToFloat(highp ivec3 value);
        vec4 intBitsToFloat(highp ivec4 value);

        float uintBitsToFloat(highp uint value);
        vec2 uintBitsToFloat(highp uvec2 value);
        vec3 uintBitsToFloat(highp uvec3 value);
        vec4 uintBitsToFloat(highp uvec4 value);
      };
    }

    if ((profile != glslang_profile_t.ES_PROFILE && version_ >= 150) ||
      (profile == glslang_profile_t.ES_PROFILE && version_ >= 310)) {
      commonBuiltins ~= q{
        float fma(float, float, float);
        vec2 fma(vec2, vec2, vec2);
        vec3 fma(vec3, vec3, vec3);
        vec4 fma(vec4, vec4, vec4);
      };
    }

    if (profile != glslang_profile_t.ES_PROFILE && version_ >= 150) {
      commonBuiltins ~= q{
        double fma(double, double, double);
        dvec2 fma(dvec2, dvec2, dvec2);
        dvec3 fma(dvec3, dvec3, dvec3);
        dvec4 fma(dvec4, dvec4, dvec4);
      };
    }

    if (profile == glslang_profile_t.ES_PROFILE && version_ >= 310) {
      commonBuiltins ~= q{
        float64_t fma(float64_t, float64_t, float64_t);
        f64vec2 fma(f64vec2, f64vec2, f64vec2);
        f64vec3 fma(f64vec3, f64vec3, f64vec3);
        f64vec4 fma(f64vec4, f64vec4, f64vec4);
      };
    }

    if ((profile == glslang_profile_t.ES_PROFILE && version_ >= 310) ||
      (profile != glslang_profile_t.ES_PROFILE && version_ >= 150)) {
      commonBuiltins ~= q{
        float frexp(highp float, out highp int);
        vec2 frexp(highp vec2, out highp ivec2);
        vec3 frexp(highp vec3, out highp ivec3);
        vec4 frexp(highp vec4, out highp ivec4);

        float ldexp(highp float, highp int);
        vec2 ldexp(highp vec2, highp ivec2);
        vec3 ldexp(highp vec3, highp ivec3);
        vec4 ldexp(highp vec4, highp ivec4);
      };
    }

    if (profile != glslang_profile_t.ES_PROFILE && version_ >= 150) {
      commonBuiltins ~= q{
        double frexp(double, out int);
        dvec2 frexp(dvec2, out ivec2);
        dvec3 frexp(dvec3, out ivec3);
        dvec4 frexp(dvec4, out ivec4);

        double ldexp(double, int);
        dvec2 ldexp(dvec2, ivec2);
        dvec3 ldexp(dvec3, ivec3);
        dvec4 ldexp(dvec4, ivec4);

        double packDouble2x32(uvec2);
        uvec2 unpackDouble2x32(double);
      };
    }

    if (profile == glslang_profile_t.ES_PROFILE && version_ >= 310) {
      commonBuiltins ~= q{
        float64_t frexp(float64_t, out int);
        f64vec2 frexp(f64vec2, out ivec2);
        f64vec3 frexp(f64vec3, out ivec3);
        f64vec4 frexp(f64vec4, out ivec4);

        float64_t ldexp(float64_t, int);
        f64vec2 ldexp(f64vec2, ivec2);
        f64vec3 ldexp(f64vec3, ivec3);
        f64vec4 ldexp(f64vec4, ivec4);
      };
    }

    if ((profile == glslang_profile_t.ES_PROFILE && version_ >= 300) ||
      (profile != glslang_profile_t.ES_PROFILE && version_ >= 150)) {
      commonBuiltins ~= q{
        highp uint packUnorm2x16(vec2);
        vec2 unpackUnorm2x16(highp uint);
      };
    }

    if ((profile == glslang_profile_t.ES_PROFILE && version_ >= 300) ||
      (profile != glslang_profile_t.ES_PROFILE && version_ >= 150)) {
      commonBuiltins ~= q{
        highp uint packSnorm2x16(vec2);
        vec2 unpackSnorm2x16(highp uint);
        highp uint packHalf2x16(vec2);
      };
    }

    if (profile == glslang_profile_t.ES_PROFILE && version_ >= 300) {
      commonBuiltins ~= q{
        mediump vec2 unpackHalf2x16(highp uint);
      };
    } else if (profile != glslang_profile_t.ES_PROFILE && version_ >= 150) {
      commonBuiltins ~= q{
        vec2 unpackHalf2x16(highp uint);
      };
    }

    if ((profile == glslang_profile_t.ES_PROFILE && version_ >= 310) ||
      (profile != glslang_profile_t.ES_PROFILE && version_ >= 150)) {
      commonBuiltins ~= q{
        highp uint packSnorm4x8(vec4);
        highp uint packUnorm4x8(vec4);
      };
    }

    if (profile == glslang_profile_t.ES_PROFILE && version_ >= 310) {
      commonBuiltins ~= q{
        mediump vec4 unpackSnorm4x8(highp uint);
        mediump vec4 unpackUnorm4x8(highp uint);
      };
    } else if (profile != glslang_profile_t.ES_PROFILE && version_ >= 150) {
      commonBuiltins ~= q{
        vec4 unpackSnorm4x8(highp uint);
        vec4 unpackUnorm4x8(highp uint);
      };
    }

    commonBuiltins ~= q{
      mat2 matrixCompMult(mat2 x, mat2 y);
      mat3 matrixCompMult(mat3 x, mat3 y);
      mat4 matrixCompMult(mat4 x, mat4 y);
    };

    if (version_ >= 120) {
      commonBuiltins ~= q{
        mat2 outerProduct(vec2 c, vec2 r);
        mat3 outerProduct(vec3 c, vec3 r);
        mat4 outerProduct(vec4 c, vec4 r);
        mat2x3 outerProduct(vec3 c, vec2 r);
        mat3x2 outerProduct(vec2 c, vec3 r);
        mat2x4 outerProduct(vec4 c, vec2 r);
        mat4x2 outerProduct(vec2 c, vec4 r);
        mat3x4 outerProduct(vec4 c, vec3 r);
        mat4x3 outerProduct(vec3 c, vec4 r);

        mat2 transpose(mat2 m);
        mat3 transpose(mat3 m);
        mat4 transpose(mat4 m);
        mat2x3 transpose(mat3x2 m);
        mat3x2 transpose(mat2x3 m);
        mat2x4 transpose(mat4x2 m);
        mat4x2 transpose(mat2x4 m);
        mat3x4 transpose(mat4x3 m);
        mat4x3 transpose(mat3x4 m);

        mat2x3 matrixCompMult(mat2x3, mat2x3);
        mat2x4 matrixCompMult(mat2x4, mat2x4);
        mat3x2 matrixCompMult(mat3x2, mat3x2);
        mat3x4 matrixCompMult(mat3x4, mat3x4);
        mat4x2 matrixCompMult(mat4x2, mat4x2);
        mat4x3 matrixCompMult(mat4x3, mat4x3);
      };

      if (version_ >= 150) {
        commonBuiltins ~= q{
          float determinant(mat2 m);
          float determinant(mat3 m);
          float determinant(mat4 m);

          mat2 inverse(mat2 m);
          mat3 inverse(mat3 m);
          mat4 inverse(mat4 m);
        };
      }
    }

    if ((profile == glslang_profile_t.ES_PROFILE && version_ == 100) ||
      (profile == glslang_profile_t.CORE_PROFILE && version_ < 420) ||
      profile == glslang_profile_t.COMPATIBILITY_PROFILE ||
      profile == glslang_profile_t.NO_PROFILE) {
      if (spvVersion.spv == 0) {
        commonBuiltins ~= q{
          vec4 texture2D(sampler2D, vec2);

          vec4 texture2DProj(sampler2D, vec3);
          vec4 texture2DProj(sampler2D, vec4);

          vec4 texture3D(sampler3D, vec3);
          vec4 texture3DProj(sampler3D, vec4);

          vec4 textureCube(samplerCube, vec3);
        };
      }
    }

    if ((profile == glslang_profile_t.CORE_PROFILE && version_ < 420) ||
      profile == glslang_profile_t.COMPATIBILITY_PROFILE ||
      profile == glslang_profile_t.NO_PROFILE) {
      if (spvVersion.spv == 0) {
        commonBuiltins ~= q{
          "vec4 texture1D(sampler1D, float);"

          "vec4 texture1DProj(sampler1D, vec2);"
          "vec4 texture1DProj(sampler1D, vec4);"

          "vec4 shadow1D(sampler1DShadow, vec3);"
          "vec4 shadow2D(sampler2DShadow, vec3);"
          "vec4 shadow1DProj(sampler1DShadow, vec4);"
          "vec4 shadow2DProj(sampler2DShadow, vec4);"

          "vec4 texture2DRect(sampler2DRect, vec2);"
          "vec4 texture2DRectProj(sampler2DRect, vec3);"
          "vec4 texture2DRectProj(sampler2DRect, vec4);"
          "vec4 shadow2DRect(sampler2DRectShadow, vec3);"
          "vec4 shadow2DRectProj(sampler2DRectShadow, vec4);"

          "vec4 texture1DArray(sampler1DArray, vec2);"
          "vec4 texture2DArray(sampler2DArray, vec3);"
          "vec4 shadow1DArray(sampler1DArrayShadow, vec3);"
          "vec4 shadow2DArray(sampler2DArrayShadow, vec4);"
          "vec4 texture1DArray(sampler1DArray, vec2, float);"
          "vec4 texture2DArray(sampler2DArray, vec3, float);"
          "vec4 shadow1DArray(sampler1DArrayShadow, vec3, float);"
          "vec4 texture1DArrayLod(sampler1DArray, vec2, float);"
          "vec4 texture2DArrayLod(sampler2DArray, vec3, float);"
          "vec4 shadow1DArrayLod(sampler1DArrayShadow, vec3, float);"
        };
      }
    }

    if (profile == glslang_profile_t.ES_PROFILE) {
      if (spvVersion.spv == 0) {
        if (version_ < 300) {
          commonBuiltins ~= q{
            vec4 texture2D(samplerExternalOES, vec2 coord);
            vec4 texture2DProj(samplerExternalOES, vec3);
            vec4 texture2DProj(samplerExternalOES, vec4);
          };
        } else {
          commonBuiltins ~= q{
            highp ivec2 textureSize(samplerExternalOES, int lod);
            vec4 texture(samplerExternalOES, vec2);
            vec4 texture(samplerExternalOES, vec2, float bias);
            vec4 textureProj(samplerExternalOES, vec3);
            vec4 textureProj(samplerExternalOES, vec3, float bias);
            vec4 textureProj(samplerExternalOES, vec4);
            vec4 textureProj(samplerExternalOES, vec4, float bias);
            vec4 texelFetch(samplerExternalOES, ivec2, int lod);
          };
        }
        commonBuiltins ~= q{
          highp ivec2 textureSize(__samplerExternal2DY2YEXT, int lod);
          vec4 texture(__samplerExternal2DY2YEXT, vec2);
          vec4 texture(__samplerExternal2DY2YEXT, vec2, float bias);
          vec4 textureProj(__samplerExternal2DY2YEXT, vec3);
          vec4 textureProj(__samplerExternal2DY2YEXT, vec3, float bias);
          vec4 textureProj(__samplerExternal2DY2YEXT, vec4);
          vec4 textureProj(__samplerExternal2DY2YEXT, vec4, float bias);
          vec4 texelFetch(__samplerExternal2DY2YEXT sampler, ivec2, int lod);
        };
        commonBuiltins ~= q{
          vec4 texture2DGradEXT(sampler2D, vec2, vec2, vec2);
          vec4 texture2DProjGradEXT(sampler2D, vec3, vec2, vec2);
          vec4 texture2DProjGradEXT(sampler2D, vec4, vec2, vec2);
          vec4 textureCubeGradEXT(samplerCube, vec3, vec3, vec3);

          float shadow2DEXT(sampler2DShadow, vec3);
          float shadow2DProjEXT(sampler2DShadow, vec4);
        };
      }
    }

    if (spvVersion.spv == 0 && profile != glslang_profile_t.ES_PROFILE) {
      commonBuiltins ~= q{
        float noise1(float x);
        float noise1(vec2 x);
        float noise1(vec3 x);
        float noise1(vec4 x);

        vec2 noise2(float x);
        vec2 noise2(vec2 x);
        vec2 noise2(vec3 x);
        vec2 noise2(vec4 x);

        vec3 noise3(float x);
        vec3 noise3(vec2 x);
        vec3 noise3(vec3 x);
        vec3 noise3(vec4 x);

        vec4 noise4(float x);
        vec4 noise4(vec2 x);
        vec4 noise4(vec3 x);
        vec4 noise4(vec4 x);
      };
    }

    if (spvVersion.vulkan == 0) {
      if ((profile != glslang_profile_t.ES_PROFILE && version_ >= 300) ||
        (profile == glslang_profile_t.ES_PROFILE && version_ >= 310)) {
        commonBuiltins ~= q{
          uint atomicCounterIncrement(atomic_uint);
          uint atomicCounterDecrement(atomic_uint);
          uint atomicCounter(atomic_uint);
        };
      }
      if (profile != glslang_profile_t.ES_PROFILE && version_ == 450) {
        commonBuiltins ~= q{
          uint atomicCounterAddARB(atomic_uint, uint);
          uint atomicCounterSubtractARB(atomic_uint, uint);
          uint atomicCounterMinARB(atomic_uint, uint);
          uint atomicCounterMaxARB(atomic_uint, uint);
          uint atomicCounterAndARB(atomic_uint, uint);
          uint atomicCounterOrARB(atomic_uint, uint);
          uint atomicCounterXorARB(atomic_uint, uint);
          uint atomicCounterExchangeARB(atomic_uint, uint);
          uint atomicCounterCompSwapARB(atomic_uint, uint, uint);
        };
      }

      if (profile != glslang_profile_t.ES_PROFILE && version_ >= 460) {
        commonBuiltins ~= q{
          uint atomicCounterAdd(atomic_uint, uint);
          uint atomicCounterSubtract(atomic_uint, uint);
          uint atomicCounterMin(atomic_uint, uint);
          uint atomicCounterMax(atomic_uint, uint);
          uint atomicCounterAnd(atomic_uint, uint);
          uint atomicCounterOr(atomic_uint, uint);
          uint atomicCounterXor(atomic_uint, uint);
          uint atomicCounterExchange(atomic_uint, uint);
          uint atomicCounterCompSwap(atomic_uint, uint, uint);
        };
      }
    } else if (spvVersion.vulkanRelaxed) {
      if ((profile != glslang_profile_t.ES_PROFILE && version_ >= 300) ||
        (profile == glslang_profile_t.ES_PROFILE && version_ >= 310)) {
        commonBuiltins ~= q{
          uint atomicCounterIncrement(volatile coherent nontemporal uint);
          uint atomicCounterDecrement(volatile coherent nontemporal uint);
          uint atomicCounter(volatile coherent nontemporal uint);
        };
      }
      if (profile != glslang_profile_t.ES_PROFILE && version_ >= 460) {
        commonBuiltins ~= q{
          uint atomicCounterAdd(volatile coherent nontemporal uint, uint);
          uint atomicCounterSubtract(volatile coherent nontemporal uint, uint);
          uint atomicCounterMin(volatile coherent nontemporal uint, uint);
          uint atomicCounterMax(volatile coherent nontemporal uint, uint);
          uint atomicCounterAnd(volatile coherent nontemporal uint, uint);
          uint atomicCounterOr(volatile coherent nontemporal uint, uint);
          uint atomicCounterXor(volatile coherent nontemporal uint, uint);
          uint atomicCounterExchange(volatile coherent nontemporal uint, uint);
          uint atomicCounterCompSwap(volatile coherent nontemporal uint, uint, uint);
        };
      }
    }

    if ((profile == glslang_profile_t.ES_PROFILE && version_ >= 310) ||
      (profile != glslang_profile_t.ES_PROFILE && version_ >= 150)) {
      commonBuiltins ~= q{
        int bitfieldExtract(int, int, int);
        ivec2 bitfieldExtract(ivec2, int, int);
        ivec3 bitfieldExtract(ivec3, int, int);
        ivec4 bitfieldExtract(ivec4, int, int);

        uint bitfieldExtract(uint, int, int);
        uvec2 bitfieldExtract(uvec2, int, int);
        uvec3 bitfieldExtract(uvec3, int, int);
        uvec4 bitfieldExtract(uvec4, int, int);

        int bitfieldInsert(int base, int, int, int);
        ivec2 bitfieldInsert(ivec2 base, ivec2, int, int);
        ivec3 bitfieldInsert(ivec3 base, ivec3, int, int);
        ivec4 bitfieldInsert(ivec4 base, ivec4, int, int);

        uint bitfieldInsert(uint base, uint, int, int);
        uvec2 bitfieldInsert(uvec2 base, uvec2, int, int);
        uvec3 bitfieldInsert(uvec3 base, uvec3, int, int);
        uvec4 bitfieldInsert(uvec4 base, uvec4, int, int);
      };
    }

    if (profile != glslang_profile_t.ES_PROFILE && version_ >= 150) {
      commonBuiltins ~= q{
        int findLSB(int);
        ivec2 findLSB(ivec2);
        ivec3 findLSB(ivec3);
        ivec4 findLSB(ivec4);

        int findLSB(uint);
        ivec2 findLSB(uvec2);
        ivec3 findLSB(uvec3);
        ivec4 findLSB(uvec4);
      };
    } else if (profile == glslang_profile_t.ES_PROFILE && version_ >= 310) {
      commonBuiltins ~= q{
        lowp int findLSB(int);
        lowp ivec2 findLSB(ivec2);
        lowp ivec3 findLSB(ivec3);
        lowp ivec4 findLSB(ivec4);

        lowp int findLSB(uint);
        lowp ivec2 findLSB(uvec2);
        lowp ivec3 findLSB(uvec3);
        lowp ivec4 findLSB(uvec4);
      };
    }

    if (profile != glslang_profile_t.ES_PROFILE && version_ >= 150) {
      commonBuiltins ~= q{
        int bitCount(int);
        ivec2 bitCount(ivec2);
        ivec3 bitCount(ivec3);
        ivec4 bitCount(ivec4);

        int bitCount(uint);
        ivec2 bitCount(uvec2);
        ivec3 bitCount(uvec3);
        ivec4 bitCount(uvec4);

        int findMSB(highp int);
        ivec2 findMSB(highp ivec2);
        ivec3 findMSB(highp ivec3);
        ivec4 findMSB(highp ivec4);

        int findMSB(highp uint);
        ivec2 findMSB(highp uvec2);
        ivec3 findMSB(highp uvec3);
        ivec4 findMSB(highp uvec4);
      };
    }

    if (profile != glslang_profile_t.ES_PROFILE && version_ >= 150 && version_ < 450) {
      commonBuiltins ~= q{
        int64_t packInt2x32(ivec2);
        uint64_t packUint2x32(uvec2);
        ivec2 unpackInt2x32(int64_t);
        uvec2 unpackUint2x32(uint64_t);

        uint packFloat2x16(f16vec2);
        f16vec2 unpackFloat2x16(uint);

        int64_t doubleBitsToInt64(double);
        i64vec2 doubleBitsToInt64(dvec2);
        i64vec3 doubleBitsToInt64(dvec3);
        i64vec4 doubleBitsToInt64(dvec4);

        uint64_t doubleBitsToUint64(double);
        u64vec2 doubleBitsToUint64(dvec2);
        u64vec3 doubleBitsToUint64(dvec3);
        u64vec4 doubleBitsToUint64(dvec4);

        double int64BitsToDouble(int64_t);
        dvec2 int64BitsToDouble(i64vec2);
        dvec3 int64BitsToDouble(i64vec3);
        dvec4 int64BitsToDouble(i64vec4);

        double uint64BitsToDouble(uint64_t);
        dvec2 uint64BitsToDouble(u64vec2);
        dvec3 uint64BitsToDouble(u64vec3);
        dvec4 uint64BitsToDouble(u64vec4);

        bvec2 lessThan(i64vec2, i64vec2);
        bvec3 lessThan(i64vec3, i64vec3);
        bvec4 lessThan(i64vec4, i64vec4);
        bvec2 lessThan(u64vec2, u64vec2);
        bvec3 lessThan(u64vec3, u64vec3);
        bvec4 lessThan(u64vec4, u64vec4);

        bvec2 lessThanEqual(i64vec2, i64vec2);
        bvec3 lessThanEqual(i64vec3, i64vec3);
        bvec4 lessThanEqual(i64vec4, i64vec4);
        bvec2 lessThanEqual(u64vec2, u64vec2);
        bvec3 lessThanEqual(u64vec3, u64vec3);
        bvec4 lessThanEqual(u64vec4, u64vec4);

        bvec2 greaterThan(i64vec2, i64vec2);
        bvec3 greaterThan(i64vec3, i64vec3);
        bvec4 greaterThan(i64vec4, i64vec4);
        bvec2 greaterThan(u64vec2, u64vec2);
        bvec3 greaterThan(u64vec3, u64vec3);
        bvec4 greaterThan(u64vec4, u64vec4);

        bvec2 greaterThanEqual(i64vec2, i64vec2);
        bvec3 greaterThanEqual(i64vec3, i64vec3);
        bvec4 greaterThanEqual(i64vec4, i64vec4);
        bvec2 greaterThanEqual(u64vec2, u64vec2);
        bvec3 greaterThanEqual(u64vec3, u64vec3);
        bvec4 greaterThanEqual(u64vec4, u64vec4);

        bvec2 equal(i64vec2, i64vec2);
        bvec3 equal(i64vec3, i64vec3);
        bvec4 equal(i64vec4, i64vec4);
        bvec2 equal(u64vec2, u64vec2);
        bvec3 equal(u64vec3, u64vec3);
        bvec4 equal(u64vec4, u64vec4);

        bvec2 notEqual(i64vec2, i64vec2);
        bvec3 notEqual(i64vec3, i64vec3);
        bvec4 notEqual(i64vec4, i64vec4);
        bvec2 notEqual(u64vec2, u64vec2);
        bvec3 notEqual(u64vec3, u64vec3);
        bvec4 notEqual(u64vec4, u64vec4);

        bvec2 lessThan(f16vec2, f16vec2);
        bvec3 lessThan(f16vec3, f16vec3);
        bvec4 lessThan(f16vec4, f16vec4);

        bvec2 lessThanEqual(f16vec2, f16vec2);
        bvec3 lessThanEqual(f16vec3, f16vec3);
        bvec4 lessThanEqual(f16vec4, f16vec4);

        bvec2 greaterThan(f16vec2, f16vec2);
        bvec3 greaterThan(f16vec3, f16vec3);
        bvec4 greaterThan(f16vec4, f16vec4);

        bvec2 greaterThanEqual(f16vec2, f16vec2);
        bvec3 greaterThanEqual(f16vec3, f16vec3);
        bvec4 greaterThanEqual(f16vec4, f16vec4);

        bvec2 equal(f16vec2, f16vec2);
        bvec3 equal(f16vec3, f16vec3);
        bvec4 equal(f16vec4, f16vec4);

        bvec2 notEqual(f16vec2, f16vec2);
        bvec3 notEqual(f16vec3, f16vec3);
        bvec4 notEqual(f16vec4, f16vec4);

        bvec2 lessThan(dvec2, dvec2);
        bvec3 lessThan(dvec3, dvec3);
        bvec4 lessThan(dvec4, dvec4);

        bvec2 lessThanEqual(dvec2, dvec2);
        bvec3 lessThanEqual(dvec3, dvec3);
        bvec4 lessThanEqual(dvec4, dvec4);

        bvec2 greaterThan(dvec2, dvec2);
        bvec3 greaterThan(dvec3, dvec3);
        bvec4 greaterThan(dvec4, dvec4);

        bvec2 greaterThanEqual(dvec2, dvec2);
        bvec3 greaterThanEqual(dvec3, dvec3);
        bvec4 greaterThanEqual(dvec4, dvec4);

        bvec2 equal(dvec2, dvec2);
        bvec3 equal(dvec3, dvec3);
        bvec4 equal(dvec4, dvec4);

        bvec2 notEqual(dvec2, dvec2);
        bvec3 notEqual(dvec3, dvec3);
        bvec4 notEqual(dvec4, dvec4);
      };
    }

    if (profile != glslang_profile_t.ES_PROFILE && version_ >= 150) {
      commonBuiltins ~= q{
        bool anyThreadNV(bool);
        bool allThreadsNV(bool);
        bool allThreadsEqualNV(bool);
      };
    }

    if ((profile == glslang_profile_t.ES_PROFILE && version_ >= 310) ||
      (profile != glslang_profile_t.ES_PROFILE && version_ >= 150)) {
      commonBuiltins ~= q{
        uint uaddCarry(highp uint, highp uint, out lowp uint carry);
        uvec2 uaddCarry(highp uvec2, highp uvec2, out lowp uvec2 carry);
        uvec3 uaddCarry(highp uvec3, highp uvec3, out lowp uvec3 carry);
        uvec4 uaddCarry(highp uvec4, highp uvec4, out lowp uvec4 carry);

        uint usubBorrow(highp uint, highp uint, out lowp uint borrow);
        uvec2 usubBorrow(highp uvec2, highp uvec2, out lowp uvec2 borrow);
        uvec3 usubBorrow(highp uvec3, highp uvec3, out lowp uvec3 borrow);
        uvec4 usubBorrow(highp uvec4, highp uvec4, out lowp uvec4 borrow);

        void umulExtended(highp uint, highp uint, out highp uint, out highp uint lsb);
        void umulExtended(highp uvec2, highp uvec2, out highp uvec2, out highp uvec2 lsb);
        void umulExtended(highp uvec3, highp uvec3, out highp uvec3, out highp uvec3 lsb);
        void umulExtended(highp uvec4, highp uvec4, out highp uvec4, out highp uvec4 lsb);

        void imulExtended(highp int, highp int, out highp int, out highp int lsb);
        void imulExtended(highp ivec2, highp ivec2, out highp ivec2, out highp ivec2 lsb);
        void imulExtended(highp ivec3, highp ivec3, out highp ivec3, out highp ivec3 lsb);
        void imulExtended(highp ivec4, highp ivec4, out highp ivec4, out highp ivec4 lsb);

        int bitfieldReverse(highp int);
        ivec2 bitfieldReverse(highp ivec2);
        ivec3 bitfieldReverse(highp ivec3);
        ivec4 bitfieldReverse(highp ivec4);

        uint bitfieldReverse(highp uint);
        uvec2 bitfieldReverse(highp uvec2);
        uvec3 bitfieldReverse(highp uvec3);
        uvec4 bitfieldReverse(highp uvec4);
      };
    }

    if (profile == glslang_profile_t.ES_PROFILE && version_ >= 310) {
      commonBuiltins ~= q{
        lowp int bitCount(int);
        lowp ivec2 bitCount(ivec2);
        lowp ivec3 bitCount(ivec3);
        lowp ivec4 bitCount(ivec4);

        lowp int bitCount(uint);
        lowp ivec2 bitCount(uvec2);
        lowp ivec3 bitCount(uvec3);
        lowp ivec4 bitCount(uvec4);

        lowp int findMSB(highp int);
        lowp ivec2 findMSB(highp ivec2);
        lowp ivec3 findMSB(highp ivec3);
        lowp ivec4 findMSB(highp ivec4);

        lowp int findMSB(highp uint);
        lowp ivec2 findMSB(highp uvec2);
        lowp ivec3 findMSB(highp uvec3);
        lowp ivec4 findMSB(highp uvec4);
      };
    }

    if (profile != glslang_profile_t.ES_PROFILE && version_ >= 450) {
      commonBuiltins ~= q{
        uint64_t ballotARB(bool);

        float readInvocationARB(float, uint);
        vec2 readInvocationARB(vec2, uint);
        vec3 readInvocationARB(vec3, uint);
        vec4 readInvocationARB(vec4, uint);

        int readInvocationARB(int, uint);
        ivec2 readInvocationARB(ivec2, uint);
        ivec3 readInvocationARB(ivec3, uint);
        ivec4 readInvocationARB(ivec4, uint);

        uint readInvocationARB(uint, uint);
        uvec2 readInvocationARB(uvec2, uint);
        uvec3 readInvocationARB(uvec3, uint);
        uvec4 readInvocationARB(uvec4, uint);

        float readFirstInvocationARB(float);
        vec2 readFirstInvocationARB(vec2);
        vec3 readFirstInvocationARB(vec3);
        vec4 readFirstInvocationARB(vec4);

        int readFirstInvocationARB(int);
        ivec2 readFirstInvocationARB(ivec2);
        ivec3 readFirstInvocationARB(ivec3);
        ivec4 readFirstInvocationARB(ivec4);

        uint readFirstInvocationARB(uint);
        uvec2 readFirstInvocationARB(uvec2);
        uvec3 readFirstInvocationARB(uvec3);
        uvec4 readFirstInvocationARB(uvec4);
      };
    }

    if (profile != glslang_profile_t.ES_PROFILE && version_ >= 430) {
      commonBuiltins ~= q{
        bool anyInvocationARB(bool);
        bool allInvocationsARB(bool);
        bool allInvocationsEqualARB(bool);
      };
    }

    if ((profile == glslang_profile_t.ES_PROFILE && version_ >= 300) ||
      (profile != glslang_profile_t.ES_PROFILE && version_ >= 450)) {
      commonBuiltins ~= q{
        uint dotEXT(uvec2 a, uvec2 b);
        int dotEXT(ivec2 a, ivec2 b);
        int dotEXT(ivec2 a, uvec2 b);
        int dotEXT(uvec2 a, ivec2 b);

        uint dotEXT(uvec3 a, uvec3 b);
        int dotEXT(ivec3 a, ivec3 b);
        int dotEXT(ivec3 a, uvec3 b);
        int dotEXT(uvec3 a, ivec3 b);

        uint dotEXT(uvec4 a, uvec4 b);
        int dotEXT(ivec4 a, ivec4 b);
        int dotEXT(ivec4 a, uvec4 b);
        int dotEXT(uvec4 a, ivec4 b);

        uint dotPacked4x8EXT(uint a, uint b);
        int dotPacked4x8EXT(int a, uint b);
        int dotPacked4x8EXT(uint a, int b);
        int dotPacked4x8EXT(int a, int b);

        uint dotEXT(u8vec2 a, u8vec2 b);
        int dotEXT(i8vec2 a, u8vec2 b);
        int dotEXT(u8vec2 a, i8vec2 b);
        int dotEXT(i8vec2 a, i8vec2 b);

        uint dotEXT(u8vec3 a, u8vec3 b);
        int dotEXT(i8vec3 a, u8vec3 b);
        int dotEXT(u8vec3 a, i8vec3 b);
        int dotEXT(i8vec3 a, i8vec3 b);

        uint dotEXT(u8vec4 a, u8vec4 b);
        int dotEXT(i8vec4 a, u8vec4 b);
        int dotEXT(u8vec4 a, i8vec4 b);
        int dotEXT(i8vec4 a, i8vec4 b);

        uint dotEXT(u16vec2 a, u16vec2 b);
        int dotEXT(i16vec2 a, u16vec2 b);
        int dotEXT(u16vec2 a, i16vec2 b);
        int dotEXT(i16vec2 a, i16vec2 b);

        uint dotEXT(u16vec3 a, u16vec3 b);
        int dotEXT(i16vec3 a, u16vec3 b);
        int dotEXT(u16vec3 a, i16vec3 b);
        int dotEXT(i16vec3 a, i16vec3 b);

        uint dotEXT(u16vec4 a, u16vec4 b);
        int dotEXT(i16vec4 a, u16vec4 b);
        int dotEXT(u16vec4 a, i16vec4 b);
        int dotEXT(i16vec4 a, i16vec4 b);

        uint64_t dotEXT(u64vec2 a, u64vec2 b);
        int64_t dotEXT(i64vec2 a, u64vec2 b);
        int64_t dotEXT(u64vec2 a, i64vec2 b);
        int64_t dotEXT(i64vec2 a, i64vec2 b);

        uint64_t dotEXT(u64vec3 a, u64vec3 b);
        int64_t dotEXT(i64vec3 a, u64vec3 b);
        int64_t dotEXT(u64vec3 a, i64vec3 b);
        int64_t dotEXT(i64vec3 a, i64vec3 b);

        uint64_t dotEXT(u64vec4 a, u64vec4 b);
        int64_t dotEXT(i64vec4 a, u64vec4 b);
        int64_t dotEXT(u64vec4 a, i64vec4 b);
        int64_t dotEXT(i64vec4 a, i64vec4 b);

        uint dotAccSatEXT(uvec2 a, uvec2 b, uint c);
        int dotAccSatEXT(ivec2 a, uvec2 b, int c);
        int dotAccSatEXT(uvec2 a, ivec2 b, int c);
        int dotAccSatEXT(ivec2 a, ivec2 b, int c);

        uint dotAccSatEXT(uvec3 a, uvec3 b, uint c);
        int dotAccSatEXT(ivec3 a, uvec3 b, int c);
        int dotAccSatEXT(uvec3 a, ivec3 b, int c);
        int dotAccSatEXT(ivec3 a, ivec3 b, int c);

        uint dotAccSatEXT(uvec4 a, uvec4 b, uint c);
        int dotAccSatEXT(ivec4 a, uvec4 b, int c);
        int dotAccSatEXT(uvec4 a, ivec4 b, int c);
        int dotAccSatEXT(ivec4 a, ivec4 b, int c);

        uint dotPacked4x8AccSatEXT(uint a, uint b, uint c);
        int dotPacked4x8AccSatEXT(int a, uint b, int c);
        int dotPacked4x8AccSatEXT(uint a, int b, int c);
        int dotPacked4x8AccSatEXT(int a, int b, int c);

        uint dotAccSatEXT(u8vec2 a, u8vec2 b, uint c);
        int dotAccSatEXT(i8vec2 a, u8vec2 b, int c);
        int dotAccSatEXT(u8vec2 a, i8vec2 b, int c);
        int dotAccSatEXT(i8vec2 a, i8vec2 b, int c);

        uint dotAccSatEXT(u8vec3 a, u8vec3 b, uint c);
        int dotAccSatEXT(i8vec3 a, u8vec3 b, int c);
        int dotAccSatEXT(u8vec3 a, i8vec3 b, int c);
        int dotAccSatEXT(i8vec3 a, i8vec3 b, int c);

        uint dotAccSatEXT(u8vec4 a, u8vec4 b, uint c);
        int dotAccSatEXT(i8vec4 a, u8vec4 b, int c);
        int dotAccSatEXT(u8vec4 a, i8vec4 b, int c);
        int dotAccSatEXT(i8vec4 a, i8vec4 b, int c);

        uint dotAccSatEXT(u16vec2 a, u16vec2 b, uint c);
        int dotAccSatEXT(i16vec2 a, u16vec2 b, int c);
        int dotAccSatEXT(u16vec2 a, i16vec2 b, int c);
        int dotAccSatEXT(i16vec2 a, i16vec2 b, int c);

        uint dotAccSatEXT(u16vec3 a, u16vec3 b, uint c);
        int dotAccSatEXT(i16vec3 a, u16vec3 b, int c);
        int dotAccSatEXT(u16vec3 a, i16vec3 b, int c);
        int dotAccSatEXT(i16vec3 a, i16vec3 b, int c);

        uint dotAccSatEXT(u16vec4 a, u16vec4 b, uint c);
        int dotAccSatEXT(i16vec4 a, u16vec4 b, int c);
        int dotAccSatEXT(u16vec4 a, i16vec4 b, int c);
        int dotAccSatEXT(i16vec4 a, i16vec4 b, int c);

        uint64_t dotAccSatEXT(u64vec2 a, u64vec2 b, uint64_t c);
        int64_t dotAccSatEXT(i64vec2 a, u64vec2 b, int64_t c);
        int64_t dotAccSatEXT(u64vec2 a, i64vec2 b, int64_t c);
        int64_t dotAccSatEXT(i64vec2 a, i64vec2 b, int64_t c);

        uint64_t dotAccSatEXT(u64vec3 a, u64vec3 b, uint64_t c);
        int64_t dotAccSatEXT(i64vec3 a, u64vec3 b, int64_t c);
        int64_t dotAccSatEXT(u64vec3 a, i64vec3 b, int64_t c);
        int64_t dotAccSatEXT(i64vec3 a, i64vec3 b, int64_t c);

        uint64_t dotAccSatEXT(u64vec4 a, u64vec4 b, uint64_t c);
        int64_t dotAccSatEXT(i64vec4 a, u64vec4 b, int64_t c);
        int64_t dotAccSatEXT(u64vec4 a, i64vec4 b, int64_t c);
        int64_t dotAccSatEXT(i64vec4 a, i64vec4 b, int64_t c);
      };
    }

    if ((profile == glslang_profile_t.ES_PROFILE && version_ >= 310) ||
      (profile != glslang_profile_t.ES_PROFILE && version_ >= 140)) {
      commonBuiltins ~= q{
        void subgroupBarrier();
        void subgroupMemoryBarrier();
        void subgroupMemoryBarrierBuffer();
        void subgroupMemoryBarrierImage();
        bool subgroupElect();

        bool subgroupAll(bool);
        bool subgroupAny(bool);
        uvec4 subgroupBallot(bool);
        bool subgroupInverseBallot(uvec4);
        bool subgroupBallotBitExtract(uvec4, uint);
        uint subgroupBallotBitCount(uvec4);
        uint subgroupBallotInclusiveBitCount(uvec4);
        uint subgroupBallotExclusiveBitCount(uvec4);
        uint subgroupBallotFindLSB(uvec4);
        uint subgroupBallotFindMSB(uvec4);
      };

      enum string[] subgroupOps = [
        "bool subgroupAllEqual(%s);\n",
        "%s subgroupBroadcast(%s, uint);\n",
        "%s subgroupBroadcastFirst(%s);\n",
        "%s subgroupShuffle(%s, uint);\n",
        "%s subgroupShuffleXor(%s, uint);\n",
        "%s subgroupShuffleUp(%s, uint delta);\n",
        "%s subgroupShuffleDown(%s, uint delta);\n",
        "%s subgroupRotate(%s, uint);\n",
        "%s subgroupClusteredRotate(%s, uint, uint);\n",
        "%s subgroupAdd(%s);\n",
        "%s subgroupMul(%s);\n",
        "%s subgroupMin(%s);\n",
        "%s subgroupMax(%s);\n",
        "%s subgroupAnd(%s);\n",
        "%s subgroupOr(%s);\n",
        "%s subgroupXor(%s);\n",
        "%s subgroupInclusiveAdd(%s);\n",
        "%s subgroupInclusiveMul(%s);\n",
        "%s subgroupInclusiveMin(%s);\n",
        "%s subgroupInclusiveMax(%s);\n",
        "%s subgroupInclusiveAnd(%s);\n",
        "%s subgroupInclusiveOr(%s);\n",
        "%s subgroupInclusiveXor(%s);\n",
        "%s subgroupExclusiveAdd(%s);\n",
        "%s subgroupExclusiveMul(%s);\n",
        "%s subgroupExclusiveMin(%s);\n",
        "%s subgroupExclusiveMax(%s);\n",
        "%s subgroupExclusiveAnd(%s);\n",
        "%s subgroupExclusiveOr(%s);\n",
        "%s subgroupExclusiveXor(%s);\n",
        "%s subgroupClusteredAdd(%s, uint);\n",
        "%s subgroupClusteredMul(%s, uint);\n",
        "%s subgroupClusteredMin(%s, uint);\n",
        "%s subgroupClusteredMax(%s, uint);\n",
        "%s subgroupClusteredAnd(%s, uint);\n",
        "%s subgroupClusteredOr(%s, uint);\n",
        "%s subgroupClusteredXor(%s, uint);\n",
        "%s subgroupQuadBroadcast(%s, uint);\n",
        "%s subgroupQuadSwapHorizontal(%s);\n",
        "%s subgroupQuadSwapVertical(%s);\n",
        "%s subgroupQuadSwapDiagonal(%s);\n",
        "uvec4 subgroupPartitionNV(%s);\n",
        "%s subgroupPartitionedAddNV(%s, uvec4 ballot);\n",
        "%s subgroupPartitionedMulNV(%s, uvec4 ballot);\n",
        "%s subgroupPartitionedMinNV(%s, uvec4 ballot);\n",
        "%s subgroupPartitionedMaxNV(%s, uvec4 ballot);\n",
        "%s subgroupPartitionedAndNV(%s, uvec4 ballot);\n",
        "%s subgroupPartitionedOrNV(%s, uvec4 ballot);\n",
        "%s subgroupPartitionedXorNV(%s, uvec4 ballot);\n",
        "%s subgroupPartitionedInclusiveAddNV(%s, uvec4 ballot);\n",
        "%s subgroupPartitionedInclusiveMulNV(%s, uvec4 ballot);\n",
        "%s subgroupPartitionedInclusiveMinNV(%s, uvec4 ballot);\n",
        "%s subgroupPartitionedInclusiveMaxNV(%s, uvec4 ballot);\n",
        "%s subgroupPartitionedInclusiveAndNV(%s, uvec4 ballot);\n",
        "%s subgroupPartitionedInclusiveOrNV(%s, uvec4 ballot);\n",
        "%s subgroupPartitionedInclusiveXorNV(%s, uvec4 ballot);\n",
        "%s subgroupPartitionedExclusiveAddNV(%s, uvec4 ballot);\n",
        "%s subgroupPartitionedExclusiveMulNV(%s, uvec4 ballot);\n",
        "%s subgroupPartitionedExclusiveMinNV(%s, uvec4 ballot);\n",
        "%s subgroupPartitionedExclusiveMaxNV(%s, uvec4 ballot);\n",
        "%s subgroupPartitionedExclusiveAndNV(%s, uvec4 ballot);\n",
        "%s subgroupPartitionedExclusiveOrNV(%s, uvec4 ballot);\n",
        "%s subgroupPartitionedExclusiveXorNV(%s, uvec4 ballot);\n",
      ];

      enum string[] floatTypes = [
        "float", "vec2", "vec3", "vec4",
        "float16_t", "f16vec2", "f16vec3", "f16vec4"
      ];
      enum string[] doubleTypes = [
        "double", "dvec2", "dvec3", "dvec4"
      ];
      enum string[] intTypes = [
        "int8_t", "i8vec2", "i8vec3", "i8vec4", 
        "int16_t", "i16vec2", "i16vec3", "i16vec4", 
        "int", "ivec2", "ivec3", "ivec4", 
        "int64_t", "i64vec2", "i64vec3", "i64vec4", 
        "uint8_t", "u8vec2", "u8vec3", "u8vec4", 
        "uint16_t", "u16vec2", "u16vec3", "u16vec4", 
        "uint", "uvec2", "uvec3", "uvec4", 
        "uint64_t", "u64vec2", "u64vec3", "u64vec4"
      ];
      enum string[] boolTypes = [
        "bool", "bvec2", "bvec3", "bvec4"
      ];

      foreach (op; subgroupOps) {
        bool logicalOp = canFind(op, "Or") || canFind(op, "And") ||
          (canFind(op, "Xor") && !canFind(op, "ShuffleXor"));
        bool mathOp = canFind(op, "Add") || canFind(op, "Mul") ||
          canFind(op, "Min") || canFind(op, "Max");

        Appender!(char[]) buf = appender!(char[]);

        if (!logicalOp) {
          foreach (floatType; floatTypes) {
            formattedWrite(buf, op, floatType, floatType);
            commonBuiltins ~= buf[];
            buf.clear;
          }
          if (profile != glslang_profile_t.ES_PROFILE && version_ >= 400) {
            foreach (doubleType; doubleTypes) {
              formattedWrite(buf, op, doubleType, doubleType);
              commonBuiltins ~= buf[];
              buf.clear;
            }
          }
        }
        if (!mathOp) {
          foreach (boolType; boolTypes) {
            formattedWrite(buf, op, boolType, boolType);
            commonBuiltins ~= buf[];
            buf.clear;
          }
        }
        foreach (intType; intTypes) {
          formattedWrite(buf, op, intType, intType);
          commonBuiltins ~= buf[];
          buf.clear;
        }
      }

      stageBuiltins[glslang_stage_t.STAGE_COMPUTE] ~= q{
        void subgroupMemoryBarrierShared();
      };
      stageBuiltins[glslang_stage_t.STAGE_MESH] ~= q{
        void subgroupMemoryBarrierShared();
      };
      stageBuiltins[glslang_stage_t.STAGE_TASK] ~= q{
        void subgroupMemoryBarrierShared();
      };
    }

    if ((profile == glslang_profile_t.ES_PROFILE && version_ >= 310) ||
      (profile != glslang_profile_t.ES_PROFILE && version_ >= 140)) {
      commonBuiltins ~= q{
        bool subgroupQuadAll(bool);
        bool subgroupQuadAny(bool);
      };   
    }

    if (profile != glslang_profile_t.ES_PROFILE && version_ >= 460) {
      commonBuiltins ~= q{
        bool anyInvocation(bool);
        bool allInvocations(bool);
        bool allInvocationsEqual(bool);
      };
    }

    if (profile != glslang_profile_t.ES_PROFILE && version_ >= 450) {
      commonBuiltins ~= q{
        float minInvocationsAMD(float);
        vec2 minInvocationsAMD(vec2);
        vec3 minInvocationsAMD(vec3);
        vec4 minInvocationsAMD(vec4);

        int minInvocationsAMD(int);
        ivec2 minInvocationsAMD(ivec2);
        ivec3 minInvocationsAMD(ivec3);
        ivec4 minInvocationsAMD(ivec4);

        uint minInvocationsAMD(uint);
        uvec2 minInvocationsAMD(uvec2);
        uvec3 minInvocationsAMD(uvec3);
        uvec4 minInvocationsAMD(uvec4);

        double minInvocationsAMD(double);
        dvec2 minInvocationsAMD(dvec2);
        dvec3 minInvocationsAMD(dvec3);
        dvec4 minInvocationsAMD(dvec4);

        int64_t minInvocationsAMD(int64_t);
        i64vec2 minInvocationsAMD(i64vec2);
        i64vec3 minInvocationsAMD(i64vec3);
        i64vec4 minInvocationsAMD(i64vec4);

        uint64_t minInvocationsAMD(uint64_t);
        u64vec2 minInvocationsAMD(u64vec2);
        u64vec3 minInvocationsAMD(u64vec3);
        u64vec4 minInvocationsAMD(u64vec4);

        float16_t minInvocationsAMD(float16_t);
        f16vec2 minInvocationsAMD(f16vec2);
        f16vec3 minInvocationsAMD(f16vec3);
        f16vec4 minInvocationsAMD(f16vec4);

        int16_t minInvocationsAMD(int16_t);
        i16vec2 minInvocationsAMD(i16vec2);
        i16vec3 minInvocationsAMD(i16vec3);
        i16vec4 minInvocationsAMD(i16vec4);

        uint16_t minInvocationsAMD(uint16_t);
        u16vec2 minInvocationsAMD(u16vec2);
        u16vec3 minInvocationsAMD(u16vec3);
        u16vec4 minInvocationsAMD(u16vec4);

        float minInvocationsInclusiveScanAMD(float);
        vec2 minInvocationsInclusiveScanAMD(vec2);
        vec3 minInvocationsInclusiveScanAMD(vec3);
        vec4 minInvocationsInclusiveScanAMD(vec4);

        int minInvocationsInclusiveScanAMD(int);
        ivec2 minInvocationsInclusiveScanAMD(ivec2);
        ivec3 minInvocationsInclusiveScanAMD(ivec3);
        ivec4 minInvocationsInclusiveScanAMD(ivec4);

        uint minInvocationsInclusiveScanAMD(uint);
        uvec2 minInvocationsInclusiveScanAMD(uvec2);
        uvec3 minInvocationsInclusiveScanAMD(uvec3);
        uvec4 minInvocationsInclusiveScanAMD(uvec4);

        double minInvocationsInclusiveScanAMD(double);
        dvec2 minInvocationsInclusiveScanAMD(dvec2);
        dvec3 minInvocationsInclusiveScanAMD(dvec3);
        dvec4 minInvocationsInclusiveScanAMD(dvec4);

        int64_t minInvocationsInclusiveScanAMD(int64_t);
        i64vec2 minInvocationsInclusiveScanAMD(i64vec2);
        i64vec3 minInvocationsInclusiveScanAMD(i64vec3);
        i64vec4 minInvocationsInclusiveScanAMD(i64vec4);

        uint64_t minInvocationsInclusiveScanAMD(uint64_t);
        u64vec2 minInvocationsInclusiveScanAMD(u64vec2);
        u64vec3 minInvocationsInclusiveScanAMD(u64vec3);
        u64vec4 minInvocationsInclusiveScanAMD(u64vec4);

        float16_t minInvocationsInclusiveScanAMD(float16_t);
        f16vec2 minInvocationsInclusiveScanAMD(f16vec2);
        f16vec3 minInvocationsInclusiveScanAMD(f16vec3);
        f16vec4 minInvocationsInclusiveScanAMD(f16vec4);

        int16_t minInvocationsInclusiveScanAMD(int16_t);
        i16vec2 minInvocationsInclusiveScanAMD(i16vec2);
        i16vec3 minInvocationsInclusiveScanAMD(i16vec3);
        i16vec4 minInvocationsInclusiveScanAMD(i16vec4);

        uint16_t minInvocationsInclusiveScanAMD(uint16_t);
        u16vec2 minInvocationsInclusiveScanAMD(u16vec2);
        u16vec3 minInvocationsInclusiveScanAMD(u16vec3);
        u16vec4 minInvocationsInclusiveScanAMD(u16vec4);

        float minInvocationsExclusiveScanAMD(float);
        vec2 minInvocationsExclusiveScanAMD(vec2);
        vec3 minInvocationsExclusiveScanAMD(vec3);
        vec4 minInvocationsExclusiveScanAMD(vec4);

        int minInvocationsExclusiveScanAMD(int);
        ivec2 minInvocationsExclusiveScanAMD(ivec2);
        ivec3 minInvocationsExclusiveScanAMD(ivec3);
        ivec4 minInvocationsExclusiveScanAMD(ivec4);

        uint minInvocationsExclusiveScanAMD(uint);
        uvec2 minInvocationsExclusiveScanAMD(uvec2);
        uvec3 minInvocationsExclusiveScanAMD(uvec3);
        uvec4 minInvocationsExclusiveScanAMD(uvec4);

        double minInvocationsExclusiveScanAMD(double);
        dvec2 minInvocationsExclusiveScanAMD(dvec2);
        dvec3 minInvocationsExclusiveScanAMD(dvec3);
        dvec4 minInvocationsExclusiveScanAMD(dvec4);

        int64_t minInvocationsExclusiveScanAMD(int64_t);
        i64vec2 minInvocationsExclusiveScanAMD(i64vec2);
        i64vec3 minInvocationsExclusiveScanAMD(i64vec3);
        i64vec4 minInvocationsExclusiveScanAMD(i64vec4);

        uint64_t minInvocationsExclusiveScanAMD(uint64_t);
        u64vec2 minInvocationsExclusiveScanAMD(u64vec2);
        u64vec3 minInvocationsExclusiveScanAMD(u64vec3);
        u64vec4 minInvocationsExclusiveScanAMD(u64vec4);

        float16_t minInvocationsExclusiveScanAMD(float16_t);
        f16vec2 minInvocationsExclusiveScanAMD(f16vec2);
        f16vec3 minInvocationsExclusiveScanAMD(f16vec3);
        f16vec4 minInvocationsExclusiveScanAMD(f16vec4);

        int16_t minInvocationsExclusiveScanAMD(int16_t);
        i16vec2 minInvocationsExclusiveScanAMD(i16vec2);
        i16vec3 minInvocationsExclusiveScanAMD(i16vec3);
        i16vec4 minInvocationsExclusiveScanAMD(i16vec4);

        uint16_t minInvocationsExclusiveScanAMD(uint16_t);
        u16vec2 minInvocationsExclusiveScanAMD(u16vec2);
        u16vec3 minInvocationsExclusiveScanAMD(u16vec3);
        u16vec4 minInvocationsExclusiveScanAMD(u16vec4);

        float maxInvocationsAMD(float);
        vec2 maxInvocationsAMD(vec2);
        vec3 maxInvocationsAMD(vec3);
        vec4 maxInvocationsAMD(vec4);

        int maxInvocationsAMD(int);
        ivec2 maxInvocationsAMD(ivec2);
        ivec3 maxInvocationsAMD(ivec3);
        ivec4 maxInvocationsAMD(ivec4);

        uint maxInvocationsAMD(uint);
        uvec2 maxInvocationsAMD(uvec2);
        uvec3 maxInvocationsAMD(uvec3);
        uvec4 maxInvocationsAMD(uvec4);

        double maxInvocationsAMD(double);
        dvec2 maxInvocationsAMD(dvec2);
        dvec3 maxInvocationsAMD(dvec3);
        dvec4 maxInvocationsAMD(dvec4);

        int64_t maxInvocationsAMD(int64_t);
        i64vec2 maxInvocationsAMD(i64vec2);
        i64vec3 maxInvocationsAMD(i64vec3);
        i64vec4 maxInvocationsAMD(i64vec4);

        uint64_t maxInvocationsAMD(uint64_t);
        u64vec2 maxInvocationsAMD(u64vec2);
        u64vec3 maxInvocationsAMD(u64vec3);
        u64vec4 maxInvocationsAMD(u64vec4);

        float16_t maxInvocationsAMD(float16_t);
        f16vec2 maxInvocationsAMD(f16vec2);
        f16vec3 maxInvocationsAMD(f16vec3);
        f16vec4 maxInvocationsAMD(f16vec4);

        int16_t maxInvocationsAMD(int16_t);
        i16vec2 maxInvocationsAMD(i16vec2);
        i16vec3 maxInvocationsAMD(i16vec3);
        i16vec4 maxInvocationsAMD(i16vec4);

        uint16_t maxInvocationsAMD(uint16_t);
        u16vec2 maxInvocationsAMD(u16vec2);
        u16vec3 maxInvocationsAMD(u16vec3);
        u16vec4 maxInvocationsAMD(u16vec4);

        float maxInvocationsInclusiveScanAMD(float);
        vec2 maxInvocationsInclusiveScanAMD(vec2);
        vec3 maxInvocationsInclusiveScanAMD(vec3);
        vec4 maxInvocationsInclusiveScanAMD(vec4);

        int maxInvocationsInclusiveScanAMD(int);
        ivec2 maxInvocationsInclusiveScanAMD(ivec2);
        ivec3 maxInvocationsInclusiveScanAMD(ivec3);
        ivec4 maxInvocationsInclusiveScanAMD(ivec4);

        uint maxInvocationsInclusiveScanAMD(uint);
        uvec2 maxInvocationsInclusiveScanAMD(uvec2);
        uvec3 maxInvocationsInclusiveScanAMD(uvec3);
        uvec4 maxInvocationsInclusiveScanAMD(uvec4);

        double maxInvocationsInclusiveScanAMD(double);
        dvec2 maxInvocationsInclusiveScanAMD(dvec2);
        dvec3 maxInvocationsInclusiveScanAMD(dvec3);
        dvec4 maxInvocationsInclusiveScanAMD(dvec4);

        int64_t maxInvocationsInclusiveScanAMD(int64_t);
        i64vec2 maxInvocationsInclusiveScanAMD(i64vec2);
        i64vec3 maxInvocationsInclusiveScanAMD(i64vec3);
        i64vec4 maxInvocationsInclusiveScanAMD(i64vec4);

        uint64_t maxInvocationsInclusiveScanAMD(uint64_t);
        u64vec2 maxInvocationsInclusiveScanAMD(u64vec2);
        u64vec3 maxInvocationsInclusiveScanAMD(u64vec3);
        u64vec4 maxInvocationsInclusiveScanAMD(u64vec4);

        float16_t maxInvocationsInclusiveScanAMD(float16_t);
        f16vec2 maxInvocationsInclusiveScanAMD(f16vec2);
        f16vec3 maxInvocationsInclusiveScanAMD(f16vec3);
        f16vec4 maxInvocationsInclusiveScanAMD(f16vec4);

        int16_t maxInvocationsInclusiveScanAMD(int16_t);
        i16vec2 maxInvocationsInclusiveScanAMD(i16vec2);
        i16vec3 maxInvocationsInclusiveScanAMD(i16vec3);
        i16vec4 maxInvocationsInclusiveScanAMD(i16vec4);

        uint16_t maxInvocationsInclusiveScanAMD(uint16_t);
        u16vec2 maxInvocationsInclusiveScanAMD(u16vec2);
        u16vec3 maxInvocationsInclusiveScanAMD(u16vec3);
        u16vec4 maxInvocationsInclusiveScanAMD(u16vec4);

        float maxInvocationsExclusiveScanAMD(float);
        vec2 maxInvocationsExclusiveScanAMD(vec2);
        vec3 maxInvocationsExclusiveScanAMD(vec3);
        vec4 maxInvocationsExclusiveScanAMD(vec4);

        int maxInvocationsExclusiveScanAMD(int);
        ivec2 maxInvocationsExclusiveScanAMD(ivec2);
        ivec3 maxInvocationsExclusiveScanAMD(ivec3);
        ivec4 maxInvocationsExclusiveScanAMD(ivec4);

        uint maxInvocationsExclusiveScanAMD(uint);
        uvec2 maxInvocationsExclusiveScanAMD(uvec2);
        uvec3 maxInvocationsExclusiveScanAMD(uvec3);
        uvec4 maxInvocationsExclusiveScanAMD(uvec4);

        double maxInvocationsExclusiveScanAMD(double);
        dvec2 maxInvocationsExclusiveScanAMD(dvec2);
        dvec3 maxInvocationsExclusiveScanAMD(dvec3);
        dvec4 maxInvocationsExclusiveScanAMD(dvec4);

        int64_t maxInvocationsExclusiveScanAMD(int64_t);
        i64vec2 maxInvocationsExclusiveScanAMD(i64vec2);
        i64vec3 maxInvocationsExclusiveScanAMD(i64vec3);
        i64vec4 maxInvocationsExclusiveScanAMD(i64vec4);

        uint64_t maxInvocationsExclusiveScanAMD(uint64_t);
        u64vec2 maxInvocationsExclusiveScanAMD(u64vec2);
        u64vec3 maxInvocationsExclusiveScanAMD(u64vec3);
        u64vec4 maxInvocationsExclusiveScanAMD(u64vec4);

        float16_t maxInvocationsExclusiveScanAMD(float16_t);
        f16vec2 maxInvocationsExclusiveScanAMD(f16vec2);
        f16vec3 maxInvocationsExclusiveScanAMD(f16vec3);
        f16vec4 maxInvocationsExclusiveScanAMD(f16vec4);

        int16_t maxInvocationsExclusiveScanAMD(int16_t);
        i16vec2 maxInvocationsExclusiveScanAMD(i16vec2);
        i16vec3 maxInvocationsExclusiveScanAMD(i16vec3);
        i16vec4 maxInvocationsExclusiveScanAMD(i16vec4);

        uint16_t maxInvocationsExclusiveScanAMD(uint16_t);
        u16vec2 maxInvocationsExclusiveScanAMD(u16vec2);
        u16vec3 maxInvocationsExclusiveScanAMD(u16vec3);
        u16vec4 maxInvocationsExclusiveScanAMD(u16vec4);

        float addInvocationsAMD(float);
        vec2 addInvocationsAMD(vec2);
        vec3 addInvocationsAMD(vec3);
        vec4 addInvocationsAMD(vec4);

        int addInvocationsAMD(int);
        ivec2 addInvocationsAMD(ivec2);
        ivec3 addInvocationsAMD(ivec3);
        ivec4 addInvocationsAMD(ivec4);

        uint addInvocationsAMD(uint);
        uvec2 addInvocationsAMD(uvec2);
        uvec3 addInvocationsAMD(uvec3);
        uvec4 addInvocationsAMD(uvec4);

        double addInvocationsAMD(double);
        dvec2 addInvocationsAMD(dvec2);
        dvec3 addInvocationsAMD(dvec3);
        dvec4 addInvocationsAMD(dvec4);

        int64_t addInvocationsAMD(int64_t);
        i64vec2 addInvocationsAMD(i64vec2);
        i64vec3 addInvocationsAMD(i64vec3);
        i64vec4 addInvocationsAMD(i64vec4);

        uint64_t addInvocationsAMD(uint64_t);
        u64vec2 addInvocationsAMD(u64vec2);
        u64vec3 addInvocationsAMD(u64vec3);
        u64vec4 addInvocationsAMD(u64vec4);

        float16_t addInvocationsAMD(float16_t);
        f16vec2 addInvocationsAMD(f16vec2);
        f16vec3 addInvocationsAMD(f16vec3);
        f16vec4 addInvocationsAMD(f16vec4);

        int16_t addInvocationsAMD(int16_t);
        i16vec2 addInvocationsAMD(i16vec2);
        i16vec3 addInvocationsAMD(i16vec3);
        i16vec4 addInvocationsAMD(i16vec4);

        uint16_t addInvocationsAMD(uint16_t);
        u16vec2 addInvocationsAMD(u16vec2);
        u16vec3 addInvocationsAMD(u16vec3);
        u16vec4 addInvocationsAMD(u16vec4);

        float addInvocationsInclusiveScanAMD(float);
        vec2 addInvocationsInclusiveScanAMD(vec2);
        vec3 addInvocationsInclusiveScanAMD(vec3);
        vec4 addInvocationsInclusiveScanAMD(vec4);

        int addInvocationsInclusiveScanAMD(int);
        ivec2 addInvocationsInclusiveScanAMD(ivec2);
        ivec3 addInvocationsInclusiveScanAMD(ivec3);
        ivec4 addInvocationsInclusiveScanAMD(ivec4);

        uint addInvocationsInclusiveScanAMD(uint);
        uvec2 addInvocationsInclusiveScanAMD(uvec2);
        uvec3 addInvocationsInclusiveScanAMD(uvec3);
        uvec4 addInvocationsInclusiveScanAMD(uvec4);

        double addInvocationsInclusiveScanAMD(double);
        dvec2 addInvocationsInclusiveScanAMD(dvec2);
        dvec3 addInvocationsInclusiveScanAMD(dvec3);
        dvec4 addInvocationsInclusiveScanAMD(dvec4);

        int64_t addInvocationsInclusiveScanAMD(int64_t);
        i64vec2 addInvocationsInclusiveScanAMD(i64vec2);
        i64vec3 addInvocationsInclusiveScanAMD(i64vec3);
        i64vec4 addInvocationsInclusiveScanAMD(i64vec4);

        uint64_t addInvocationsInclusiveScanAMD(uint64_t);
        u64vec2 addInvocationsInclusiveScanAMD(u64vec2);
        u64vec3 addInvocationsInclusiveScanAMD(u64vec3);
        u64vec4 addInvocationsInclusiveScanAMD(u64vec4);

        float16_t addInvocationsInclusiveScanAMD(float16_t);
        f16vec2 addInvocationsInclusiveScanAMD(f16vec2);
        f16vec3 addInvocationsInclusiveScanAMD(f16vec3);
        f16vec4 addInvocationsInclusiveScanAMD(f16vec4);

        int16_t addInvocationsInclusiveScanAMD(int16_t);
        i16vec2 addInvocationsInclusiveScanAMD(i16vec2);
        i16vec3 addInvocationsInclusiveScanAMD(i16vec3);
        i16vec4 addInvocationsInclusiveScanAMD(i16vec4);

        uint16_t addInvocationsInclusiveScanAMD(uint16_t);
        u16vec2 addInvocationsInclusiveScanAMD(u16vec2);
        u16vec3 addInvocationsInclusiveScanAMD(u16vec3);
        u16vec4 addInvocationsInclusiveScanAMD(u16vec4);

        float addInvocationsExclusiveScanAMD(float);
        vec2 addInvocationsExclusiveScanAMD(vec2);
        vec3 addInvocationsExclusiveScanAMD(vec3);
        vec4 addInvocationsExclusiveScanAMD(vec4);

        int addInvocationsExclusiveScanAMD(int);
        ivec2 addInvocationsExclusiveScanAMD(ivec2);
        ivec3 addInvocationsExclusiveScanAMD(ivec3);
        ivec4 addInvocationsExclusiveScanAMD(ivec4);

        uint addInvocationsExclusiveScanAMD(uint);
        uvec2 addInvocationsExclusiveScanAMD(uvec2);
        uvec3 addInvocationsExclusiveScanAMD(uvec3);
        uvec4 addInvocationsExclusiveScanAMD(uvec4);

        double addInvocationsExclusiveScanAMD(double);
        dvec2 addInvocationsExclusiveScanAMD(dvec2);
        dvec3 addInvocationsExclusiveScanAMD(dvec3);
        dvec4 addInvocationsExclusiveScanAMD(dvec4);

        int64_t addInvocationsExclusiveScanAMD(int64_t);
        i64vec2 addInvocationsExclusiveScanAMD(i64vec2);
        i64vec3 addInvocationsExclusiveScanAMD(i64vec3);
        i64vec4 addInvocationsExclusiveScanAMD(i64vec4);

        uint64_t addInvocationsExclusiveScanAMD(uint64_t);
        u64vec2 addInvocationsExclusiveScanAMD(u64vec2);
        u64vec3 addInvocationsExclusiveScanAMD(u64vec3);
        u64vec4 addInvocationsExclusiveScanAMD(u64vec4);

        float16_t addInvocationsExclusiveScanAMD(float16_t);
        f16vec2 addInvocationsExclusiveScanAMD(f16vec2);
        f16vec3 addInvocationsExclusiveScanAMD(f16vec3);
        f16vec4 addInvocationsExclusiveScanAMD(f16vec4);

        int16_t addInvocationsExclusiveScanAMD(int16_t);
        i16vec2 addInvocationsExclusiveScanAMD(i16vec2);
        i16vec3 addInvocationsExclusiveScanAMD(i16vec3);
        i16vec4 addInvocationsExclusiveScanAMD(i16vec4);

        uint16_t addInvocationsExclusiveScanAMD(uint16_t);
        u16vec2 addInvocationsExclusiveScanAMD(u16vec2);
        u16vec3 addInvocationsExclusiveScanAMD(u16vec3);
        u16vec4 addInvocationsExclusiveScanAMD(u16vec4);

        float minInvocationsNonUniformAMD(float);
        vec2 minInvocationsNonUniformAMD(vec2);
        vec3 minInvocationsNonUniformAMD(vec3);
        vec4 minInvocationsNonUniformAMD(vec4);

        int minInvocationsNonUniformAMD(int);
        ivec2 minInvocationsNonUniformAMD(ivec2);
        ivec3 minInvocationsNonUniformAMD(ivec3);
        ivec4 minInvocationsNonUniformAMD(ivec4);

        uint minInvocationsNonUniformAMD(uint);
        uvec2 minInvocationsNonUniformAMD(uvec2);
        uvec3 minInvocationsNonUniformAMD(uvec3);
        uvec4 minInvocationsNonUniformAMD(uvec4);

        double minInvocationsNonUniformAMD(double);
        dvec2 minInvocationsNonUniformAMD(dvec2);
        dvec3 minInvocationsNonUniformAMD(dvec3);
        dvec4 minInvocationsNonUniformAMD(dvec4);

        int64_t minInvocationsNonUniformAMD(int64_t);
        i64vec2 minInvocationsNonUniformAMD(i64vec2);
        i64vec3 minInvocationsNonUniformAMD(i64vec3);
        i64vec4 minInvocationsNonUniformAMD(i64vec4);

        uint64_t minInvocationsNonUniformAMD(uint64_t);
        u64vec2 minInvocationsNonUniformAMD(u64vec2);
        u64vec3 minInvocationsNonUniformAMD(u64vec3);
        u64vec4 minInvocationsNonUniformAMD(u64vec4);

        float16_t minInvocationsNonUniformAMD(float16_t);
        f16vec2 minInvocationsNonUniformAMD(f16vec2);
        f16vec3 minInvocationsNonUniformAMD(f16vec3);
        f16vec4 minInvocationsNonUniformAMD(f16vec4);

        int16_t minInvocationsNonUniformAMD(int16_t);
        i16vec2 minInvocationsNonUniformAMD(i16vec2);
        i16vec3 minInvocationsNonUniformAMD(i16vec3);
        i16vec4 minInvocationsNonUniformAMD(i16vec4);

        uint16_t minInvocationsNonUniformAMD(uint16_t);
        u16vec2 minInvocationsNonUniformAMD(u16vec2);
        u16vec3 minInvocationsNonUniformAMD(u16vec3);
        u16vec4 minInvocationsNonUniformAMD(u16vec4);

        float minInvocationsInclusiveScanNonUniformAMD(float);
        vec2 minInvocationsInclusiveScanNonUniformAMD(vec2);
        vec3 minInvocationsInclusiveScanNonUniformAMD(vec3);
        vec4 minInvocationsInclusiveScanNonUniformAMD(vec4);

        int minInvocationsInclusiveScanNonUniformAMD(int);
        ivec2 minInvocationsInclusiveScanNonUniformAMD(ivec2);
        ivec3 minInvocationsInclusiveScanNonUniformAMD(ivec3);
        ivec4 minInvocationsInclusiveScanNonUniformAMD(ivec4);

        uint minInvocationsInclusiveScanNonUniformAMD(uint);
        uvec2 minInvocationsInclusiveScanNonUniformAMD(uvec2);
        uvec3 minInvocationsInclusiveScanNonUniformAMD(uvec3);
        uvec4 minInvocationsInclusiveScanNonUniformAMD(uvec4);

        double minInvocationsInclusiveScanNonUniformAMD(double);
        dvec2 minInvocationsInclusiveScanNonUniformAMD(dvec2);
        dvec3 minInvocationsInclusiveScanNonUniformAMD(dvec3);
        dvec4 minInvocationsInclusiveScanNonUniformAMD(dvec4);

        int64_t minInvocationsInclusiveScanNonUniformAMD(int64_t);
        i64vec2 minInvocationsInclusiveScanNonUniformAMD(i64vec2);
        i64vec3 minInvocationsInclusiveScanNonUniformAMD(i64vec3);
        i64vec4 minInvocationsInclusiveScanNonUniformAMD(i64vec4);

        uint64_t minInvocationsInclusiveScanNonUniformAMD(uint64_t);
        u64vec2 minInvocationsInclusiveScanNonUniformAMD(u64vec2);
        u64vec3 minInvocationsInclusiveScanNonUniformAMD(u64vec3);
        u64vec4 minInvocationsInclusiveScanNonUniformAMD(u64vec4);

        float16_t minInvocationsInclusiveScanNonUniformAMD(float16_t);
        f16vec2 minInvocationsInclusiveScanNonUniformAMD(f16vec2);
        f16vec3 minInvocationsInclusiveScanNonUniformAMD(f16vec3);
        f16vec4 minInvocationsInclusiveScanNonUniformAMD(f16vec4);

        int16_t minInvocationsInclusiveScanNonUniformAMD(int16_t);
        i16vec2 minInvocationsInclusiveScanNonUniformAMD(i16vec2);
        i16vec3 minInvocationsInclusiveScanNonUniformAMD(i16vec3);
        i16vec4 minInvocationsInclusiveScanNonUniformAMD(i16vec4);

        uint16_t minInvocationsInclusiveScanNonUniformAMD(uint16_t);
        u16vec2 minInvocationsInclusiveScanNonUniformAMD(u16vec2);
        u16vec3 minInvocationsInclusiveScanNonUniformAMD(u16vec3);
        u16vec4 minInvocationsInclusiveScanNonUniformAMD(u16vec4);

        float minInvocationsExclusiveScanNonUniformAMD(float);
        vec2 minInvocationsExclusiveScanNonUniformAMD(vec2);
        vec3 minInvocationsExclusiveScanNonUniformAMD(vec3);
        vec4 minInvocationsExclusiveScanNonUniformAMD(vec4);

        int minInvocationsExclusiveScanNonUniformAMD(int);
        ivec2 minInvocationsExclusiveScanNonUniformAMD(ivec2);
        ivec3 minInvocationsExclusiveScanNonUniformAMD(ivec3);
        ivec4 minInvocationsExclusiveScanNonUniformAMD(ivec4);

        uint minInvocationsExclusiveScanNonUniformAMD(uint);
        uvec2 minInvocationsExclusiveScanNonUniformAMD(uvec2);
        uvec3 minInvocationsExclusiveScanNonUniformAMD(uvec3);
        uvec4 minInvocationsExclusiveScanNonUniformAMD(uvec4);

        double minInvocationsExclusiveScanNonUniformAMD(double);
        dvec2 minInvocationsExclusiveScanNonUniformAMD(dvec2);
        dvec3 minInvocationsExclusiveScanNonUniformAMD(dvec3);
        dvec4 minInvocationsExclusiveScanNonUniformAMD(dvec4);

        int64_t minInvocationsExclusiveScanNonUniformAMD(int64_t);
        i64vec2 minInvocationsExclusiveScanNonUniformAMD(i64vec2);
        i64vec3 minInvocationsExclusiveScanNonUniformAMD(i64vec3);
        i64vec4 minInvocationsExclusiveScanNonUniformAMD(i64vec4);

        uint64_t minInvocationsExclusiveScanNonUniformAMD(uint64_t);
        u64vec2 minInvocationsExclusiveScanNonUniformAMD(u64vec2);
        u64vec3 minInvocationsExclusiveScanNonUniformAMD(u64vec3);
        u64vec4 minInvocationsExclusiveScanNonUniformAMD(u64vec4);

        float16_t minInvocationsExclusiveScanNonUniformAMD(float16_t);
        f16vec2 minInvocationsExclusiveScanNonUniformAMD(f16vec2);
        f16vec3 minInvocationsExclusiveScanNonUniformAMD(f16vec3);
        f16vec4 minInvocationsExclusiveScanNonUniformAMD(f16vec4);

        int16_t minInvocationsExclusiveScanNonUniformAMD(int16_t);
        i16vec2 minInvocationsExclusiveScanNonUniformAMD(i16vec2);
        i16vec3 minInvocationsExclusiveScanNonUniformAMD(i16vec3);
        i16vec4 minInvocationsExclusiveScanNonUniformAMD(i16vec4);

        uint16_t minInvocationsExclusiveScanNonUniformAMD(uint16_t);
        u16vec2 minInvocationsExclusiveScanNonUniformAMD(u16vec2);
        u16vec3 minInvocationsExclusiveScanNonUniformAMD(u16vec3);
        u16vec4 minInvocationsExclusiveScanNonUniformAMD(u16vec4);

        float maxInvocationsNonUniformAMD(float);
        vec2 maxInvocationsNonUniformAMD(vec2);
        vec3 maxInvocationsNonUniformAMD(vec3);
        vec4 maxInvocationsNonUniformAMD(vec4);

        int maxInvocationsNonUniformAMD(int);
        ivec2 maxInvocationsNonUniformAMD(ivec2);
        ivec3 maxInvocationsNonUniformAMD(ivec3);
        ivec4 maxInvocationsNonUniformAMD(ivec4);

        uint maxInvocationsNonUniformAMD(uint);
        uvec2 maxInvocationsNonUniformAMD(uvec2);
        uvec3 maxInvocationsNonUniformAMD(uvec3);
        uvec4 maxInvocationsNonUniformAMD(uvec4);

        double maxInvocationsNonUniformAMD(double);
        dvec2 maxInvocationsNonUniformAMD(dvec2);
        dvec3 maxInvocationsNonUniformAMD(dvec3);
        dvec4 maxInvocationsNonUniformAMD(dvec4);

        int64_t maxInvocationsNonUniformAMD(int64_t);
        i64vec2 maxInvocationsNonUniformAMD(i64vec2);
        i64vec3 maxInvocationsNonUniformAMD(i64vec3);
        i64vec4 maxInvocationsNonUniformAMD(i64vec4);

        uint64_t maxInvocationsNonUniformAMD(uint64_t);
        u64vec2 maxInvocationsNonUniformAMD(u64vec2);
        u64vec3 maxInvocationsNonUniformAMD(u64vec3);
        u64vec4 maxInvocationsNonUniformAMD(u64vec4);

        float16_t maxInvocationsNonUniformAMD(float16_t);
        f16vec2 maxInvocationsNonUniformAMD(f16vec2);
        f16vec3 maxInvocationsNonUniformAMD(f16vec3);
        f16vec4 maxInvocationsNonUniformAMD(f16vec4);

        int16_t maxInvocationsNonUniformAMD(int16_t);
        i16vec2 maxInvocationsNonUniformAMD(i16vec2);
        i16vec3 maxInvocationsNonUniformAMD(i16vec3);
        i16vec4 maxInvocationsNonUniformAMD(i16vec4);

        uint16_t maxInvocationsNonUniformAMD(uint16_t);
        u16vec2 maxInvocationsNonUniformAMD(u16vec2);
        u16vec3 maxInvocationsNonUniformAMD(u16vec3);
        u16vec4 maxInvocationsNonUniformAMD(u16vec4);

        float maxInvocationsInclusiveScanNonUniformAMD(float);
        vec2 maxInvocationsInclusiveScanNonUniformAMD(vec2);
        vec3 maxInvocationsInclusiveScanNonUniformAMD(vec3);
        vec4 maxInvocationsInclusiveScanNonUniformAMD(vec4);

        int maxInvocationsInclusiveScanNonUniformAMD(int);
        ivec2 maxInvocationsInclusiveScanNonUniformAMD(ivec2);
        ivec3 maxInvocationsInclusiveScanNonUniformAMD(ivec3);
        ivec4 maxInvocationsInclusiveScanNonUniformAMD(ivec4);

        uint maxInvocationsInclusiveScanNonUniformAMD(uint);
        uvec2 maxInvocationsInclusiveScanNonUniformAMD(uvec2);
        uvec3 maxInvocationsInclusiveScanNonUniformAMD(uvec3);
        uvec4 maxInvocationsInclusiveScanNonUniformAMD(uvec4);

        double maxInvocationsInclusiveScanNonUniformAMD(double);
        dvec2 maxInvocationsInclusiveScanNonUniformAMD(dvec2);
        dvec3 maxInvocationsInclusiveScanNonUniformAMD(dvec3);
        dvec4 maxInvocationsInclusiveScanNonUniformAMD(dvec4);

        int64_t maxInvocationsInclusiveScanNonUniformAMD(int64_t);
        i64vec2 maxInvocationsInclusiveScanNonUniformAMD(i64vec2);
        i64vec3 maxInvocationsInclusiveScanNonUniformAMD(i64vec3);
        i64vec4 maxInvocationsInclusiveScanNonUniformAMD(i64vec4);

        uint64_t maxInvocationsInclusiveScanNonUniformAMD(uint64_t);
        u64vec2 maxInvocationsInclusiveScanNonUniformAMD(u64vec2);
        u64vec3 maxInvocationsInclusiveScanNonUniformAMD(u64vec3);
        u64vec4 maxInvocationsInclusiveScanNonUniformAMD(u64vec4);

        float16_t maxInvocationsInclusiveScanNonUniformAMD(float16_t);
        f16vec2 maxInvocationsInclusiveScanNonUniformAMD(f16vec2);
        f16vec3 maxInvocationsInclusiveScanNonUniformAMD(f16vec3);
        f16vec4 maxInvocationsInclusiveScanNonUniformAMD(f16vec4);

        int16_t maxInvocationsInclusiveScanNonUniformAMD(int16_t);
        i16vec2 maxInvocationsInclusiveScanNonUniformAMD(i16vec2);
        i16vec3 maxInvocationsInclusiveScanNonUniformAMD(i16vec3);
        i16vec4 maxInvocationsInclusiveScanNonUniformAMD(i16vec4);

        uint16_t maxInvocationsInclusiveScanNonUniformAMD(uint16_t);
        u16vec2 maxInvocationsInclusiveScanNonUniformAMD(u16vec2);
        u16vec3 maxInvocationsInclusiveScanNonUniformAMD(u16vec3);
        u16vec4 maxInvocationsInclusiveScanNonUniformAMD(u16vec4);

        float maxInvocationsExclusiveScanNonUniformAMD(float);
        vec2 maxInvocationsExclusiveScanNonUniformAMD(vec2);
        vec3 maxInvocationsExclusiveScanNonUniformAMD(vec3);
        vec4 maxInvocationsExclusiveScanNonUniformAMD(vec4);

        int maxInvocationsExclusiveScanNonUniformAMD(int);
        ivec2 maxInvocationsExclusiveScanNonUniformAMD(ivec2);
        ivec3 maxInvocationsExclusiveScanNonUniformAMD(ivec3);
        ivec4 maxInvocationsExclusiveScanNonUniformAMD(ivec4);

        uint maxInvocationsExclusiveScanNonUniformAMD(uint);
        uvec2 maxInvocationsExclusiveScanNonUniformAMD(uvec2);
        uvec3 maxInvocationsExclusiveScanNonUniformAMD(uvec3);
        uvec4 maxInvocationsExclusiveScanNonUniformAMD(uvec4);

        double maxInvocationsExclusiveScanNonUniformAMD(double);
        dvec2 maxInvocationsExclusiveScanNonUniformAMD(dvec2);
        dvec3 maxInvocationsExclusiveScanNonUniformAMD(dvec3);
        dvec4 maxInvocationsExclusiveScanNonUniformAMD(dvec4);

        int64_t maxInvocationsExclusiveScanNonUniformAMD(int64_t);
        i64vec2 maxInvocationsExclusiveScanNonUniformAMD(i64vec2);
        i64vec3 maxInvocationsExclusiveScanNonUniformAMD(i64vec3);
        i64vec4 maxInvocationsExclusiveScanNonUniformAMD(i64vec4);

        uint64_t maxInvocationsExclusiveScanNonUniformAMD(uint64_t);
        u64vec2 maxInvocationsExclusiveScanNonUniformAMD(u64vec2);
        u64vec3 maxInvocationsExclusiveScanNonUniformAMD(u64vec3);
        u64vec4 maxInvocationsExclusiveScanNonUniformAMD(u64vec4);

        float16_t maxInvocationsExclusiveScanNonUniformAMD(float16_t);
        f16vec2 maxInvocationsExclusiveScanNonUniformAMD(f16vec2);
        f16vec3 maxInvocationsExclusiveScanNonUniformAMD(f16vec3);
        f16vec4 maxInvocationsExclusiveScanNonUniformAMD(f16vec4);

        int16_t maxInvocationsExclusiveScanNonUniformAMD(int16_t);
        i16vec2 maxInvocationsExclusiveScanNonUniformAMD(i16vec2);
        i16vec3 maxInvocationsExclusiveScanNonUniformAMD(i16vec3);
        i16vec4 maxInvocationsExclusiveScanNonUniformAMD(i16vec4);

        uint16_t maxInvocationsExclusiveScanNonUniformAMD(uint16_t);
        u16vec2 maxInvocationsExclusiveScanNonUniformAMD(u16vec2);
        u16vec3 maxInvocationsExclusiveScanNonUniformAMD(u16vec3);
        u16vec4 maxInvocationsExclusiveScanNonUniformAMD(u16vec4);

        float addInvocationsNonUniformAMD(float);
        vec2 addInvocationsNonUniformAMD(vec2);
        vec3 addInvocationsNonUniformAMD(vec3);
        vec4 addInvocationsNonUniformAMD(vec4);

        int addInvocationsNonUniformAMD(int);
        ivec2 addInvocationsNonUniformAMD(ivec2);
        ivec3 addInvocationsNonUniformAMD(ivec3);
        ivec4 addInvocationsNonUniformAMD(ivec4);

        uint addInvocationsNonUniformAMD(uint);
        uvec2 addInvocationsNonUniformAMD(uvec2);
        uvec3 addInvocationsNonUniformAMD(uvec3);
        uvec4 addInvocationsNonUniformAMD(uvec4);

        double addInvocationsNonUniformAMD(double);
        dvec2 addInvocationsNonUniformAMD(dvec2);
        dvec3 addInvocationsNonUniformAMD(dvec3);
        dvec4 addInvocationsNonUniformAMD(dvec4);

        int64_t addInvocationsNonUniformAMD(int64_t);
        i64vec2 addInvocationsNonUniformAMD(i64vec2);
        i64vec3 addInvocationsNonUniformAMD(i64vec3);
        i64vec4 addInvocationsNonUniformAMD(i64vec4);

        uint64_t addInvocationsNonUniformAMD(uint64_t);
        u64vec2 addInvocationsNonUniformAMD(u64vec2);
        u64vec3 addInvocationsNonUniformAMD(u64vec3);
        u64vec4 addInvocationsNonUniformAMD(u64vec4);

        float16_t addInvocationsNonUniformAMD(float16_t);
        f16vec2 addInvocationsNonUniformAMD(f16vec2);
        f16vec3 addInvocationsNonUniformAMD(f16vec3);
        f16vec4 addInvocationsNonUniformAMD(f16vec4);

        int16_t addInvocationsNonUniformAMD(int16_t);
        i16vec2 addInvocationsNonUniformAMD(i16vec2);
        i16vec3 addInvocationsNonUniformAMD(i16vec3);
        i16vec4 addInvocationsNonUniformAMD(i16vec4);

        uint16_t addInvocationsNonUniformAMD(uint16_t);
        u16vec2 addInvocationsNonUniformAMD(u16vec2);
        u16vec3 addInvocationsNonUniformAMD(u16vec3);
        u16vec4 addInvocationsNonUniformAMD(u16vec4);

        float addInvocationsInclusiveScanNonUniformAMD(float);
        vec2 addInvocationsInclusiveScanNonUniformAMD(vec2);
        vec3 addInvocationsInclusiveScanNonUniformAMD(vec3);
        vec4 addInvocationsInclusiveScanNonUniformAMD(vec4);

        int addInvocationsInclusiveScanNonUniformAMD(int);
        ivec2 addInvocationsInclusiveScanNonUniformAMD(ivec2);
        ivec3 addInvocationsInclusiveScanNonUniformAMD(ivec3);
        ivec4 addInvocationsInclusiveScanNonUniformAMD(ivec4);

        uint addInvocationsInclusiveScanNonUniformAMD(uint);
        uvec2 addInvocationsInclusiveScanNonUniformAMD(uvec2);
        uvec3 addInvocationsInclusiveScanNonUniformAMD(uvec3);
        uvec4 addInvocationsInclusiveScanNonUniformAMD(uvec4);

        double addInvocationsInclusiveScanNonUniformAMD(double);
        dvec2 addInvocationsInclusiveScanNonUniformAMD(dvec2);
        dvec3 addInvocationsInclusiveScanNonUniformAMD(dvec3);
        dvec4 addInvocationsInclusiveScanNonUniformAMD(dvec4);

        int64_t addInvocationsInclusiveScanNonUniformAMD(int64_t);
        i64vec2 addInvocationsInclusiveScanNonUniformAMD(i64vec2);
        i64vec3 addInvocationsInclusiveScanNonUniformAMD(i64vec3);
        i64vec4 addInvocationsInclusiveScanNonUniformAMD(i64vec4);

        uint64_t addInvocationsInclusiveScanNonUniformAMD(uint64_t);
        u64vec2 addInvocationsInclusiveScanNonUniformAMD(u64vec2);
        u64vec3 addInvocationsInclusiveScanNonUniformAMD(u64vec3);
        u64vec4 addInvocationsInclusiveScanNonUniformAMD(u64vec4);

        float16_t addInvocationsInclusiveScanNonUniformAMD(float16_t);
        f16vec2 addInvocationsInclusiveScanNonUniformAMD(f16vec2);
        f16vec3 addInvocationsInclusiveScanNonUniformAMD(f16vec3);
        f16vec4 addInvocationsInclusiveScanNonUniformAMD(f16vec4);

        int16_t addInvocationsInclusiveScanNonUniformAMD(int16_t);
        i16vec2 addInvocationsInclusiveScanNonUniformAMD(i16vec2);
        i16vec3 addInvocationsInclusiveScanNonUniformAMD(i16vec3);
        i16vec4 addInvocationsInclusiveScanNonUniformAMD(i16vec4);

        uint16_t addInvocationsInclusiveScanNonUniformAMD(uint16_t);
        u16vec2 addInvocationsInclusiveScanNonUniformAMD(u16vec2);
        u16vec3 addInvocationsInclusiveScanNonUniformAMD(u16vec3);
        u16vec4 addInvocationsInclusiveScanNonUniformAMD(u16vec4);

        float addInvocationsExclusiveScanNonUniformAMD(float);
        vec2 addInvocationsExclusiveScanNonUniformAMD(vec2);
        vec3 addInvocationsExclusiveScanNonUniformAMD(vec3);
        vec4 addInvocationsExclusiveScanNonUniformAMD(vec4);

        int addInvocationsExclusiveScanNonUniformAMD(int);
        ivec2 addInvocationsExclusiveScanNonUniformAMD(ivec2);
        ivec3 addInvocationsExclusiveScanNonUniformAMD(ivec3);
        ivec4 addInvocationsExclusiveScanNonUniformAMD(ivec4);

        uint addInvocationsExclusiveScanNonUniformAMD(uint);
        uvec2 addInvocationsExclusiveScanNonUniformAMD(uvec2);
        uvec3 addInvocationsExclusiveScanNonUniformAMD(uvec3);
        uvec4 addInvocationsExclusiveScanNonUniformAMD(uvec4);

        double addInvocationsExclusiveScanNonUniformAMD(double);
        dvec2 addInvocationsExclusiveScanNonUniformAMD(dvec2);
        dvec3 addInvocationsExclusiveScanNonUniformAMD(dvec3);
        dvec4 addInvocationsExclusiveScanNonUniformAMD(dvec4);

        int64_t addInvocationsExclusiveScanNonUniformAMD(int64_t);
        i64vec2 addInvocationsExclusiveScanNonUniformAMD(i64vec2);
        i64vec3 addInvocationsExclusiveScanNonUniformAMD(i64vec3);
        i64vec4 addInvocationsExclusiveScanNonUniformAMD(i64vec4);

        uint64_t addInvocationsExclusiveScanNonUniformAMD(uint64_t);
        u64vec2 addInvocationsExclusiveScanNonUniformAMD(u64vec2);
        u64vec3 addInvocationsExclusiveScanNonUniformAMD(u64vec3);
        u64vec4 addInvocationsExclusiveScanNonUniformAMD(u64vec4);

        float16_t addInvocationsExclusiveScanNonUniformAMD(float16_t);
        f16vec2 addInvocationsExclusiveScanNonUniformAMD(f16vec2);
        f16vec3 addInvocationsExclusiveScanNonUniformAMD(f16vec3);
        f16vec4 addInvocationsExclusiveScanNonUniformAMD(f16vec4);

        int16_t addInvocationsExclusiveScanNonUniformAMD(int16_t);
        i16vec2 addInvocationsExclusiveScanNonUniformAMD(i16vec2);
        i16vec3 addInvocationsExclusiveScanNonUniformAMD(i16vec3);
        i16vec4 addInvocationsExclusiveScanNonUniformAMD(i16vec4);

        uint16_t addInvocationsExclusiveScanNonUniformAMD(uint16_t);
        u16vec2 addInvocationsExclusiveScanNonUniformAMD(u16vec2);
        u16vec3 addInvocationsExclusiveScanNonUniformAMD(u16vec3);
        u16vec4 addInvocationsExclusiveScanNonUniformAMD(u16vec4);

        float swizzleInvocationsAMD(float, uvec4);
        vec2 swizzleInvocationsAMD(vec2, uvec4);
        vec3 swizzleInvocationsAMD(vec3, uvec4);
        vec4 swizzleInvocationsAMD(vec4, uvec4);

        int swizzleInvocationsAMD(int, uvec4);
        ivec2 swizzleInvocationsAMD(ivec2, uvec4);
        ivec3 swizzleInvocationsAMD(ivec3, uvec4);
        ivec4 swizzleInvocationsAMD(ivec4, uvec4);

        uint swizzleInvocationsAMD(uint, uvec4);
        uvec2 swizzleInvocationsAMD(uvec2, uvec4);
        uvec3 swizzleInvocationsAMD(uvec3, uvec4);
        uvec4 swizzleInvocationsAMD(uvec4, uvec4);

        float swizzleInvocationsMaskedAMD(float, uvec3);
        vec2 swizzleInvocationsMaskedAMD(vec2, uvec3);
        vec3 swizzleInvocationsMaskedAMD(vec3, uvec3);
        vec4 swizzleInvocationsMaskedAMD(vec4, uvec3);

        int swizzleInvocationsMaskedAMD(int, uvec3);
        ivec2 swizzleInvocationsMaskedAMD(ivec2, uvec3);
        ivec3 swizzleInvocationsMaskedAMD(ivec3, uvec3);
        ivec4 swizzleInvocationsMaskedAMD(ivec4, uvec3);

        uint swizzleInvocationsMaskedAMD(uint, uvec3);
        uvec2 swizzleInvocationsMaskedAMD(uvec2, uvec3);
        uvec3 swizzleInvocationsMaskedAMD(uvec3, uvec3);
        uvec4 swizzleInvocationsMaskedAMD(uvec4, uvec3);

        float writeInvocationAMD(float, float, uint);
        vec2 writeInvocationAMD(vec2, vec2, uint);
        vec3 writeInvocationAMD(vec3, vec3, uint);
        vec4 writeInvocationAMD(vec4, vec4, uint);

        int writeInvocationAMD(int, int, uint);
        ivec2 writeInvocationAMD(ivec2, ivec2, uint);
        ivec3 writeInvocationAMD(ivec3, ivec3, uint);
        ivec4 writeInvocationAMD(ivec4, ivec4, uint);

        uint writeInvocationAMD(uint, uint, uint);
        uvec2 writeInvocationAMD(uvec2, uvec2, uint);
        uvec3 writeInvocationAMD(uvec3, uvec3, uint);
        uvec4 writeInvocationAMD(uvec4, uvec4, uint);

        uint mbcntAMD(uint64_t);
      };
    }

    if (profile != glslang_profile_t.ES_PROFILE && version_ >= 440) {
      commonBuiltins ~= q{
        float cubeFaceIndexAMD(vec3);
        vec2 cubeFaceCoordAMD(vec3);
        uint64_t timeAMD();

        in int gl_SIMDGroupSizeAMD;
      };
    }

    if (profile != glslang_profile_t.ES_PROFILE && version_ >= 450) {
      commonBuiltins ~= q{
        uint fragmentMaskFetchAMD(sampler2DMS, ivec2);
        uint fragmentMaskFetchAMD(isampler2DMS, ivec2);
        uint fragmentMaskFetchAMD(usampler2DMS, ivec2);

        uint fragmentMaskFetchAMD(sampler2DMSArray, ivec3);
        uint fragmentMaskFetchAMD(isampler2DMSArray, ivec3);
        uint fragmentMaskFetchAMD(usampler2DMSArray, ivec3);

        vec4 fragmentFetchAMD(sampler2DMS, ivec2, uint);
        ivec4 fragmentFetchAMD(isampler2DMS, ivec2, uint);
        uvec4 fragmentFetchAMD(usampler2DMS, ivec2, uint);

        vec4 fragmentFetchAMD(sampler2DMSArray, ivec3, uint);
        ivec4 fragmentFetchAMD(isampler2DMSArray, ivec3, uint);
        uvec4 fragmentFetchAMD(usampler2DMSArray, ivec3, uint);
      };
    }

    if ((profile != glslang_profile_t.ES_PROFILE && version_ >= 130) ||
      (profile == glslang_profile_t.ES_PROFILE && version_ >= 300)) {
      commonBuiltins ~= q{
        uint countLeadingZeros(uint);
        uvec2 countLeadingZeros(uvec2);
        uvec3 countLeadingZeros(uvec3);
        uvec4 countLeadingZeros(uvec4);

        uint countTrailingZeros(uint);
        uvec2 countTrailingZeros(uvec2);
        uvec3 countTrailingZeros(uvec3);
        uvec4 countTrailingZeros(uvec4);

        uint absoluteDifference(int, int);
        uvec2 absoluteDifference(ivec2, ivec2);
        uvec3 absoluteDifference(ivec3, ivec3);
        uvec4 absoluteDifference(ivec4, ivec4);

        uint16_t absoluteDifference(int16_t, int16_t);
        u16vec2 absoluteDifference(i16vec2, i16vec2);
        u16vec3 absoluteDifference(i16vec3, i16vec3);
        u16vec4 absoluteDifference(i16vec4, i16vec4);

        uint64_t absoluteDifference(int64_t, int64_t);
        u64vec2 absoluteDifference(i64vec2, i64vec2);
        u64vec3 absoluteDifference(i64vec3, i64vec3);
        u64vec4 absoluteDifference(i64vec4, i64vec4);

        uint absoluteDifference(uint, uint);
        uvec2 absoluteDifference(uvec2, uvec2);
        uvec3 absoluteDifference(uvec3, uvec3);
        uvec4 absoluteDifference(uvec4, uvec4);

        uint16_t absoluteDifference(uint16_t, uint16_t);
        u16vec2 absoluteDifference(u16vec2, u16vec2);
        u16vec3 absoluteDifference(u16vec3, u16vec3);
        u16vec4 absoluteDifference(u16vec4, u16vec4);

        uint64_t absoluteDifference(uint64_t, uint64_t);
        u64vec2 absoluteDifference(u64vec2, u64vec2);
        u64vec3 absoluteDifference(u64vec3, u64vec3);
        u64vec4 absoluteDifference(u64vec4, u64vec4);

        int addSaturate(int, int);
        ivec2 addSaturate(ivec2, ivec2);
        ivec3 addSaturate(ivec3, ivec3);
        ivec4 addSaturate(ivec4, ivec4);

        int16_t addSaturate(int16_t, int16_t);
        i16vec2 addSaturate(i16vec2, i16vec2);
        i16vec3 addSaturate(i16vec3, i16vec3);
        i16vec4 addSaturate(i16vec4, i16vec4);

        int64_t addSaturate(int64_t, int64_t);
        i64vec2 addSaturate(i64vec2, i64vec2);
        i64vec3 addSaturate(i64vec3, i64vec3);
        i64vec4 addSaturate(i64vec4, i64vec4);

        uint addSaturate(uint, uint);
        uvec2 addSaturate(uvec2, uvec2);
        uvec3 addSaturate(uvec3, uvec3);
        uvec4 addSaturate(uvec4, uvec4);

        uint16_t addSaturate(uint16_t, uint16_t);
        u16vec2 addSaturate(u16vec2, u16vec2);
        u16vec3 addSaturate(u16vec3, u16vec3);
        u16vec4 addSaturate(u16vec4, u16vec4);

        uint64_t addSaturate(uint64_t, uint64_t);
        u64vec2 addSaturate(u64vec2, u64vec2);
        u64vec3 addSaturate(u64vec3, u64vec3);
        u64vec4 addSaturate(u64vec4, u64vec4);

        int subtractSaturate(int, int);
        ivec2 subtractSaturate(ivec2, ivec2);
        ivec3 subtractSaturate(ivec3, ivec3);
        ivec4 subtractSaturate(ivec4, ivec4);

        int16_t subtractSaturate(int16_t, int16_t);
        i16vec2 subtractSaturate(i16vec2, i16vec2);
        i16vec3 subtractSaturate(i16vec3, i16vec3);
        i16vec4 subtractSaturate(i16vec4, i16vec4);

        int64_t subtractSaturate(int64_t, int64_t);
        i64vec2 subtractSaturate(i64vec2, i64vec2);
        i64vec3 subtractSaturate(i64vec3, i64vec3);
        i64vec4 subtractSaturate(i64vec4, i64vec4);

        uint subtractSaturate(uint, uint);
        uvec2 subtractSaturate(uvec2, uvec2);
        uvec3 subtractSaturate(uvec3, uvec3);
        uvec4 subtractSaturate(uvec4, uvec4);

        uint16_t subtractSaturate(uint16_t, uint16_t);
        u16vec2 subtractSaturate(u16vec2, u16vec2);
        u16vec3 subtractSaturate(u16vec3, u16vec3);
        u16vec4 subtractSaturate(u16vec4, u16vec4);

        uint64_t subtractSaturate(uint64_t, uint64_t);
        u64vec2 subtractSaturate(u64vec2, u64vec2);
        u64vec3 subtractSaturate(u64vec3, u64vec3);
        u64vec4 subtractSaturate(u64vec4, u64vec4);

        int average(int, int);
        ivec2 average(ivec2, ivec2);
        ivec3 average(ivec3, ivec3);
        ivec4 average(ivec4, ivec4);

        int16_t average(int16_t, int16_t);
        i16vec2 average(i16vec2, i16vec2);
        i16vec3 average(i16vec3, i16vec3);
        i16vec4 average(i16vec4, i16vec4);

        int64_t average(int64_t, int64_t);
        i64vec2 average(i64vec2, i64vec2);
        i64vec3 average(i64vec3, i64vec3);
        i64vec4 average(i64vec4, i64vec4);

        uint average(uint, uint);
        uvec2 average(uvec2, uvec2);
        uvec3 average(uvec3, uvec3);
        uvec4 average(uvec4, uvec4);

        uint16_t average(uint16_t, uint16_t);
        u16vec2 average(u16vec2, u16vec2);
        u16vec3 average(u16vec3, u16vec3);
        u16vec4 average(u16vec4, u16vec4);

        uint64_t average(uint64_t, uint64_t);
        u64vec2 average(u64vec2, u64vec2);
        u64vec3 average(u64vec3, u64vec3);
        u64vec4 average(u64vec4, u64vec4);

        int averageRounded(int, int);
        ivec2 averageRounded(ivec2, ivec2);
        ivec3 averageRounded(ivec3, ivec3);
        ivec4 averageRounded(ivec4, ivec4);

        int16_t averageRounded(int16_t, int16_t);
        i16vec2 averageRounded(i16vec2, i16vec2);
        i16vec3 averageRounded(i16vec3, i16vec3);
        i16vec4 averageRounded(i16vec4, i16vec4);

        int64_t averageRounded(int64_t, int64_t);
        i64vec2 averageRounded(i64vec2, i64vec2);
        i64vec3 averageRounded(i64vec3, i64vec3);
        i64vec4 averageRounded(i64vec4, i64vec4);

        uint averageRounded(uint, uint);
        uvec2 averageRounded(uvec2, uvec2);
        uvec3 averageRounded(uvec3, uvec3);
        uvec4 averageRounded(uvec4, uvec4);

        uint16_t averageRounded(uint16_t, uint16_t);
        u16vec2 averageRounded(u16vec2, u16vec2);
        u16vec3 averageRounded(u16vec3, u16vec3);
        u16vec4 averageRounded(u16vec4, u16vec4);

        uint64_t averageRounded(uint64_t, uint64_t);
        u64vec2 averageRounded(u64vec2, u64vec2);
        u64vec3 averageRounded(u64vec3, u64vec3);
        u64vec4 averageRounded(u64vec4, u64vec4);

        int multiply32x16(int, int);
        ivec2 multiply32x16(ivec2, ivec2);
        ivec3 multiply32x16(ivec3, ivec3);
        ivec4 multiply32x16(ivec4, ivec4);

        uint multiply32x16(uint, uint);
        uvec2 multiply32x16(uvec2, uvec2);
        uvec3 multiply32x16(uvec3, uvec3);
        uvec4 multiply32x16(uvec4, uvec4);
      };
    }

    if ((profile != glslang_profile_t.ES_PROFILE && version_ >= 450) ||
      (profile == glslang_profile_t.ES_PROFILE && version_ >= 320)) {
      commonBuiltins ~= q{
        struct gl_TextureFootprint2DNV {
          uvec2 anchor;
          uvec2 offset;
          uvec2 mask;
          uint lod;
          uint granularity;
        };

        struct gl_TextureFootprint3DNV {
          uvec3 anchor;
          uvec3 offset;
          uvec2 mask;
          uint lod;
          uint granularity;
        };

        bool textureFootprintNV(sampler2D, vec2, int, bool, out gl_TextureFootprint2DNV);
        bool textureFootprintNV(sampler3D, vec3, int, bool, out gl_TextureFootprint3DNV);
        bool textureFootprintNV(sampler2D, vec2, int, bool, out gl_TextureFootprint2DNV, float);
        bool textureFootprintNV(sampler3D, vec3, int, bool, out gl_TextureFootprint3DNV, float);
        bool textureFootprintClampNV(sampler2D, vec2, float, int, bool, out gl_TextureFootprint2DNV);
        bool textureFootprintClampNV(sampler3D, vec3, float, int, bool, out gl_TextureFootprint3DNV);
        bool textureFootprintClampNV(sampler2D, vec2, float, int, bool, out gl_TextureFootprint2DNV, float);
        bool textureFootprintClampNV(sampler3D, vec3, float, int, bool, out gl_TextureFootprint3DNV, float);
        bool textureFootprintLodNV(sampler2D, vec2, float, int, bool, out gl_TextureFootprint2DNV);
        bool textureFootprintLodNV(sampler3D, vec3, float, int, bool, out gl_TextureFootprint3DNV);
        bool textureFootprintGradNV(sampler2D, vec2, vec2, vec2, int, bool, out gl_TextureFootprint2DNV);
        bool textureFootprintGradClampNV(sampler2D, vec2, vec2, vec2, float, int, bool, out gl_TextureFootprint2DNV);
      };   
    }

    if ((profile == glslang_profile_t.ES_PROFILE && version_ >= 300 && version_ < 310) ||
      (profile == glslang_profile_t.ES_PROFILE && version_ >= 150 && version_ < 450)) {
      commonBuiltins ~= q{
        int mix(int, int, bool);
        ivec2 mix(ivec2, ivec2, bvec2);
        ivec3 mix(ivec3, ivec3, bvec3);
        ivec4 mix(ivec4, ivec4, bvec4);
        uint mix(uint, uint, bool );
        uvec2 mix(uvec2, uvec2, bvec2);
        uvec3 mix(uvec3, uvec3, bvec3);
        uvec4 mix(uvec4, uvec4, bvec4);
        bool mix(bool, bool, bool );
        bvec2 mix(bvec2, bvec2, bvec2);
        bvec3 mix(bvec3, bvec3, bvec3);
        bvec4 mix(bvec4, bvec4, bvec4);
      };
    }

    if ((profile != glslang_profile_t.ES_PROFILE && version_ >= 450) ||
      (profile == glslang_profile_t.ES_PROFILE && version_ >= 310)) {
      commonBuiltins ~= q{
        float16_t radians(float16_t);
        f16vec2 radians(f16vec2);
        f16vec3 radians(f16vec3);
        f16vec4 radians(f16vec4);

        float16_t degrees(float16_t);
        f16vec2 degrees(f16vec2);
        f16vec3 degrees(f16vec3);
        f16vec4 degrees(f16vec4);

        float16_t sin(float16_t);
        f16vec2 sin(f16vec2);
        f16vec3 sin(f16vec3);
        f16vec4 sin(f16vec4);

        float16_t cos(float16_t);
        f16vec2 cos(f16vec2);
        f16vec3 cos(f16vec3);
        f16vec4 cos(f16vec4);

        float16_t tan(float16_t);
        f16vec2 tan(f16vec2);
        f16vec3 tan(f16vec3);
        f16vec4 tan(f16vec4);

        float16_t asin(float16_t);
        f16vec2 asin(f16vec2);
        f16vec3 asin(f16vec3);
        f16vec4 asin(f16vec4);

        float16_t acos(float16_t);
        f16vec2 acos(f16vec2);
        f16vec3 acos(f16vec3);
        f16vec4 acos(f16vec4);

        float16_t atan(float16_t, float16_t);
        f16vec2 atan(f16vec2, f16vec2);
        f16vec3 atan(f16vec3, f16vec3);
        f16vec4 atan(f16vec4, f16vec4);

        float16_t atan(float16_t);
        f16vec2 atan(f16vec2);
        f16vec3 atan(f16vec3);
        f16vec4 atan(f16vec4);

        float16_t sinh(float16_t);
        f16vec2 sinh(f16vec2);
        f16vec3 sinh(f16vec3);
        f16vec4 sinh(f16vec4);

        float16_t cosh(float16_t);
        f16vec2 cosh(f16vec2);
        f16vec3 cosh(f16vec3);
        f16vec4 cosh(f16vec4);

        float16_t tanh(float16_t);
        f16vec2 tanh(f16vec2);
        f16vec3 tanh(f16vec3);
        f16vec4 tanh(f16vec4);

        float16_t asinh(float16_t);
        f16vec2 asinh(f16vec2);
        f16vec3 asinh(f16vec3);
        f16vec4 asinh(f16vec4);

        float16_t acosh(float16_t);
        f16vec2 acosh(f16vec2);
        f16vec3 acosh(f16vec3);
        f16vec4 acosh(f16vec4);

        float16_t atanh(float16_t);
        f16vec2 atanh(f16vec2);
        f16vec3 atanh(f16vec3);
        f16vec4 atanh(f16vec4);

        float16_t pow(float16_t, float16_t);
        f16vec2 pow(f16vec2, f16vec2);
        f16vec3 pow(f16vec3, f16vec3);
        f16vec4 pow(f16vec4, f16vec4);

        float16_t exp(float16_t);
        f16vec2 exp(f16vec2);
        f16vec3 exp(f16vec3);
        f16vec4 exp(f16vec4);

        float16_t log(float16_t);
        f16vec2 log(f16vec2);
        f16vec3 log(f16vec3);
        f16vec4 log(f16vec4);

        float16_t exp2(float16_t);
        f16vec2 exp2(f16vec2);
        f16vec3 exp2(f16vec3);
        f16vec4 exp2(f16vec4);

        float16_t log2(float16_t);
        f16vec2 log2(f16vec2);
        f16vec3 log2(f16vec3);
        f16vec4 log2(f16vec4);

        float16_t sqrt(float16_t);
        f16vec2 sqrt(f16vec2);
        f16vec3 sqrt(f16vec3);
        f16vec4 sqrt(f16vec4);

        float16_t inversesqrt(float16_t);
        f16vec2 inversesqrt(f16vec2);
        f16vec3 inversesqrt(f16vec3);
        f16vec4 inversesqrt(f16vec4);

        float16_t abs(float16_t);
        f16vec2 abs(f16vec2);
        f16vec3 abs(f16vec3);
        f16vec4 abs(f16vec4);

        float16_t sign(float16_t);
        f16vec2 sign(f16vec2);
        f16vec3 sign(f16vec3);
        f16vec4 sign(f16vec4);

        float16_t floor(float16_t);
        f16vec2 floor(f16vec2);
        f16vec3 floor(f16vec3);
        f16vec4 floor(f16vec4);

        float16_t trunc(float16_t);
        f16vec2 trunc(f16vec2);
        f16vec3 trunc(f16vec3);
        f16vec4 trunc(f16vec4);

        float16_t round(float16_t);
        f16vec2 round(f16vec2);
        f16vec3 round(f16vec3);
        f16vec4 round(f16vec4);

        float16_t roundEven(float16_t);
        f16vec2 roundEven(f16vec2);
        f16vec3 roundEven(f16vec3);
        f16vec4 roundEven(f16vec4);

        float16_t ceil(float16_t);
        f16vec2 ceil(f16vec2);
        f16vec3 ceil(f16vec3);
        f16vec4 ceil(f16vec4);

        float16_t fract(float16_t);
        f16vec2 fract(f16vec2);
        f16vec3 fract(f16vec3);
        f16vec4 fract(f16vec4);

        float16_t mod(float16_t, float16_t);
        f16vec2 mod(f16vec2, float16_t);
        f16vec3 mod(f16vec3, float16_t);
        f16vec4 mod(f16vec4, float16_t);
        f16vec2 mod(f16vec2, f16vec2);
        f16vec3 mod(f16vec3, f16vec3);
        f16vec4 mod(f16vec4, f16vec4);

        float16_t modf(float16_t, out float16_t);
        f16vec2 modf(f16vec2, out f16vec2);
        f16vec3 modf(f16vec3, out f16vec3);
        f16vec4 modf(f16vec4, out f16vec4);

        float16_t min(float16_t, float16_t);
        f16vec2 min(f16vec2, float16_t);
        f16vec3 min(f16vec3, float16_t);
        f16vec4 min(f16vec4, float16_t);
        f16vec2 min(f16vec2, f16vec2);
        f16vec3 min(f16vec3, f16vec3);
        f16vec4 min(f16vec4, f16vec4);

        float16_t max(float16_t, float16_t);
        f16vec2 max(f16vec2, float16_t);
        f16vec3 max(f16vec3, float16_t);
        f16vec4 max(f16vec4, float16_t);
        f16vec2 max(f16vec2, f16vec2);
        f16vec3 max(f16vec3, f16vec3);
        f16vec4 max(f16vec4, f16vec4);

        float16_t clamp(float16_t, float16_t, float16_t);
        f16vec2 clamp(f16vec2, float16_t, float16_t);
        f16vec3 clamp(f16vec3, float16_t, float16_t);
        f16vec4 clamp(f16vec4, float16_t, float16_t);
        f16vec2 clamp(f16vec2, f16vec2, f16vec2);
        f16vec3 clamp(f16vec3, f16vec3, f16vec3);
        f16vec4 clamp(f16vec4, f16vec4, f16vec4);

        float16_t mix(float16_t, float16_t, float16_t);
        f16vec2 mix(f16vec2, f16vec2, float16_t);
        f16vec3 mix(f16vec3, f16vec3, float16_t);
        f16vec4 mix(f16vec4, f16vec4, float16_t);
        f16vec2 mix(f16vec2, f16vec2, f16vec2);
        f16vec3 mix(f16vec3, f16vec3, f16vec3);
        f16vec4 mix(f16vec4, f16vec4, f16vec4);
        float16_t mix(float16_t, float16_t, bool);
        f16vec2 mix(f16vec2, f16vec2, bvec2);
        f16vec3 mix(f16vec3, f16vec3, bvec3);
        f16vec4 mix(f16vec4, f16vec4, bvec4);

        float16_t step(float16_t, float16_t);
        f16vec2 step(f16vec2, f16vec2);
        f16vec3 step(f16vec3, f16vec3);
        f16vec4 step(f16vec4, f16vec4);
        f16vec2 step(float16_t, f16vec2);
        f16vec3 step(float16_t, f16vec3);
        f16vec4 step(float16_t, f16vec4);

        float16_t smoothstep(float16_t, float16_t, float16_t);
        f16vec2 smoothstep(f16vec2, f16vec2, f16vec2);
        f16vec3 smoothstep(f16vec3, f16vec3, f16vec3);
        f16vec4 smoothstep(f16vec4, f16vec4, f16vec4);
        f16vec2 smoothstep(float16_t, float16_t, f16vec2);
        f16vec3 smoothstep(float16_t, float16_t, f16vec3);
        f16vec4 smoothstep(float16_t, float16_t, f16vec4);

        bool isnan(float16_t);
        bvec2 isnan(f16vec2);
        bvec3 isnan(f16vec3);
        bvec4 isnan(f16vec4);

        bool isinf(float16_t);
        bvec2 isinf(f16vec2);
        bvec3 isinf(f16vec3);
        bvec4 isinf(f16vec4);

        float16_t fma(float16_t, float16_t, float16_t);
        f16vec2 fma(f16vec2, f16vec2, f16vec2);
        f16vec3 fma(f16vec3, f16vec3, f16vec3);
        f16vec4 fma(f16vec4, f16vec4, f16vec4);

        float16_t frexp(float16_t, out int);
        f16vec2 frexp(f16vec2, out ivec2);
        f16vec3 frexp(f16vec3, out ivec3);
        f16vec4 frexp(f16vec4, out ivec4);

        float16_t ldexp(float16_t, in int);
        f16vec2 ldexp(f16vec2, in ivec2);
        f16vec3 ldexp(f16vec3, in ivec3);
        f16vec4 ldexp(f16vec4, in ivec4);

        uint packFloat2x16(f16vec2);
        f16vec2 unpackFloat2x16(uint);

        float16_t length(float16_t);
        float16_t length(f16vec2);
        float16_t length(f16vec3);
        float16_t length(f16vec4);

        float16_t distance(float16_t, float16_t);
        float16_t distance(f16vec2, f16vec2);
        float16_t distance(f16vec3, f16vec3);
        float16_t distance(f16vec4, f16vec4);

        float16_t dot(float16_t, float16_t);
        float16_t dot(f16vec2, f16vec2);
        float16_t dot(f16vec3, f16vec3);
        float16_t dot(f16vec4, f16vec4);

        f16vec3 cross(f16vec3, f16vec3);

        float16_t normalize(float16_t);
        f16vec2 normalize(f16vec2);
        f16vec3 normalize(f16vec3);
        f16vec4 normalize(f16vec4);

        float16_t faceforward(float16_t, float16_t, float16_t);
        f16vec2 faceforward(f16vec2, f16vec2, f16vec2);
        f16vec3 faceforward(f16vec3, f16vec3, f16vec3);
        f16vec4 faceforward(f16vec4, f16vec4, f16vec4);

        float16_t reflect(float16_t, float16_t);
        f16vec2 reflect(f16vec2, f16vec2);
        f16vec3 reflect(f16vec3, f16vec3);
        f16vec4 reflect(f16vec4, f16vec4);

        float16_t refract(float16_t, float16_t, float16_t);
        f16vec2 refract(f16vec2, f16vec2, float16_t);
        f16vec3 refract(f16vec3, f16vec3, float16_t);
        f16vec4 refract(f16vec4, f16vec4, float16_t);

        f16mat2 matrixCompMult(f16mat2, f16mat2);
        f16mat3 matrixCompMult(f16mat3, f16mat3);
        f16mat4 matrixCompMult(f16mat4, f16mat4);
        f16mat2x3 matrixCompMult(f16mat2x3, f16mat2x3);
        f16mat2x4 matrixCompMult(f16mat2x4, f16mat2x4);
        f16mat3x2 matrixCompMult(f16mat3x2, f16mat3x2);
        f16mat3x4 matrixCompMult(f16mat3x4, f16mat3x4);
        f16mat4x2 matrixCompMult(f16mat4x2, f16mat4x2);
        f16mat4x3 matrixCompMult(f16mat4x3, f16mat4x3);

        f16mat2 outerProduct(f16vec2, f16vec2);
        f16mat3 outerProduct(f16vec3, f16vec3);
        f16mat4 outerProduct(f16vec4, f16vec4);
        f16mat2x3 outerProduct(f16vec3, f16vec2);
        f16mat3x2 outerProduct(f16vec2, f16vec3);
        f16mat2x4 outerProduct(f16vec4, f16vec2);
        f16mat4x2 outerProduct(f16vec2, f16vec4);
        f16mat3x4 outerProduct(f16vec4, f16vec3);
        f16mat4x3 outerProduct(f16vec3, f16vec4);

        f16mat2 transpose(f16mat2);
        f16mat3 transpose(f16mat3);
        f16mat4 transpose(f16mat4);
        f16mat2x3 transpose(f16mat3x2);
        f16mat3x2 transpose(f16mat2x3);
        f16mat2x4 transpose(f16mat4x2);
        f16mat4x2 transpose(f16mat2x4);
        f16mat3x4 transpose(f16mat4x3);
        f16mat4x3 transpose(f16mat3x4);

        float16_t determinant(f16mat2);
        float16_t determinant(f16mat3);
        float16_t determinant(f16mat4);

        f16mat2 inverse(f16mat2);
        f16mat3 inverse(f16mat3);
        f16mat4 inverse(f16mat4);

        bvec2 lessThan(f16vec2, f16vec2);
        bvec3 lessThan(f16vec3, f16vec3);
        bvec4 lessThan(f16vec4, f16vec4);

        bvec2 lessThanEqual(f16vec2, f16vec2);
        bvec3 lessThanEqual(f16vec3, f16vec3);
        bvec4 lessThanEqual(f16vec4, f16vec4);

        bvec2 greaterThan(f16vec2, f16vec2);
        bvec3 greaterThan(f16vec3, f16vec3);
        bvec4 greaterThan(f16vec4, f16vec4);

        bvec2 greaterThanEqual(f16vec2, f16vec2);
        bvec3 greaterThanEqual(f16vec3, f16vec3);
        bvec4 greaterThanEqual(f16vec4, f16vec4);

        bvec2 equal(f16vec2, f16vec2);
        bvec3 equal(f16vec3, f16vec3);
        bvec4 equal(f16vec4, f16vec4);

        bvec2 notEqual(f16vec2, f16vec2);
        bvec3 notEqual(f16vec3, f16vec3);
        bvec4 notEqual(f16vec4, f16vec4);

        bfloat16_t dot(bfloat16_t, bfloat16_t);
        bfloat16_t dot(bf16vec2, bf16vec2);
        bfloat16_t dot(bf16vec3, bf16vec3);
        bfloat16_t dot(bf16vec4, bf16vec4);

        int16_t bfloat16BitsToIntEXT(bfloat16_t value);
        i16vec2 bfloat16BitsToIntEXT(bf16vec2 value);
        i16vec3 bfloat16BitsToIntEXT(bf16vec3 value);
        i16vec4 bfloat16BitsToIntEXT(bf16vec4 value);

        uint16_t bfloat16BitsToUintEXT(bfloat16_t value);
        u16vec2 bfloat16BitsToUintEXT(bf16vec2 value);
        u16vec3 bfloat16BitsToUintEXT(bf16vec3 value);
        u16vec4 bfloat16BitsToUintEXT(bf16vec4 value);

        bfloat16_t intBitsToBFloat16EXT(int16_t value);
        bf16vec2 intBitsToBFloat16EXT(i16vec2 value);
        bf16vec3 intBitsToBFloat16EXT(i16vec3 value);
        bf16vec4 intBitsToBFloat16EXT(i16vec4 value);

        bfloat16_t uintBitsToBFloat16EXT(uint16_t value);
        bf16vec2 uintBitsToBFloat16EXT(u16vec2 value);
        bf16vec3 uintBitsToBFloat16EXT(u16vec3 value);
        bf16vec4 uintBitsToBFloat16EXT(u16vec4 value);

      int8_t floate5m2BitsToIntEXT(floate5m2_t value);
        i8vec2 floate5m2BitsToIntEXT(fe5m2vec2 value);
        i8vec3 floate5m2BitsToIntEXT(fe5m2vec3 value);
        i8vec4 floate5m2BitsToIntEXT(fe5m2vec4 value);

        uint8_t floate5m2BitsToUintEXT(floate5m2_t value);
        u8vec2 floate5m2BitsToUintEXT(fe5m2vec2 value);
        u8vec3 floate5m2BitsToUintEXT(fe5m2vec3 value);
        u8vec4 floate5m2BitsToUintEXT(fe5m2vec4 value);

        floate5m2_t intBitsToFloate5m2EXT(int8_t value);
        fe5m2vec2 intBitsToFloate5m2EXT(i8vec2 value);
        fe5m2vec3 intBitsToFloate5m2EXT(i8vec3 value);
        fe5m2vec4 intBitsToFloate5m2EXT(i8vec4 value);

        floate5m2_t uintBitsToFloate5m2EXT(uint8_t value);
        fe5m2vec2 uintBitsToFloate5m2EXT(u8vec2 value);
        fe5m2vec3 uintBitsToFloate5m2EXT(u8vec3 value);
        fe5m2vec4 uintBitsToFloate5m2EXT(u8vec4 value);

      int8_t floate4m3BitsToIntEXT(floate4m3_t value);
        i8vec2 floate4m3BitsToIntEXT(fe4m3vec2 value);
        i8vec3 floate4m3BitsToIntEXT(fe4m3vec3 value);
        i8vec4 floate4m3BitsToIntEXT(fe4m3vec4 value);

        uint8_t floate4m3BitsToUintEXT(floate4m3_t value);
        u8vec2 floate4m3BitsToUintEXT(fe4m3vec2 value);
        u8vec3 floate4m3BitsToUintEXT(fe4m3vec3 value);
        u8vec4 floate4m3BitsToUintEXT(fe4m3vec4 value);

        floate4m3_t intBitsToFloate4m3EXT(int8_t value);
        fe4m3vec2 intBitsToFloate4m3EXT(i8vec2 value);
        fe4m3vec3 intBitsToFloate4m3EXT(i8vec3 value);
        fe4m3vec4 intBitsToFloate4m3EXT(i8vec4 value);

        floate4m3_t uintBitsToFloate4m3EXT(uint8_t value);
        fe4m3vec2 uintBitsToFloate4m3EXT(u8vec2 value);
        fe4m3vec3 uintBitsToFloate4m3EXT(u8vec3 value);
        fe4m3vec4 uintBitsToFloate4m3EXT(u8vec4 value);

        void saturatedConvertEXT();
      };
    }

    if ((profile != glslang_profile_t.ES_PROFILE && version_ >= 450) ||
      (profile == glslang_profile_t.ES_PROFILE && version_ >= 310)) {
      commonBuiltins ~= q{
        int8_t abs(int8_t);
        i8vec2 abs(i8vec2);
        i8vec3 abs(i8vec3);
        i8vec4 abs(i8vec4);

        int8_t sign(int8_t);
        i8vec2 sign(i8vec2);
        i8vec3 sign(i8vec3);
        i8vec4 sign(i8vec4);

        int8_t min(int8_t x, int8_t y);
        i8vec2 min(i8vec2 x, int8_t y);
        i8vec3 min(i8vec3 x, int8_t y);
        i8vec4 min(i8vec4 x, int8_t y);
        i8vec2 min(i8vec2 x, i8vec2 y);
        i8vec3 min(i8vec3 x, i8vec3 y);
        i8vec4 min(i8vec4 x, i8vec4 y);

        uint8_t min(uint8_t x, uint8_t y);
        u8vec2 min(u8vec2 x, uint8_t y);
        u8vec3 min(u8vec3 x, uint8_t y);
        u8vec4 min(u8vec4 x, uint8_t y);
        u8vec2 min(u8vec2 x, u8vec2 y);
        u8vec3 min(u8vec3 x, u8vec3 y);
        u8vec4 min(u8vec4 x, u8vec4 y);

        int8_t max(int8_t x, int8_t y);
        i8vec2 max(i8vec2 x, int8_t y);
        i8vec3 max(i8vec3 x, int8_t y);
        i8vec4 max(i8vec4 x, int8_t y);
        i8vec2 max(i8vec2 x, i8vec2 y);
        i8vec3 max(i8vec3 x, i8vec3 y);
        i8vec4 max(i8vec4 x, i8vec4 y);

        uint8_t max(uint8_t x, uint8_t y);
        u8vec2 max(u8vec2 x, uint8_t y);
        u8vec3 max(u8vec3 x, uint8_t y);
        u8vec4 max(u8vec4 x, uint8_t y);
        u8vec2 max(u8vec2 x, u8vec2 y);
        u8vec3 max(u8vec3 x, u8vec3 y);
        u8vec4 max(u8vec4 x, u8vec4 y);

        int8_t clamp(int8_t x, int8_t minVal, int8_t maxVal);
        i8vec2 clamp(i8vec2 x, int8_t minVal, int8_t maxVal);
        i8vec3 clamp(i8vec3 x, int8_t minVal, int8_t maxVal);
        i8vec4 clamp(i8vec4 x, int8_t minVal, int8_t maxVal);
        i8vec2 clamp(i8vec2 x, i8vec2 minVal, i8vec2 maxVal);
        i8vec3 clamp(i8vec3 x, i8vec3 minVal, i8vec3 maxVal);
        i8vec4 clamp(i8vec4 x, i8vec4 minVal, i8vec4 maxVal);

        uint8_t clamp(uint8_t x, uint8_t minVal, uint8_t maxVal);
        u8vec2 clamp(u8vec2 x, uint8_t minVal, uint8_t maxVal);
        u8vec3 clamp(u8vec3 x, uint8_t minVal, uint8_t maxVal);
        u8vec4 clamp(u8vec4 x, uint8_t minVal, uint8_t maxVal);
        u8vec2 clamp(u8vec2 x, u8vec2 minVal, u8vec2 maxVal);
        u8vec3 clamp(u8vec3 x, u8vec3 minVal, u8vec3 maxVal);
        u8vec4 clamp(u8vec4 x, u8vec4 minVal, u8vec4 maxVal);

        int8_t mix(int8_t,int8_t, bool);
        i8vec2 mix(i8vec2, i8vec2, bvec2);
        i8vec3 mix(i8vec3, i8vec3, bvec3);
        i8vec4 mix(i8vec4, i8vec4, bvec4);
        uint8_t mix(uint8_t, uint8_t, bool);
        u8vec2 mix(u8vec2, u8vec2, bvec2);
        u8vec3 mix(u8vec3, u8vec3, bvec3);
        u8vec4 mix(u8vec4, u8vec4, bvec4);

        bvec2 lessThan(i8vec2, i8vec2);
        bvec3 lessThan(i8vec3, i8vec3);
        bvec4 lessThan(i8vec4, i8vec4);
        bvec2 lessThan(u8vec2, u8vec2);
        bvec3 lessThan(u8vec3, u8vec3);
        bvec4 lessThan(u8vec4, u8vec4);

        bvec2 lessThanEqual(i8vec2, i8vec2);
        bvec3 lessThanEqual(i8vec3, i8vec3);
        bvec4 lessThanEqual(i8vec4, i8vec4);
        bvec2 lessThanEqual(u8vec2, u8vec2);
        bvec3 lessThanEqual(u8vec3, u8vec3);
        bvec4 lessThanEqual(u8vec4, u8vec4);

        bvec2 greaterThan(i8vec2, i8vec2);
        bvec3 greaterThan(i8vec3, i8vec3);
        bvec4 greaterThan(i8vec4, i8vec4);
        bvec2 greaterThan(u8vec2, u8vec2);
        bvec3 greaterThan(u8vec3, u8vec3);
        bvec4 greaterThan(u8vec4, u8vec4);

        bvec2 greaterThanEqual(i8vec2, i8vec2);
        bvec3 greaterThanEqual(i8vec3, i8vec3);
        bvec4 greaterThanEqual(i8vec4, i8vec4);
        bvec2 greaterThanEqual(u8vec2, u8vec2);
        bvec3 greaterThanEqual(u8vec3, u8vec3);
        bvec4 greaterThanEqual(u8vec4, u8vec4);

        bvec2 equal(i8vec2, i8vec2);
        bvec3 equal(i8vec3, i8vec3);
        bvec4 equal(i8vec4, i8vec4);
        bvec2 equal(u8vec2, u8vec2);
        bvec3 equal(u8vec3, u8vec3);
        bvec4 equal(u8vec4, u8vec4);

        bvec2 notEqual(i8vec2, i8vec2);
        bvec3 notEqual(i8vec3, i8vec3);
        bvec4 notEqual(i8vec4, i8vec4);
        bvec2 notEqual(u8vec2, u8vec2);
        bvec3 notEqual(u8vec3, u8vec3);
        bvec4 notEqual(u8vec4, u8vec4);

        int8_t bitfieldExtract(int8_t, int8_t, int8_t);
        i8vec2 bitfieldExtract(i8vec2, int8_t, int8_t);
        i8vec3 bitfieldExtract(i8vec3, int8_t, int8_t);
        i8vec4 bitfieldExtract(i8vec4, int8_t, int8_t);

        uint8_t bitfieldExtract(uint8_t, int8_t, int8_t);
        u8vec2 bitfieldExtract(u8vec2, int8_t, int8_t);
        u8vec3 bitfieldExtract(u8vec3, int8_t, int8_t);
        u8vec4 bitfieldExtract(u8vec4, int8_t, int8_t);

        int8_t bitfieldInsert(int8_t base, int8_t, int8_t, int8_t);
        i8vec2 bitfieldInsert(i8vec2 base, i8vec2, int8_t, int8_t);
        i8vec3 bitfieldInsert(i8vec3 base, i8vec3, int8_t, int8_t);
        i8vec4 bitfieldInsert(i8vec4 base, i8vec4, int8_t, int8_t);

        uint8_t bitfieldInsert(uint8_t base, uint8_t, int8_t, int8_t);
        u8vec2 bitfieldInsert(u8vec2 base, u8vec2, int8_t, int8_t);
        u8vec3 bitfieldInsert(u8vec3 base, u8vec3, int8_t, int8_t);
        u8vec4 bitfieldInsert(u8vec4 base, u8vec4, int8_t, int8_t);

        int8_t bitCount(int8_t);
        i8vec2 bitCount(i8vec2);
        i8vec3 bitCount(i8vec3);
        i8vec4 bitCount(i8vec4);

        int8_t bitCount(uint8_t);
        i8vec2 bitCount(u8vec2);
        i8vec3 bitCount(u8vec3);
        i8vec4 bitCount(u8vec4);

        int8_t findLSB(int8_t);
        i8vec2 findLSB(i8vec2);
        i8vec3 findLSB(i8vec3);
        i8vec4 findLSB(i8vec4);

        int8_t findLSB(uint8_t);
        i8vec2 findLSB(u8vec2);
        i8vec3 findLSB(u8vec3);
        i8vec4 findLSB(u8vec4);

        int8_t findMSB(int8_t);
        i8vec2 findMSB(i8vec2);
        i8vec3 findMSB(i8vec3);
        i8vec4 findMSB(i8vec4);

        int8_t findMSB(uint8_t);
        i8vec2 findMSB(u8vec2);
        i8vec3 findMSB(u8vec3);
        i8vec4 findMSB(u8vec4);

        int16_t abs(int16_t);
        i16vec2 abs(i16vec2);
        i16vec3 abs(i16vec3);
        i16vec4 abs(i16vec4);

        int16_t sign(int16_t);
        i16vec2 sign(i16vec2);
        i16vec3 sign(i16vec3);
        i16vec4 sign(i16vec4);

        int16_t min(int16_t x, int16_t y);
        i16vec2 min(i16vec2 x, int16_t y);
        i16vec3 min(i16vec3 x, int16_t y);
        i16vec4 min(i16vec4 x, int16_t y);
        i16vec2 min(i16vec2 x, i16vec2 y);
        i16vec3 min(i16vec3 x, i16vec3 y);
        i16vec4 min(i16vec4 x, i16vec4 y);

        uint16_t min(uint16_t x, uint16_t y);
        u16vec2 min(u16vec2 x, uint16_t y);
        u16vec3 min(u16vec3 x, uint16_t y);
        u16vec4 min(u16vec4 x, uint16_t y);
        u16vec2 min(u16vec2 x, u16vec2 y);
        u16vec3 min(u16vec3 x, u16vec3 y);
        u16vec4 min(u16vec4 x, u16vec4 y);

        int16_t max(int16_t x, int16_t y);
        i16vec2 max(i16vec2 x, int16_t y);
        i16vec3 max(i16vec3 x, int16_t y);
        i16vec4 max(i16vec4 x, int16_t y);
        i16vec2 max(i16vec2 x, i16vec2 y);
        i16vec3 max(i16vec3 x, i16vec3 y);
        i16vec4 max(i16vec4 x, i16vec4 y);

        uint16_t max(uint16_t x, uint16_t y);
        u16vec2 max(u16vec2 x, uint16_t y);
        u16vec3 max(u16vec3 x, uint16_t y);
        u16vec4 max(u16vec4 x, uint16_t y);
        u16vec2 max(u16vec2 x, u16vec2 y);
        u16vec3 max(u16vec3 x, u16vec3 y);
        u16vec4 max(u16vec4 x, u16vec4 y);

        int16_t clamp(int16_t x, int16_t minVal, int16_t maxVal);
        i16vec2 clamp(i16vec2 x, int16_t minVal, int16_t maxVal);
        i16vec3 clamp(i16vec3 x, int16_t minVal, int16_t maxVal);
        i16vec4 clamp(i16vec4 x, int16_t minVal, int16_t maxVal);
        i16vec2 clamp(i16vec2 x, i16vec2 minVal, i16vec2 maxVal);
        i16vec3 clamp(i16vec3 x, i16vec3 minVal, i16vec3 maxVal);
        i16vec4 clamp(i16vec4 x, i16vec4 minVal, i16vec4 maxVal);

        uint16_t clamp(uint16_t x, uint16_t minVal, uint16_t maxVal);
        u16vec2 clamp(u16vec2 x, uint16_t minVal, uint16_t maxVal);
        u16vec3 clamp(u16vec3 x, uint16_t minVal, uint16_t maxVal);
        u16vec4 clamp(u16vec4 x, uint16_t minVal, uint16_t maxVal);
        u16vec2 clamp(u16vec2 x, u16vec2 minVal, u16vec2 maxVal);
        u16vec3 clamp(u16vec3 x, u16vec3 minVal, u16vec3 maxVal);
        u16vec4 clamp(u16vec4 x, u16vec4 minVal, u16vec4 maxVal);

        int16_t mix(int16_t, int16_t, bool);
        i16vec2 mix(i16vec2, i16vec2, bvec2);
        i16vec3 mix(i16vec3, i16vec3, bvec3);
        i16vec4 mix(i16vec4, i16vec4, bvec4);
        uint16_t mix(uint16_t, uint16_t, bool);
        u16vec2 mix(u16vec2, u16vec2, bvec2);
        u16vec3 mix(u16vec3, u16vec3, bvec3);
        u16vec4 mix(u16vec4, u16vec4, bvec4);

        float16_t frexp(float16_t, out int16_t);
        f16vec2 frexp(f16vec2, out i16vec2);
        f16vec3 frexp(f16vec3, out i16vec3);
        f16vec4 frexp(f16vec4, out i16vec4);

        float16_t ldexp(float16_t, int16_t);
        f16vec2 ldexp(f16vec2, i16vec2);
        f16vec3 ldexp(f16vec3, i16vec3);
        f16vec4 ldexp(f16vec4, i16vec4);

        int16_t halfBitsToInt16(float16_t);
        i16vec2 halfBitsToInt16(f16vec2);
        i16vec3 halhBitsToInt16(f16vec3);
        i16vec4 halfBitsToInt16(f16vec4);

        uint16_t halfBitsToUint16(float16_t);
        u16vec2 halfBitsToUint16(f16vec2);
        u16vec3 halfBitsToUint16(f16vec3);
        u16vec4 halfBitsToUint16(f16vec4);

        int16_t float16BitsToInt16(float16_t);
        i16vec2 float16BitsToInt16(f16vec2);
        i16vec3 float16BitsToInt16(f16vec3);
        i16vec4 float16BitsToInt16(f16vec4);

        uint16_t float16BitsToUint16(float16_t);
        u16vec2 float16BitsToUint16(f16vec2);
        u16vec3 float16BitsToUint16(f16vec3);
        u16vec4 float16BitsToUint16(f16vec4);

        float16_t int16BitsToFloat16(int16_t);
        f16vec2 int16BitsToFloat16(i16vec2);
        f16vec3 int16BitsToFloat16(i16vec3);
        f16vec4 int16BitsToFloat16(i16vec4);

        float16_t uint16BitsToFloat16(uint16_t);
        f16vec2 uint16BitsToFloat16(u16vec2);
        f16vec3 uint16BitsToFloat16(u16vec3);
        f16vec4 uint16BitsToFloat16(u16vec4);

        float16_t int16BitsToHalf(int16_t);
        f16vec2 int16BitsToHalf(i16vec2);
        f16vec3 int16BitsToHalf(i16vec3);
        f16vec4 int16BitsToHalf(i16vec4);

        float16_t uint16BitsToHalf(uint16_t);
        f16vec2 uint16BitsToHalf(u16vec2);
        f16vec3 uint16BitsToHalf(u16vec3);
        f16vec4 uint16BitsToHalf(u16vec4);

        int packInt2x16(i16vec2);
        uint packUint2x16(u16vec2);
        int64_t packInt4x16(i16vec4);
        uint64_t packUint4x16(u16vec4);
        i16vec2 unpackInt2x16(int);
        u16vec2 unpackUint2x16(uint);
        i16vec4 unpackInt4x16(int64_t);
        u16vec4 unpackUint4x16(uint64_t);

        bvec2 lessThan(i16vec2, i16vec2);
        bvec3 lessThan(i16vec3, i16vec3);
        bvec4 lessThan(i16vec4, i16vec4);
        bvec2 lessThan(u16vec2, u16vec2);
        bvec3 lessThan(u16vec3, u16vec3);
        bvec4 lessThan(u16vec4, u16vec4);

        bvec2 lessThanEqual(i16vec2, i16vec2);
        bvec3 lessThanEqual(i16vec3, i16vec3);
        bvec4 lessThanEqual(i16vec4, i16vec4);
        bvec2 lessThanEqual(u16vec2, u16vec2);
        bvec3 lessThanEqual(u16vec3, u16vec3);
        bvec4 lessThanEqual(u16vec4, u16vec4);

        bvec2 greaterThan(i16vec2, i16vec2);
        bvec3 greaterThan(i16vec3, i16vec3);
        bvec4 greaterThan(i16vec4, i16vec4);
        bvec2 greaterThan(u16vec2, u16vec2);
        bvec3 greaterThan(u16vec3, u16vec3);
        bvec4 greaterThan(u16vec4, u16vec4);

        bvec2 greaterThanEqual(i16vec2, i16vec2);
        bvec3 greaterThanEqual(i16vec3, i16vec3);
        bvec4 greaterThanEqual(i16vec4, i16vec4);
        bvec2 greaterThanEqual(u16vec2, u16vec2);
        bvec3 greaterThanEqual(u16vec3, u16vec3);
        bvec4 greaterThanEqual(u16vec4, u16vec4);

        bvec2 equal(i16vec2, i16vec2);
        bvec3 equal(i16vec3, i16vec3);
        bvec4 equal(i16vec4, i16vec4);
        bvec2 equal(u16vec2, u16vec2);
        bvec3 equal(u16vec3, u16vec3);
        bvec4 equal(u16vec4, u16vec4);

        bvec2 notEqual(i16vec2, i16vec2);
        bvec3 notEqual(i16vec3, i16vec3);
        bvec4 notEqual(i16vec4, i16vec4);
        bvec2 notEqual(u16vec2, u16vec2);
        bvec3 notEqual(u16vec3, u16vec3);
        bvec4 notEqual(u16vec4, u16vec4);

        int16_t bitfieldExtract(int16_t, int16_t, int16_t);
        i16vec2 bitfieldExtract(i16vec2, int16_t, int16_t);
        i16vec3 bitfieldExtract(i16vec3, int16_t, int16_t);
        i16vec4 bitfieldExtract(i16vec4, int16_t, int16_t);

        uint16_t bitfieldExtract(uint16_t, int16_t, int16_t);
        u16vec2 bitfieldExtract(u16vec2, int16_t, int16_t);
        u16vec3 bitfieldExtract(u16vec3, int16_t, int16_t);
        u16vec4 bitfieldExtract(u16vec4, int16_t, int16_t);

        int16_t bitfieldInsert(int16_t base, int16_t, int16_t, int16_t);
        i16vec2 bitfieldInsert(i16vec2 base, i16vec2, int16_t, int16_t);
        i16vec3 bitfieldInsert(i16vec3 base, i16vec3, int16_t, int16_t);
        i16vec4 bitfieldInsert(i16vec4 base, i16vec4, int16_t, int16_t);

        uint16_t bitfieldInsert(uint16_t base, uint16_t, int16_t, int16_t);
        u16vec2 bitfieldInsert(u16vec2 base, u16vec2, int16_t, int16_t);
        u16vec3 bitfieldInsert(u16vec3 base, u16vec3, int16_t, int16_t);
        u16vec4 bitfieldInsert(u16vec4 base, u16vec4, int16_t, int16_t);

        int16_t bitCount(int16_t);
        i16vec2 bitCount(i16vec2);
        i16vec3 bitCount(i16vec3);
        i16vec4 bitCount(i16vec4);

        int16_t bitCount(uint16_t);
        i16vec2 bitCount(u16vec2);
        i16vec3 bitCount(u16vec3);
        i16vec4 bitCount(u16vec4);

        int16_t findLSB(int16_t);
        i16vec2 findLSB(i16vec2);
        i16vec3 findLSB(i16vec3);
        i16vec4 findLSB(i16vec4);

        int16_t findLSB(uint16_t);
        i16vec2 findLSB(u16vec2);
        i16vec3 findLSB(u16vec3);
        i16vec4 findLSB(u16vec4);

        int16_t findMSB(int16_t);
        i16vec2 findMSB(i16vec2);
        i16vec3 findMSB(i16vec3);
        i16vec4 findMSB(i16vec4);

        int16_t findMSB(uint16_t);
        i16vec2 findMSB(u16vec2);
        i16vec3 findMSB(u16vec3);
        i16vec4 findMSB(u16vec4);

        int16_t pack16(i8vec2);
        uint16_t pack16(u8vec2);
        int32_t pack32(i8vec4);
        uint32_t pack32(u8vec4);
        int32_t pack32(i16vec2);
        uint32_t pack32(u16vec2);
        int64_t pack64(i16vec4);
        uint64_t pack64(u16vec4);
        int64_t pack64(i32vec2);
        uint64_t pack64(u32vec2);

        i8vec2 unpack8(int16_t);
        u8vec2 unpack8(uint16_t);
        i8vec4 unpack8(int32_t);
        u8vec4 unpack8(uint32_t);
        i16vec2 unpack16(int32_t);
        u16vec2 unpack16(uint32_t);
        i16vec4 unpack16(int64_t);
        u16vec4 unpack16(uint64_t);
        i32vec2 unpack32(int64_t);
        u32vec2 unpack32(uint64_t);

        int8_t expectEXT(int8_t, int8_t);
        i8vec2 expectEXT(i8vec2, i8vec2);
        i8vec3 expectEXT(i8vec3, i8vec3);
        i8vec4 expectEXT(i8vec4, i8vec4);

        uint8_t expectEXT(uint8_t, uint8_t);
        u8vec2 expectEXT(u8vec2, u8vec2);
        u8vec3 expectEXT(u8vec3, u8vec3);
        u8vec4 expectEXT(u8vec4, u8vec4);

        int16_t expectEXT(int16_t, int16_t);
        i16vec2 expectEXT(i16vec2, i16vec2);
        i16vec3 expectEXT(i16vec3, i16vec3);
        i16vec4 expectEXT(i16vec4, i16vec4);

        uint16_t expectEXT(uint16_t, uint16_t);
        u16vec2 expectEXT(u16vec2, u16vec2);
        u16vec3 expectEXT(u16vec3, u16vec3);
        u16vec4 expectEXT(u16vec4, u16vec4);

        int64_t expectEXT(int64_t, int64_t);
        i64vec2 expectEXT(i64vec2, i64vec2);
        i64vec3 expectEXT(i64vec3, i64vec3);
        i64vec4 expectEXT(i64vec4, i64vec4);

        uint64_t expectEXT(uint64_t, uint64_t);
        u64vec2 expectEXT(u64vec2, u64vec2);
        u64vec3 expectEXT(u64vec3, u64vec3);
        u64vec4 expectEXT(u64vec4, u64vec4);
      };
    }

    if ((profile == glslang_profile_t.ES_PROFILE && version_ >= 300) ||
      (profile != glslang_profile_t.ES_PROFILE && version_ >= 130)) {
      commonBuiltins ~= q{
        float texture(sampler2DArrayShadow, vec4, float);
        float texture(samplerCubeArrayShadow, vec4, float, float);
        float textureLod(sampler2DArrayShadow, vec4, float);
        float textureLod(samplerCubeShadow, vec4, float);
        float textureLod(samplerCubeArrayShadow, vec4, float, float);
        float textureLodOffset(sampler2DArrayShadow, vec4, float, ivec2);
        float textureOffset(sampler2DArrayShadow, vec4, ivec2, float);
      };
    }

    if (profile != glslang_profile_t.ES_PROFILE && version_ >= 450) {
      stageBuiltins[glslang_stage_t.STAGE_FRAGMENT] ~= derivativesAndControl64bits;
      stageBuiltins[glslang_stage_t.STAGE_FRAGMENT] ~= q{
        float64_t interpolateAtCentroid(float64_t);
        f64vec2 interpolateAtCentroid(f64vec2);
        f64vec3 interpolateAtCentroid(f64vec3);
        f64vec4 interpolateAtCentroid(f64vec4);

        float64_t interpolateAtSample(float64_t, int);
        f64vec2 interpolateAtSample(f64vec2, int);
        f64vec3 interpolateAtSample(f64vec3, int);
        f64vec4 interpolateAtSample(f64vec4, int);

        float64_t interpolateAtOffset(float64_t, f64vec2);
        f64vec2 interpolateAtOffset(f64vec2, f64vec2);
        f64vec3 interpolateAtOffset(f64vec3, f64vec2);
        f64vec4 interpolateAtOffset(f64vec4, f64vec2);
      };
    }

    if ((profile == glslang_profile_t.ES_PROFILE && version_ >= 310) ||
      (profile != glslang_profile_t.ES_PROFILE && version_ >= 140)) {
      commonBuiltins ~= q{
        void assumeEXT(bool);

        bool expectEXT(bool, bool);
        bvec2 expectEXT(bvec2, bvec2);
        bvec3 expectEXT(bvec3, bvec3);
        bvec4 expectEXT(bvec4, bvec4);

        int expectEXT(int, int);
        ivec2 expectEXT(ivec2, ivec2);
        ivec3 expectEXT(ivec3, ivec3);
        ivec4 expectEXT(ivec4, ivec4);

        uint expectEXT(uint, uint);
        uvec2 expectEXT(uvec2, uvec2);
        uvec3 expectEXT(uvec3, uvec3);
        uvec4 expectEXT(uvec4, uvec4);
      };
    }

    if ((profile == glslang_profile_t.ES_PROFILE && version_ >= 310) ||
      (profile != glslang_profile_t.ES_PROFILE && version_ >= 140)) {
      commonBuiltins ~= q{
        vec4 textureWeightedQCOM(sampler2D, vec2, sampler2DArray);
        vec4 textureWeightedQCOM(sampler2D, vec2, sampler1DArray);
        vec4 textureBoxFilterQCOM(sampler2D, vec2, vec2);
        vec4 textureBlockMatchSADQCOM(sampler2D, uvec2, sampler2D, uvec2, uvec2);
        vec4 textureBlockMatchSSDQCOM(sampler2D, uvec2, sampler2D, uvec2, uvec2);

        vec4 textureBlockMatchWindowSSDQCOM(sampler2D, uvec2, sampler2D, uvec2, uvec2);
        vec4 textureBlockMatchWindowSADQCOM(sampler2D, uvec2, sampler2D, uvec2, uvec2);
        vec4 textureBlockMatchGatherSSDQCOM(sampler2D, uvec2, sampler2D, uvec2, uvec2);
        vec4 textureBlockMatchGatherSADQCOM(sampler2D, uvec2, sampler2D, uvec2, uvec2);
      };
    }

    if (spvVersion.vulkan == 0 && IncludeLegacy(version_, profile, spvVersion))
      stageBuiltins[glslang_stage_t.STAGE_VERTEX] ~= q{
        vec4 ftransform();
      };

    Appender!(char[])* s;
    if (version_ == 100)
      s = &stageBuiltins[glslang_stage_t.STAGE_VERTEX];
    else
      s = &commonBuiltins;
    if ((profile == glslang_profile_t.ES_PROFILE && version_ == 100) ||
      (profile == glslang_profile_t.CORE_PROFILE && version_ < 420) ||
      profile == glslang_profile_t.COMPATIBILITY_PROFILE ||
      profile == glslang_profile_t.NO_PROFILE) {
      if (spvVersion.spv == 0) {
        s.put = q{
          vec4 texture2DLod(sampler2D, vec2, float);
          vec4 texture2DProjLod(sampler2D, vec3, float);
          vec4 texture2DProjLod(sampler2D, vec4, float);
          vec4 texture3DLod(sampler3D, vec3, float);
          vec4 texture3DProjLod(sampler3D, vec4, float);
          vec4 textureCubeLod(samplerCube, vec3, float);
        };
      }
    }
    if ((profile == glslang_profile_t.CORE_PROFILE && version_ < 420) ||
      profile == glslang_profile_t.COMPATIBILITY_PROFILE ||
      profile == glslang_profile_t.NO_PROFILE) {
      if (spvVersion.spv == 0) {
        s.put = q{
          vec4 texture1DLod(sampler1D, float, float);
          vec4 texture1DProjLod(sampler1D, vec2, float);
          vec4 texture1DProjLod(sampler1D, vec4, float);
          vec4 shadow1DLod(sampler1DShadow, vec3, float);
          vec4 shadow2DLod(sampler2DShadow, vec3, float);
          vec4 shadow1DProjLod(sampler1DShadow, vec4, float);
          vec4 shadow2DProjLod(sampler2DShadow, vec4, float);

          vec4 texture1DGradARB(sampler1D, float, float, float);
          vec4 texture1DProjGradARB(sampler1D, vec2, float, float);
          vec4 texture1DProjGradARB(sampler1D, vec4, float, float);
          vec4 texture2DGradARB(sampler2D, vec2, vec2, vec2);
          vec4 texture2DProjGradARB(sampler2D, vec3, vec2, vec2);
          vec4 texture2DProjGradARB(sampler2D, vec4, vec2, vec2);
          vec4 texture3DGradARB(sampler3D, vec3, vec3, vec3);
          vec4 texture3DProjGradARB(sampler3D, vec4, vec3, vec3);
          vec4 textureCubeGradARB(samplerCube, vec3, vec3, vec3);
          vec4 shadow1DGradARB(sampler1DShadow, vec3, float, float);
          vec4 shadow1DProjGradARB(sampler1DShadow, vec4, float, float);
          vec4 shadow2DGradARB(sampler2DShadow, vec3, vec2, vec2);
          vec4 shadow2DProjGradARB(sampler2DShadow, vec4, vec2, vec2);
          vec4 texture2DRectGradARB(sampler2DRect, vec2, vec2, vec2);
          vec4 texture2DRectProjGradARB(sampler2DRect, vec3, vec2, vec2);
          vec4 texture2DRectProjGradARB(sampler2DRect, vec4, vec2, vec2);
          vec4 shadow2DRectGradARB(sampler2DRectShadow, vec3, vec2, vec2);
          vec4 shadow2DRectProjGradARB(sampler2DRectShadow, vec4, vec2, vec2);
        };
      }
    }

    if ((profile != glslang_profile_t.ES_PROFILE && version_ >= 150) ||
      (profile == glslang_profile_t.ES_PROFILE && version_ >= 310)) {
      if (profile != glslang_profile_t.ES_PROFILE && version_ >= 150) {
        stageBuiltins[glslang_stage_t.STAGE_GEOMETRY] ~= q{
          void EmitStreamVertex(int);
          void EndStreamPrimitive(int);
        };
      }
      stageBuiltins[glslang_stage_t.STAGE_GEOMETRY] ~= q{
        void EmitVertex();
        void EndPrimitive();
      };
    }

    bool esBarrier = (profile == glslang_profile_t.ES_PROFILE && version_ >= 310);
    if ((profile != glslang_profile_t.ES_PROFILE && version_ >= 150) || esBarrier)
      stageBuiltins[glslang_stage_t.STAGE_TESSCONTROL] ~= q{
        void barrier();
      };
    if ((profile != glslang_profile_t.ES_PROFILE && version_ >= 420) || esBarrier)
      stageBuiltins[glslang_stage_t.STAGE_COMPUTE] ~= q{
        void barrier();
      };
    if ((profile != glslang_profile_t.ES_PROFILE && version_ >= 450) ||
      (profile == glslang_profile_t.ES_PROFILE && version_ >= 320)) {
      stageBuiltins[glslang_stage_t.STAGE_MESH] ~= q{
        void barrier();
      };
      stageBuiltins[glslang_stage_t.STAGE_TASK] ~= q{
        void barrier();
      };
    }
    if ((profile != glslang_profile_t.ES_PROFILE && version_ >= 130) || esBarrier)
      commonBuiltins ~= q{
        void memoryBarrier();
      };
    if ((profile != glslang_profile_t.ES_PROFILE && version_ >= 420) || esBarrier) {
      commonBuiltins ~= q{
        void memoryBarrierBuffer();
      };
      stageBuiltins[glslang_stage_t.STAGE_COMPUTE] ~= q{
        void memoryBarrierShared();
        void groupMemoryBarrier();
      };
    }
    if ((profile != glslang_profile_t.ES_PROFILE && version_ >= 420) || esBarrier) {
      if (spvVersion.vulkan == 0 || spvVersion.vulkanRelaxed) {
        commonBuiltins ~= q{
          void memoryBarrierAtomicCounter();
        };
      }
      commonBuiltins ~= q{
        void memoryBarrierImage();
      };
    }
    if ((profile != glslang_profile_t.ES_PROFILE && version_ >= 450) ||
      (profile == glslang_profile_t.ES_PROFILE && version_ >= 320)) {
      stageBuiltins[glslang_stage_t.STAGE_MESH] ~= q{
        void memoryBarrierShared();
        void groupMemoryBarrier();
      };
      stageBuiltins[glslang_stage_t.STAGE_TASK] ~= q{
        void memoryBarrierShared();
        void groupMemoryBarrier();
      };
    }

    commonBuiltins ~= q{
      void controlBarrier(int, int, int, int);
      void memoryBarrier(int, int, int);
      void debugPrintfEXT();
    };

    if (profile != glslang_profile_t.ES_PROFILE && version_ >= 450) {
      stageBuiltins[glslang_stage_t.STAGE_COMPUTE] ~= q{
        void coopMatLoadNV(out fcoopmatNV m, volatile coherent nontemporal float16_t[] buf, uint element, uint stride, bool colMajor);
        void coopMatLoadNV(out fcoopmatNV m, volatile coherent nontemporal float[] buf, uint element, uint stride, bool colMajor);
        void coopMatLoadNV(out fcoopmatNV m, volatile coherent nontemporal uint8_t[] buf, uint element, uint stride, bool colMajor);
        void coopMatLoadNV(out fcoopmatNV m, volatile coherent nontemporal uint16_t[] buf, uint element, uint stride, bool colMajor);
        void coopMatLoadNV(out fcoopmatNV m, volatile coherent nontemporal uint[] buf, uint element, uint stride, bool colMajor);
        void coopMatLoadNV(out fcoopmatNV m, volatile coherent nontemporal uint64_t[] buf, uint element, uint stride, bool colMajor);
        void coopMatLoadNV(out fcoopmatNV m, volatile coherent nontemporal uvec2[] buf, uint element, uint stride, bool colMajor);
        void coopMatLoadNV(out fcoopmatNV m, volatile coherent nontemporal uvec4[] buf, uint element, uint stride, bool colMajor);

        void coopMatStoreNV(fcoopmatNV m, volatile coherent nontemporal float16_t[] buf, uint element, uint stride, bool colMajor);
        void coopMatStoreNV(fcoopmatNV m, volatile coherent nontemporal float[] buf, uint element, uint stride, bool colMajor);
        void coopMatStoreNV(fcoopmatNV m, volatile coherent nontemporal float64_t[] buf, uint element, uint stride, bool colMajor);
        void coopMatStoreNV(fcoopmatNV m, volatile coherent nontemporal uint8_t[] buf, uint element, uint stride, bool colMajor);
        void coopMatStoreNV(fcoopmatNV m, volatile coherent nontemporal uint16_t[] buf, uint element, uint stride, bool colMajor);
        void coopMatStoreNV(fcoopmatNV m, volatile coherent nontemporal uint[] buf, uint element, uint stride, bool colMajor);
        void coopMatStoreNV(fcoopmatNV m, volatile coherent nontemporal uint64_t[] buf, uint element, uint stride, bool colMajor);
        void coopMatStoreNV(fcoopmatNV m, volatile coherent nontemporal uvec2[] buf, uint element, uint stride, bool colMajor);
        void coopMatStoreNV(fcoopmatNV m, volatile coherent nontemporal uvec4[] buf, uint element, uint stride, bool colMajor);

        fcoopmatNV coopMatMulAddNV(fcoopmatNV A, fcoopmatNV B, fcoopmatNV C);
        void coopMatLoadNV(out icoopmatNV m, volatile coherent nontemporal int8_t[] buf, uint element, uint stride, bool colMajor);
        void coopMatLoadNV(out icoopmatNV m, volatile coherent nontemporal int16_t[] buf, uint element, uint stride, bool colMajor);
        void coopMatLoadNV(out icoopmatNV m, volatile coherent nontemporal int[] buf, uint element, uint stride, bool colMajor);
        void coopMatLoadNV(out icoopmatNV m, volatile coherent nontemporal int64_t[] buf, uint element, uint stride, bool colMajor);
        void coopMatLoadNV(out icoopmatNV m, volatile coherent nontemporal ivec2[] buf, uint element, uint stride, bool colMajor);
        void coopMatLoadNV(out icoopmatNV m, volatile coherent nontemporal ivec4[] buf, uint element, uint stride, bool colMajor);
        void coopMatLoadNV(out icoopmatNV m, volatile coherent nontemporal uint8_t[] buf, uint element, uint stride, bool colMajor);
        void coopMatLoadNV(out icoopmatNV m, volatile coherent nontemporal uint16_t[] buf, uint element, uint stride, bool colMajor);
        void coopMatLoadNV(out icoopmatNV m, volatile coherent nontemporal uint[] buf, uint element, uint stride, bool colMajor);
        void coopMatLoadNV(out icoopmatNV m, volatile coherent nontemporal uint64_t[] buf, uint element, uint stride, bool colMajor);
        void coopMatLoadNV(out icoopmatNV m, volatile coherent nontemporal uvec2[] buf, uint element, uint stride, bool colMajor);
        void coopMatLoadNV(out icoopmatNV m, volatile coherent nontemporal uvec4[] buf, uint element, uint stride, bool colMajor);

        void coopMatLoadNV(out ucoopmatNV m, volatile coherent nontemporal int8_t[] buf, uint element, uint stride, bool colMajor);
        void coopMatLoadNV(out ucoopmatNV m, volatile coherent nontemporal int16_t[] buf, uint element, uint stride, bool colMajor);
        void coopMatLoadNV(out ucoopmatNV m, volatile coherent nontemporal int[] buf, uint element, uint stride, bool colMajor);
        void coopMatLoadNV(out ucoopmatNV m, volatile coherent nontemporal int64_t[] buf, uint element, uint stride, bool colMajor);
        void coopMatLoadNV(out ucoopmatNV m, volatile coherent nontemporal ivec2[] buf, uint element, uint stride, bool colMajor);
        void coopMatLoadNV(out ucoopmatNV m, volatile coherent nontemporal ivec4[] buf, uint element, uint stride, bool colMajor);
        void coopMatLoadNV(out ucoopmatNV m, volatile coherent nontemporal uint8_t[] buf, uint element, uint stride, bool colMajor);
        void coopMatLoadNV(out ucoopmatNV m, volatile coherent nontemporal uint16_t[] buf, uint element, uint stride, bool colMajor);
        void coopMatLoadNV(out ucoopmatNV m, volatile coherent nontemporal uint[] buf, uint element, uint stride, bool colMajor);
        void coopMatLoadNV(out ucoopmatNV m, volatile coherent nontemporal uint64_t[] buf, uint element, uint stride, bool colMajor);
        void coopMatLoadNV(out ucoopmatNV m, volatile coherent nontemporal uvec2[] buf, uint element, uint stride, bool colMajor);
        void coopMatLoadNV(out ucoopmatNV m, volatile coherent nontemporal uvec4[] buf, uint element, uint stride, bool colMajor);

        void coopMatStoreNV(icoopmatNV m, volatile coherent nontemporal int8_t[] buf, uint element, uint stride, bool colMajor);
        void coopMatStoreNV(icoopmatNV m, volatile coherent nontemporal int16_t[] buf, uint element, uint stride, bool colMajor);
        void coopMatStoreNV(icoopmatNV m, volatile coherent nontemporal int[] buf, uint element, uint stride, bool colMajor);
        void coopMatStoreNV(icoopmatNV m, volatile coherent nontemporal int64_t[] buf, uint element, uint stride, bool colMajor);
        void coopMatStoreNV(icoopmatNV m, volatile coherent nontemporal ivec2[] buf, uint element, uint stride, bool colMajor);
        void coopMatStoreNV(icoopmatNV m, volatile coherent nontemporal ivec4[] buf, uint element, uint stride, bool colMajor);
        void coopMatStoreNV(icoopmatNV m, volatile coherent nontemporal uint8_t[] buf, uint element, uint stride, bool colMajor);
        void coopMatStoreNV(icoopmatNV m, volatile coherent nontemporal uint16_t[] buf, uint element, uint stride, bool colMajor);
        void coopMatStoreNV(icoopmatNV m, volatile coherent nontemporal uint[] buf, uint element, uint stride, bool colMajor);
        void coopMatStoreNV(icoopmatNV m, volatile coherent nontemporal uint64_t[] buf, uint element, uint stride, bool colMajor);
        void coopMatStoreNV(icoopmatNV m, volatile coherent nontemporal uvec2[] buf, uint element, uint stride, bool colMajor);
        void coopMatStoreNV(icoopmatNV m, volatile coherent nontemporal uvec4[] buf, uint element, uint stride, bool colMajor);

        void coopMatStoreNV(ucoopmatNV m, volatile coherent nontemporal int8_t[] buf, uint element, uint stride, bool colMajor);
        void coopMatStoreNV(ucoopmatNV m, volatile coherent nontemporal int16_t[] buf, uint element, uint stride, bool colMajor);
        void coopMatStoreNV(ucoopmatNV m, volatile coherent nontemporal int[] buf, uint element, uint stride, bool colMajor);
        void coopMatStoreNV(ucoopmatNV m, volatile coherent nontemporal int64_t[] buf, uint element, uint stride, bool colMajor);
        void coopMatStoreNV(ucoopmatNV m, volatile coherent nontemporal ivec2[] buf, uint element, uint stride, bool colMajor);
        void coopMatStoreNV(ucoopmatNV m, volatile coherent nontemporal ivec4[] buf, uint element, uint stride, bool colMajor);
        void coopMatStoreNV(ucoopmatNV m, volatile coherent nontemporal uint8_t[] buf, uint element, uint stride, bool colMajor);
        void coopMatStoreNV(ucoopmatNV m, volatile coherent nontemporal uint16_t[] buf, uint element, uint stride, bool colMajor);
        void coopMatStoreNV(ucoopmatNV m, volatile coherent nontemporal uint[] buf, uint element, uint stride, bool colMajor);
        void coopMatStoreNV(ucoopmatNV m, volatile coherent nontemporal uint64_t[] buf, uint element, uint stride, bool colMajor);
        void coopMatStoreNV(ucoopmatNV m, volatile coherent nontemporal uvec2[] buf, uint element, uint stride, bool colMajor);
        void coopMatStoreNV(ucoopmatNV m, volatile coherent nontemporal uvec4[] buf, uint element, uint stride, bool colMajor);

        icoopmatNV coopMatMulAddNV(icoopmatNV A, icoopmatNV B, icoopmatNV C);
        ucoopmatNV coopMatMulAddNV(ucoopmatNV A, ucoopmatNV B, ucoopmatNV C);
      };

      Appender!(char[]) cooperativeMatrixFuncs = appender!(char[]);

      {
        enum string[] allTypes = [
          "float", "vec2", "vec4",
          "float16_t", "f16vec2", "f16vec4",
          "bfloat16_t", "bf16vec2", "bf16vec4",
          "floate5m2_t", "fe5m2vec2", "fe5m2vec4",
          "floate4m3_t", "fe4m3vec2", "fe4m3vec4",
          "double", "dvec2", "dvec4",
          "int8_t", "i8vec2", "i8vec4",
          "int16_t", "i16vec2", "i16vec4",
          "int", "ivec2", "ivec4",
          "int64_t", "i64vec2", "i64vec4",
          "uint8_t", "u8vec2", "u8vec4",
          "uint16_t", "u16vec2", "u16vec4",
          "uint", "uvec2", "uvec4",
          "uint64_t", "u64vec2", "u64vec4",
        ];

        foreach (elemTy; ["uint", "uint64_t"]) {
          foreach (t; allTypes) {
            cooperativeMatrixFuncs ~= iq{
              void coopMatLoad(out coopmat m, volatile coherent nontemporal $(t)[] buf, $(elemTy) element, uint stride, int matrixLayout);
              void coopMatStore(coopmat m, volatile coherent nontemporal $(t)[] buf, $(elemTy) element, uint stride, int matrixLayout);
            }.text;
          }
          cooperativeMatrixFuncs ~= iq{
            void coopMatLoadTensorNV(inout coopmat m, volatile coherent nontemporal uint8_t[] buf, $(elemTy) element, tensorLayoutNV t);
            void coopMatLoadTensorNV(inout coopmat m, volatile coherent nontemporal uint8_t[] buf, $(elemTy) element, tensorLayoutNV t, tensorViewNV v);
            void coopMatLoadTensorNV(inout coopmat m, volatile coherent nontemporal uint8_t[] buf, $(elemTy) element, tensorLayoutNV t, __function f);
            void coopMatLoadTensorNV(inout coopmat m, volatile coherent nontemporal uint8_t[] buf, $(elemTy) element, tensorLayoutNV t, tensorViewNV v, __function f);
            void coopMatStoreTensorNV(coopmat m, volatile coherent nontemporal uint8_t[] buf, $(elemTy) element, tensorLayoutNV t);
            void coopMatStoreTensorNV(coopmat m, volatile coherent nontemporal uint8_t[] buf, $(elemTy) element, tensorLayoutNV t, tensorViewNV v);
          }.text;
        }
      }

      cooperativeMatrixFuncs ~= q{
        coopmat coopMatMulAdd(coopmat A, coopmat B, coopmat C);
        coopmat coopMatMulAdd(coopmat A, coopmat B, coopmat C, int matrixOperands);
      };

      commonBuiltins ~= cooperativeMatrixFuncs[];

      commonBuiltins ~= q{
        const int gl_MatrixUseA = 0;
        const int gl_MatrixUseB = 1;
        const int gl_MatrixUseAccumulator = 2;
        const int gl_MatrixOperandsSaturatingAccumulation = 0x10;
        const int gl_CooperativeMatrixLayoutRowMajor = 0;
        const int gl_CooperativeMatrixLayoutColumnMajor = 1;
        const int gl_CooperativeMatrixLayoutRowBlockedInterleavedARM = 4202;
        const int gl_CooperativeMatrixLayoutColumnBlockedInterleavedARM = 4203;

        void coopMatTransposeNV(out coopmat, coopmat);
        void coopMatReduceNV(out coopmat, coopmat, int, __function);
        void coopMatPerElementNV();

        const int gl_CooperativeMatrixReduceRowNV = 0x1;
        const int gl_CooperativeMatrixReduceColumnNV = 0x2;
        const int gl_CooperativeMatrixReduceRowAndColumnNV = 0x3;
        const int gl_CooperativeMatrixReduce2x2NV = 0x4;

        const int gl_CooperativeMatrixClampModeUndefinedNV = 0x0;
        const int gl_CooperativeMatrixClampModeConstantNV = 0x1;
        const int gl_CooperativeMatrixClampModeClampToEdgeNV = 0x2;
        const int gl_CooperativeMatrixClampModeRepeatNV = 0x3;
        const int gl_CooperativeMatrixClampModeMirrorRepeatNV = 0x4;
      };

      {
        Appender!(char[]) coopMatConvFuncs = appender!(char[]);

        enum string[] eltTypes = [
          "uint32_t", "uint", "int32_t", "int", "float32_t", "float", "float16_t"
        ];

        foreach (srcEltTy; eltTypes) {
          foreach (dstEltTy; eltTypes) {
            coopMatConvFuncs ~= iq{
              void bitcastQCOM($(srcEltTy) SrcArr[], $(dstEltTy) DstArr[]);
            }.text;
          }
        }

        foreach (
          eltTy; ["float32_t", "float16_t", "int8_t",
            "uint8_t", "uint32_t", "uint", "int32_t", "int"]
        ) {
          coopMatConvFuncs ~= iq{
            void vectorToCoopmatQCOM($(eltTy) SrcVec[], coopmat CM);
            void coopmatToVectorQCOM(coopmat CM, $(eltTy) Dstvec[]);
          }.text;
        }

        foreach (eltTy; ["uint32_t", "uint", "int32_t", "int",
          "float32_t", "float", "float16_t"]
        ) {
          coopMatConvFuncs ~= iq{
            void extractSubArrayQCOM($(eltTy) arr[], uint index, $(eltTy) subarr[]);
          }.text;
        }

        commonBuiltins ~= coopMatConvFuncs[];
      }

      commonBuiltins ~= q{
        tensorLayoutNV createTensorLayoutNV(uint Dim);
        tensorLayoutNV createTensorLayoutNV(uint Dim, uint Mode);

        tensorLayoutNV setTensorLayoutBlockSizeNV(tensorLayoutNV t, uint blockSize0);
        tensorLayoutNV setTensorLayoutBlockSizeNV(tensorLayoutNV t, uint blockSize0, uint blockSize1);
        tensorLayoutNV setTensorLayoutBlockSizeNV(tensorLayoutNV t, uint blockSize0, uint blockSize1, uint blockSize2);
        tensorLayoutNV setTensorLayoutBlockSizeNV(tensorLayoutNV t, uint blockSize0, uint blockSize1, uint blockSize2, uint blockSize3);
        tensorLayoutNV setTensorLayoutBlockSizeNV(tensorLayoutNV t, uint blockSize0, uint blockSize1, uint blockSize2, uint blockSize3, uint blockSize4);

        tensorLayoutNV setTensorLayoutDimensionNV(tensorLayoutNV t, uint dim0);
        tensorLayoutNV setTensorLayoutDimensionNV(tensorLayoutNV t, uint dim0, uint dim1);
        tensorLayoutNV setTensorLayoutDimensionNV(tensorLayoutNV t, uint dim0, uint dim1, uint dim2);
        tensorLayoutNV setTensorLayoutDimensionNV(tensorLayoutNV t, uint dim0, uint dim1, uint dim2, uint dim3);
        tensorLayoutNV setTensorLayoutDimensionNV(tensorLayoutNV t, uint dim0, uint dim1, uint dim2, uint dim3, uint dim4);

        tensorLayoutNV setTensorLayoutStrideNV(tensorLayoutNV t, uint stride0);
        tensorLayoutNV setTensorLayoutStrideNV(tensorLayoutNV t, uint stride0, uint stride1);
        tensorLayoutNV setTensorLayoutStrideNV(tensorLayoutNV t, uint stride0, uint stride1, uint stride2);
        tensorLayoutNV setTensorLayoutStrideNV(tensorLayoutNV t, uint stride0, uint stride1, uint stride2, uint stride3);
        tensorLayoutNV setTensorLayoutStrideNV(tensorLayoutNV t, uint stride0, uint stride1, uint stride2, uint stride3, uint stride4);

        tensorLayoutNV sliceTensorLayoutNV(tensorLayoutNV t, uint offset0, uint span0);
        tensorLayoutNV sliceTensorLayoutNV(tensorLayoutNV t, uint offset0, uint span0, uint offset1, uint span1);
        tensorLayoutNV sliceTensorLayoutNV(tensorLayoutNV t, uint offset0, uint span0, uint offset1, uint span1, uint offset2, uint span2);
        tensorLayoutNV sliceTensorLayoutNV(tensorLayoutNV t, uint offset0, uint span0, uint offset1, uint span1, uint offset2, uint span2, uint offset3, uint span3);
        tensorLayoutNV sliceTensorLayoutNV(tensorLayoutNV t, uint offset0, uint span0, uint offset1, uint span1, uint offset2, uint span2, uint offset3, uint span3, uint offset4, uint span4);

        tensorLayoutNV setTensorLayoutClampValueNV(tensorLayoutNV t, uint value);

        tensorViewNV createTensorViewNV(uint Dim);
        tensorViewNV createTensorViewNV(uint Dim, bool HasDimensions);
        tensorViewNV createTensorViewNV(uint Dim, bool HasDimensions, uint p0);
        tensorViewNV createTensorViewNV(uint Dim, bool HasDimensions, uint p0, uint p1);
        tensorViewNV createTensorViewNV(uint Dim, bool HasDimensions, uint p0, uint p1, uint p2);
        tensorViewNV createTensorViewNV(uint Dim, bool HasDimensions, uint p0, uint p1, uint p2, uint p3);
        tensorViewNV createTensorViewNV(uint Dim, bool HasDimensions, uint p0, uint p1, uint p2, uint p3, uint p4);

        tensorViewNV setTensorViewDimensionsNV(tensorViewNV v, uint dim0);
        tensorViewNV setTensorViewDimensionsNV(tensorViewNV v, uint dim0, uint dim1);
        tensorViewNV setTensorViewDimensionsNV(tensorViewNV v, uint dim0, uint dim1, uint dim2);
        tensorViewNV setTensorViewDimensionsNV(tensorViewNV v, uint dim0, uint dim1, uint dim2, uint dim3);
        tensorViewNV setTensorViewDimensionsNV(tensorViewNV v, uint dim0, uint dim1, uint dim2, uint dim3, uint dim4);

        tensorViewNV setTensorViewStrideNV(tensorViewNV v, uint stride0);
        tensorViewNV setTensorViewStrideNV(tensorViewNV v, uint stride0, uint stride1);
        tensorViewNV setTensorViewStrideNV(tensorViewNV v, uint stride0, uint stride1, uint stride2);
        tensorViewNV setTensorViewStrideNV(tensorViewNV v, uint stride0, uint stride1, uint stride2, uint stride3);
        tensorViewNV setTensorViewStrideNV(tensorViewNV v, uint stride0, uint stride1, uint stride2, uint stride3, uint stride4);

        tensorViewNV setTensorViewClipNV(tensorViewNV v, uint clipRowOffset, uint clipRowSpan, uint clipColOffset, uint clipColSpan);
      };

      enum string[] tensorDataTypesARM = [
        "bool",
        "int8_t", "int16_t", "int32_t", "int64_t",
        "uint8_t", "uint16_t", "uint32_t", "uint64_t",
        "float16_t", "float32_t", "float64_t"
      ];
      Appender!(char[]) ostream = appender!(char[]);
      foreach (t; tensorDataTypesARM) {
        ostream ~= iq{
          void tensorReadARM(readonly tensorARM t, uint coords[], out $(t)  data, uint tensorOperands = 0U, ...);
          void tensorWriteARM(writeonly tensorARM t, uint coords[], $(t) data, uint tensorOperands = 0U, ...);
          void tensorReadARM(readonly tensorARM t, uint coords[], $(t) data[], uint tensorOperands = 0U, ...);
          void tensorWriteARM(writeonly tensorARM t, uint coords[], $(t) data[], uint tensorOperands = 0U, ...);
        }.text;
      }
      ostream ~= q{
        uint tensorSizeARM(readonly writeonly tensorARM t, uint dim);
      };
      commonBuiltins ~= ostream[];
    }

    if (profile != glslang_profile_t.ES_PROFILE && version_ >= 450) {
      enum string[] basicTypes = [
        "int8_t",
        "int16_t",
        "int32_t",
        "int64_t",
        "uint8_t",
        "uint16_t",
        "uint32_t",
        "uint64_t",
        "float16_t",
        "float32_t",
        "float64_t"
      ];
      enum string[] coopVecOffsetTypes = [
        "uint",
        "uint64_t"
      ];
      foreach (offsetTy; coopVecOffsetTypes) {
        foreach (basicTy; basicTypes) {
          commonBuiltins ~=
            "void coopVecMatMulNV(out coopvecNV result, coopvecNV v, int inputInterpretation, "
              ~ i"$(basicTy)[] matrix, $(offsetTy) matrixOffset, int matrixInterpretation, ".text
              ~ "uint M, uint K, int matrixLayout, bool transpose, uint matrixStride);\n";
          
          foreach (biasBasicType; basicTypes) {
            commonBuiltins ~= "void coopVecMatMulAddNV(out coopvecNV result, coopvecNV v, int inputInterpretation, "
              ~ i"$(basicTy)[] matrix, $(offsetTy) matrixOffset, int matrixInterpretation, ".text
              ~ i"$(biasBasicType)[] bias, $(offsetTy) biasOffset, int biasInterpretation, ".text
              ~ "uint M, uint K, int matrixLayout, bool transpose, uint matrixStride);\n";
          }

          commonBuiltins ~= "void coopVecOuterProductAccumulateNV(coopvecNV v1, coopvecNV v2, "
            ~ i"$(basicTy)[] buf, $(offsetTy) offset, uint stride, int matrixLayout, int matrixInterpretation);\n".text;

          commonBuiltins ~= "void coopVecReduceSumAccumulateNV(coopvecNV v, "
            ~ i"$(basicTy)[] buf, $(offsetTy) offset);\n".text;
        }
      }
      commonBuiltins ~= q{
        coopvecNV fma(coopvecNV, coopvecNV, coopvecNV);
        coopvecNV min(coopvecNV, coopvecNV);
        coopvecNV max(coopvecNV, coopvecNV);
        coopvecNV step(coopvecNV, coopvecNV);
        coopvecNV exp(coopvecNV);            
        coopvecNV log(coopvecNV);            
        coopvecNV tanh(coopvecNV);            
        coopvecNV atan(coopvecNV);            
        coopvecNV clamp(coopvecNV, coopvecNV, coopvecNV);
      };

      enum string[] scalarAndVectorTypes = [
        "int8_t",
        "int16_t",
        "int32_t",
        "int64_t",
        "uint8_t",
        "uint16_t",
        "uint32_t",
        "uint64_t",
        "float16_t",
        "float32_t",
        "float64_t",
        "i8vec2",
        "i16vec2",
        "i32vec2",
        "i64vec2",
        "u8vec2",
        "u16vec2",
        "u32vec2",
        "u64vec2",
        "f16vec2",
        "f32vec2",
        "f64vec2",
        "i8vec3",
        "i16vec3",
        "i32vec3",
        "i64vec3",
        "u8vec3",
        "u16vec3",
        "u32vec3",
        "u64vec3",
        "f16vec3",
        "f32vec3",
        "f64vec3",
        "i8vec4",
        "i16vec4",
        "i32vec4",
        "i64vec4",
        "u8vec4",
        "u16vec4",
        "u32vec4",
        "u64vec4",
        "f16vec4",
        "f32vec4",
        "f64vec4"
      ];

      foreach (offsetTy; coopVecOffsetTypes) {
        foreach (scalarAndVectorTy; scalarAndVectorTypes) {
          
        }
      }
    }
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
  Versioning[] versioning;
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

enum ARBCompatibility = true;

bool IncludeLegacy(int version_, glslang_profile_t profile, in SpvVersion spvVersion) {
  return profile != glslang_profile_t.ES_PROFILE && (version_ <= 130 ||
    (spvVersion.spv == 0 && version_ == 140 && ARBCompatibility) ||
    profile == glslang_profile_t.COMPATIBILITY_PROFILE);
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

void AddTabledBuiltin(ref Appender!(char[]) decls, in BuiltInFunction func) {
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
