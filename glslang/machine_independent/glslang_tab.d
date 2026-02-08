module glslang.machine_independent.glslang_tab;

enum ParserMeta parserMeta = buildParserMeta();

struct Symbol {
  string tag;

  int iAlias = -1;
  bool isAlias;

  size_t iContent;
}

enum SymKind {
  Token,
  Nterm
}

struct SymContent {
  int number;
  SymKind kind;
  size_t iSymbol;
}

struct ParserMeta {
  int ntokens;
  int nnterms;

  size_t iAcceptSymbol;
  size_t iErrToken;
  size_t iUndefToken;
  size_t iEofToken;

  Symbol[] symbolBuf;
  SymContent[] symContentBuf;
}

ParserMeta buildParserMeta() {
  ParserMeta parserMetaWip;

  GramMeta gramMeta = buildGramMeta();
  parserMetaWip.ntokens = gramMeta.ntokens;
  parserMetaWip.nnterms = gramMeta.nnterms;

  parserMetaWip.iAcceptSymbol = gramMeta.iAcceptSymbol;
  parserMetaWip.iErrToken = gramMeta.iErrToken;
  parserMetaWip.iUndefToken = gramMeta.iUndefToken;
  parserMetaWip.iEofToken = gramMeta.iEofToken;
  
  parserMetaWip.symbolBuf = gramMeta.symbolBuf;
  parserMetaWip.symContentBuf = gramMeta.symContentBuf;

  return parserMetaWip;
}

struct GramMeta {
  int ntokens;
  int nnterms;

  size_t iAcceptSymbol;
  size_t iErrToken;
  size_t iUndefToken;
  size_t iEofToken;

  Symbol[] symbolBuf;
  SymContent[] symContentBuf;

  void declareToken(string[] tags ...) {
    foreach (tag; tags) {
      symbolBuf ~= Symbol(
        tag: tag,
        iContent: symContentBuf.length
      );
      symContentBuf ~= SymContent(
        number: ntokens++,
        kind: SymKind.Token,
        iSymbol: symbolBuf.length - 1
      );
    }
  }
}

GramMeta buildGramMeta() {
  import std.range.primitives;

  GramMeta gramMetaWip;

  gramMetaWip.symbolBuf ~= Symbol(
    tag: "$accept",
    iContent: gramMetaWip.symContentBuf.length
  );
  gramMetaWip.symContentBuf ~= SymContent(
    number: gramMetaWip.nnterms++,
    kind: SymKind.Nterm,
    iSymbol: gramMetaWip.symbolBuf.length - 1
  );
  gramMetaWip.iAcceptSymbol = gramMetaWip.symbolBuf.length - 1;

  gramMetaWip.symbolBuf ~= Symbol(
    tag: "YYerror",
    iContent: gramMetaWip.symContentBuf.length,
    iAlias: cast(int) gramMetaWip.symbolBuf.length + 1
  );
  gramMetaWip.symContentBuf ~= SymContent(
    number: gramMetaWip.ntokens++,
    kind: SymKind.Token,
    iSymbol: gramMetaWip.symbolBuf.length
  );
  gramMetaWip.iErrToken = gramMetaWip.symbolBuf.length - 1;
  gramMetaWip.symbolBuf ~= Symbol(
    tag: "error",
    iContent: gramMetaWip.symContentBuf.length - 1,
    iAlias: cast(int) gramMetaWip.symbolBuf.length - 1,
    isAlias: true
  );

  gramMetaWip.symbolBuf ~= Symbol(
    tag: "YYUNDEF",
    iContent: gramMetaWip.symContentBuf.length,
    iAlias: cast(int) gramMetaWip.symbolBuf.length + 1
  );
  gramMetaWip.symContentBuf ~= SymContent(
    number: gramMetaWip.ntokens++,
    kind: SymKind.Token,
    iSymbol: gramMetaWip.symbolBuf.length
  );
  gramMetaWip.iUndefToken = gramMetaWip.symbolBuf.length - 1;
  gramMetaWip.symbolBuf ~= Symbol(
    tag: "$undefined",
    iContent: gramMetaWip.symContentBuf.length - 1,
    iAlias: cast(int) gramMetaWip.symbolBuf.length - 1,
    isAlias: true
  );

  gramMetaWip.symbolBuf ~= Symbol(
    tag: "YYEOF",
    iContent: gramMetaWip.symContentBuf.length,
    iAlias: cast(int) gramMetaWip.symbolBuf.length + 1
  );
  gramMetaWip.symContentBuf ~= SymContent(
    number: gramMetaWip.ntokens++,
    kind: SymKind.Token,
    iSymbol: gramMetaWip.symbolBuf.length
  );
  gramMetaWip.iEofToken = gramMetaWip.symbolBuf.length - 1;
  gramMetaWip.symbolBuf ~= Symbol(
    tag: "$end",
    iContent: gramMetaWip.symContentBuf.length - 1,
    iAlias: cast(int) gramMetaWip.symbolBuf.length - 1,
    isAlias: true
  );

  gramMetaWip.declareToken("CONST", "BOOL", "INT", "UINT", "FLOAT");
  gramMetaWip.declareToken("BVEC2", "BVEC3", "BVEC4");
  gramMetaWip.declareToken("IVEC2", "IVEC3", "IVEC4");
  gramMetaWip.declareToken("UVEC2", "UVEC3", "UVEC4");
  gramMetaWip.declareToken("VEC2", "VEC3", "VEC4");
  gramMetaWip.declareToken("MAT2", "MAT3", "MAT4");
  gramMetaWip.declareToken("MAT2X2", "MAT2X3", "MAT2X4");
  gramMetaWip.declareToken("MAT3X2", "MAT3X3", "MAT3X4");
  gramMetaWip.declareToken("MAT4X2", "MAT4X3", "MAT4X4");
  gramMetaWip.declareToken("SAMPLER2D", "SAMPLER3D", "SAMPLERCUBE", "SAMPLER2DSHADOW");
  gramMetaWip.declareToken("SAMPLERCUBESHADOW", "SAMPLER2DARRAY");
  gramMetaWip.declareToken("SAMPLER2DARRAYSHADOW", "ISAMPLER2D", "ISAMPLER3D", "ISAMPLERCUBE");
  gramMetaWip.declareToken("ISAMPLER2DARRAY", "USAMPLER2D", "USAMPLER3D");
  gramMetaWip.declareToken("USAMPLERCUBE", "USAMPLER2DARRAY");
  gramMetaWip.declareToken("SAMPLER", "SAMPLERSHADOW");
  gramMetaWip.declareToken("TEXTURE2D", "TEXTURE3D", "TEXTURECUBE", "TEXTURE2DARRAY");
  gramMetaWip.declareToken("ITEXTURE2D", "ITEXTURE3D", "ITEXTURECUBE", "ITEXTURE2DARRAY");
  gramMetaWip.declareToken("UTEXTURE2D", "UTEXTURE3D", "UTEXTURECUBE", "UTEXTURE2DARRAY");
  gramMetaWip.declareToken("ATTRIBUTE", "VARYING");
  gramMetaWip.declareToken("FLOATE5M2_T", "FLOATE4M3_T", "BFLOAT16_T", "FLOAT16_T", "FLOAT32_T", "DOUBLE", "FLOAT64_T");
  gramMetaWip.declareToken("INT64_T", "UINT64_T", "INT32_T", "UINT32_T", "INT16_T", "UINT16_T", "INT8_T", "UINT8_T");
  gramMetaWip.declareToken("I64VEC2", "I64VEC3", "I64VEC4");
  gramMetaWip.declareToken("U64VEC2", "U64VEC3", "U64VEC4");
  gramMetaWip.declareToken("I32VEC2", "I32VEC3", "I32VEC4");
  gramMetaWip.declareToken("U32VEC2", "U32VEC3", "U32VEC4");
  gramMetaWip.declareToken("I16VEC2", "I16VEC3", "I16VEC4");
  gramMetaWip.declareToken("U16VEC2", "U16VEC3", "U16VEC4");
  gramMetaWip.declareToken("I8VEC2", "I8VEC3", "I8VEC4");
  gramMetaWip.declareToken("U8VEC2", "U8VEC3", "U8VEC4");
  gramMetaWip.declareToken("DVEC2", "DVEC3", "DVEC4", "DMAT2", "DMAT3", "DMAT4");

  return gramMetaWip;
}

void main() {
  import std.stdio;

  writeln(parserMeta);
}