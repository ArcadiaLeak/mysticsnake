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
    auto forEachFunction(ref string decls, const(BuiltInFunction[]) functions) {
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
