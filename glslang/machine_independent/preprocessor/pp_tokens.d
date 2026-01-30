module glslang.machine_independent.preprocessor.pp_tokens;

enum EFixedAtoms {
  PpAtomMaxSingle = 127,

  PpAtomBadToken,

  PPAtomAddAssign,
  PPAtomSubAssign,
  PPAtomMulAssign,
  PPAtomDivAssign,
  PPAtomModAssign,

  PpAtomRight,
  PpAtomLeft,

  PpAtomRightAssign,
  PpAtomLeftAssign,
  PpAtomAndAssign,
  PpAtomOrAssign,
  PpAtomXorAssign,

  PpAtomAnd,
  PpAtomOr,
  PpAtomXor,

  PpAtomEQ,
  PpAtomNE,
  PpAtomGE,
  PpAtomLE,

  PpAtomDecrement,
  PpAtomIncrement,

  PpAtomColonColon,

  PpAtomPaste,

  PpAtomConstInt,
  PpAtomConstUint,
  PpAtomConstInt64,
  PpAtomConstUint64,
  PpAtomConstInt16,
  PpAtomConstUint16,
  PpAtomConstFloat,
  PpAtomConstDouble,
  PpAtomConstFloat16,
  PpAtomConstString,

  PpAtomIdentifier,

  PpAtomDefine,
  PpAtomUndef,

  PpAtomIf,
  PpAtomIfdef,
  PpAtomIfndef,
  PpAtomElse,
  PpAtomElif,
  PpAtomEndif,

  PpAtomLine,
  PpAtomPragma,
  PpAtomError,

  PpAtomVersion,
  PpAtomCore,
  PpAtomCompatibility,
  PpAtomEs,

  PpAtomExtension,

  PpAtomLineMacro,
  PpAtomFileMacro,
  PpAtomVersionMacro,

  PpAtomInclude,

  PpAtomLast,
}
