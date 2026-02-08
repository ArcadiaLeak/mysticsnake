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

   void declareNterm(string[] tags ...) {
    foreach (tag; tags) {
      symbolBuf ~= Symbol(
        tag: tag,
        iContent: symContentBuf.length
      );
      symContentBuf ~= SymContent(
        number: nnterms++,
        kind: SymKind.Nterm,
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
  gramMetaWip.declareToken("BF16VEC2", "BF16VEC3", "BF16VEC4");
  gramMetaWip.declareToken("FE5M2VEC2", "FE5M2VEC3", "FE5M2VEC4");
  gramMetaWip.declareToken("FE4M3VEC2", "FE4M3VEC3", "FE4M3VEC4");
  gramMetaWip.declareToken("F16VEC2", "F16VEC3", "F16VEC4", "F16MAT2", "F16MAT3", "F16MAT4");
  gramMetaWip.declareToken("F32VEC2", "F32VEC3", "F32VEC4", "F32MAT2", "F32MAT3", "F32MAT4");
  gramMetaWip.declareToken("F64VEC2", "F64VEC3", "F64VEC4", "F64MAT2", "F64MAT3", "F64MAT4");
  gramMetaWip.declareToken("DMAT2X2", "DMAT2X3", "DMAT2X4");
  gramMetaWip.declareToken("DMAT3X2", "DMAT3X3", "DMAT3X4");
  gramMetaWip.declareToken("DMAT4X2", "DMAT4X3", "DMAT4X4");
  gramMetaWip.declareToken("F16MAT2X2", "F16MAT2X3", "F16MAT2X4");
  gramMetaWip.declareToken("F16MAT3X2", "F16MAT3X3", "F16MAT3X4");
  gramMetaWip.declareToken("F16MAT4X2", "F16MAT4X3", "F16MAT4X4");
  gramMetaWip.declareToken("F32MAT2X2", "F32MAT2X3", "F32MAT2X4");
  gramMetaWip.declareToken("F32MAT3X2", "F32MAT3X3", "F32MAT3X4");
  gramMetaWip.declareToken("F32MAT4X2", "F32MAT4X3", "F32MAT4X4");
  gramMetaWip.declareToken("F64MAT2X2", "F64MAT2X3", "F64MAT2X4");
  gramMetaWip.declareToken("F64MAT3X2", "F64MAT3X3", "F64MAT3X4");
  gramMetaWip.declareToken("F64MAT4X2", "F64MAT4X3", "F64MAT4X4");
  gramMetaWip.declareToken("ATOMIC_UINT", "ACCSTRUCTNV", "ACCSTRUCTEXT", "RAYQUERYEXT");
  gramMetaWip.declareToken("FCOOPMATNV", "ICOOPMATNV", "UCOOPMATNV");
  gramMetaWip.declareToken("COOPMAT", "COOPVECNV", "HITOBJECTNV", "HITOBJECTATTRNV", "HITOBJECTEXT", "HITOBJECTATTREXT");
  gramMetaWip.declareToken("TENSORLAYOUTNV", "TENSORVIEWNV", "TENSORARM");
  gramMetaWip.declareToken("SAMPLERCUBEARRAY", "SAMPLERCUBEARRAYSHADOW", "ISAMPLERCUBEARRAY", "USAMPLERCUBEARRAY");
  gramMetaWip.declareToken("SAMPLER1D", "SAMPLER1DARRAY", "SAMPLER1DARRAYSHADOW", "ISAMPLER1D", "SAMPLER1DSHADOW");
  gramMetaWip.declareToken("SAMPLER2DRECT", "SAMPLER2DRECTSHADOW", "ISAMPLER2DRECT", "USAMPLER2DRECT");
  gramMetaWip.declareToken("SAMPLERBUFFER", "ISAMPLERBUFFER", "USAMPLERBUFFER");
  gramMetaWip.declareToken("SAMPLER2DMS", "ISAMPLER2DMS", "USAMPLER2DMS");
  gramMetaWip.declareToken("SAMPLER2DMSARRAY", "ISAMPLER2DMSARRAY", "USAMPLER2DMSARRAY");
  gramMetaWip.declareToken("SAMPLEREXTERNALOES", "SAMPLEREXTERNAL2DY2YEXT");
  gramMetaWip.declareToken("ISAMPLER1DARRAY", "USAMPLER1D", "USAMPLER1DARRAY");
  gramMetaWip.declareToken("F16SAMPLER1D", "F16SAMPLER2D", "F16SAMPLER3D", "F16SAMPLER2DRECT", "F16SAMPLERCUBE");
  gramMetaWip.declareToken("F16SAMPLER1DARRAY", "F16SAMPLER2DARRAY", "F16SAMPLERCUBEARRAY");
  gramMetaWip.declareToken("F16SAMPLERBUFFER", "F16SAMPLER2DMS", "F16SAMPLER2DMSARRAY");
  gramMetaWip.declareToken("F16SAMPLER1DSHADOW", "F16SAMPLER2DSHADOW", "F16SAMPLER1DARRAYSHADOW", "F16SAMPLER2DARRAYSHADOW");
  gramMetaWip.declareToken("F16SAMPLER2DRECTSHADOW", "F16SAMPLERCUBESHADOW", "F16SAMPLERCUBEARRAYSHADOW");
  gramMetaWip.declareToken("IMAGE1D", "IIMAGE1D", "UIMAGE1D", "IMAGE2D", "IIMAGE2D");
  gramMetaWip.declareToken("UIMAGE2D", "IMAGE3D", "IIMAGE3D", "UIMAGE3D");
  gramMetaWip.declareToken("IMAGE2DRECT", "IIMAGE2DRECT", "UIMAGE2DRECT");
  gramMetaWip.declareToken("IMAGECUBE", "IIMAGECUBE", "UIMAGECUBE");
  gramMetaWip.declareToken("IMAGEBUFFER", "IIMAGEBUFFER", "UIMAGEBUFFER");
  gramMetaWip.declareToken("IMAGE1DARRAY", "IIMAGE1DARRAY", "UIMAGE1DARRAY");
  gramMetaWip.declareToken("IMAGE2DARRAY", "IIMAGE2DARRAY", "UIMAGE2DARRAY");
  gramMetaWip.declareToken("IMAGECUBEARRAY", "IIMAGECUBEARRAY", "UIMAGECUBEARRAY");
  gramMetaWip.declareToken("IMAGE2DMS", "IIMAGE2DMS", "UIMAGE2DMS");
  gramMetaWip.declareToken("IMAGE2DMSARRAY", "IIMAGE2DMSARRAY", "UIMAGE2DMSARRAY");
  gramMetaWip.declareToken("F16IMAGE1D", "F16IMAGE2D", "F16IMAGE3D", "F16IMAGE2DRECT");
  gramMetaWip.declareToken("F16IMAGECUBE", "F16IMAGE1DARRAY", "F16IMAGE2DARRAY", "F16IMAGECUBEARRAY");
  gramMetaWip.declareToken("F16IMAGEBUFFER", "F16IMAGE2DMS", "F16IMAGE2DMSARRAY");
  gramMetaWip.declareToken("I64IMAGE1D", "U64IMAGE1D");
  gramMetaWip.declareToken("I64IMAGE2D", "U64IMAGE2D");
  gramMetaWip.declareToken("I64IMAGE3D", "U64IMAGE3D");
  gramMetaWip.declareToken("I64IMAGE2DRECT", "U64IMAGE2DRECT");
  gramMetaWip.declareToken("I64IMAGECUBE", "U64IMAGECUBE");
  gramMetaWip.declareToken("I64IMAGEBUFFER", "U64IMAGEBUFFER");
  gramMetaWip.declareToken("I64IMAGE1DARRAY", "U64IMAGE1DARRAY");
  gramMetaWip.declareToken("I64IMAGE2DARRAY", "U64IMAGE2DARRAY");
  gramMetaWip.declareToken("I64IMAGECUBEARRAY", "U64IMAGECUBEARRAY");
  gramMetaWip.declareToken("I64IMAGE2DMS", "U64IMAGE2DMS");
  gramMetaWip.declareToken("I64IMAGE2DMSARRAY", "U64IMAGE2DMSARRAY");
  gramMetaWip.declareToken("TEXTURECUBEARRAY", "ITEXTURECUBEARRAY", "UTEXTURECUBEARRAY");
  gramMetaWip.declareToken("TEXTURE1D", "ITEXTURE1D", "UTEXTURE1D");
  gramMetaWip.declareToken("TEXTURE1DARRAY", "ITEXTURE1DARRAY", "UTEXTURE1DARRAY");
  gramMetaWip.declareToken("TEXTURE2DRECT", "ITEXTURE2DRECT", "UTEXTURE2DRECT");
  gramMetaWip.declareToken("TEXTUREBUFFER", "ITEXTUREBUFFER", "UTEXTUREBUFFER");
  gramMetaWip.declareToken("TEXTURE2DMS", "ITEXTURE2DMS", "UTEXTURE2DMS");
  gramMetaWip.declareToken("TEXTURE2DMSARRAY", "ITEXTURE2DMSARRAY", "UTEXTURE2DMSARRAY");
  gramMetaWip.declareToken("F16TEXTURE1D", "F16TEXTURE2D", "F16TEXTURE3D", "F16TEXTURE2DRECT", "F16TEXTURECUBE");
  gramMetaWip.declareToken("F16TEXTURE1DARRAY", "F16TEXTURE2DARRAY", "F16TEXTURECUBEARRAY");
  gramMetaWip.declareToken("F16TEXTUREBUFFER", "F16TEXTURE2DMS", "F16TEXTURE2DMSARRAY");
  gramMetaWip.declareToken("SUBPASSINPUT", "SUBPASSINPUTMS", "ISUBPASSINPUT", "ISUBPASSINPUTMS", "USUBPASSINPUT", "USUBPASSINPUTMS");
  gramMetaWip.declareToken("F16SUBPASSINPUT", "F16SUBPASSINPUTMS");
  gramMetaWip.declareToken("SPIRV_INSTRUCTION", "SPIRV_EXECUTION_MODE", "SPIRV_EXECUTION_MODE_ID");
  gramMetaWip.declareToken("SPIRV_DECORATE", "SPIRV_DECORATE_ID", "SPIRV_DECORATE_STRING");
  gramMetaWip.declareToken("SPIRV_TYPE", "SPIRV_STORAGE_CLASS", "SPIRV_BY_REFERENCE", "SPIRV_LITERAL");
  gramMetaWip.declareToken("ATTACHMENTEXT", "IATTACHMENTEXT", "UATTACHMENTEXT");
  gramMetaWip.declareToken("LEFT_OP", "RIGHT_OP");
  gramMetaWip.declareToken("INC_OP", "DEC_OP", "LE_OP", "GE_OP", "EQ_OP", "NE_OP");
  gramMetaWip.declareToken("AND_OP", "OR_OP", "XOR_OP", "MUL_ASSIGN", "DIV_ASSIGN", "ADD_ASSIGN");
  gramMetaWip.declareToken("MOD_ASSIGN", "LEFT_ASSIGN", "RIGHT_ASSIGN", "AND_ASSIGN", "XOR_ASSIGN", "OR_ASSIGN", "SUB_ASSIGN");
  gramMetaWip.declareToken("STRING_LITERAL");
  gramMetaWip.declareToken("LEFT_PAREN", "RIGHT_PAREN", "LEFT_BRACKET", "RIGHT_BRACKET", "LEFT_BRACE", "RIGHT_BRACE", "DOT");
  gramMetaWip.declareToken("COMMA", "COLON", "EQUAL", "SEMICOLON", "BANG", "DASH", "TILDE", "PLUS", "STAR", "SLASH", "PERCENT");
  gramMetaWip.declareToken("LEFT_ANGLE", "RIGHT_ANGLE", "VERTICAL_BAR", "CARET", "AMPERSAND", "QUESTION");
  gramMetaWip.declareToken("INVARIANT");
  gramMetaWip.declareToken("HIGH_PRECISION", "MEDIUM_PRECISION", "LOW_PRECISION", "PRECISION");
  gramMetaWip.declareToken("PACKED", "RESOURCE", "SUPERP");
  gramMetaWip.declareToken("FLOATCONSTANT", "INTCONSTANT", "UINTCONSTANT", "BOOLCONSTANT");
  gramMetaWip.declareToken("IDENTIFIER", "TYPE_NAME");
  gramMetaWip.declareToken("CENTROID", "IN", "OUT", "INOUT");
  gramMetaWip.declareToken("STRUCT", "VOID", "WHILE");
  gramMetaWip.declareToken("BREAK", "CONTINUE", "DO", "ELSE", "FOR", "IF", "DISCARD", "RETURN", "SWITCH", "CASE", "DEFAULT");
  gramMetaWip.declareToken("TERMINATE_INVOCATION", "TERMINATE_RAY", "IGNORE_INTERSECTION");
  gramMetaWip.declareToken("UNIFORM", "SHARED", "BUFFER", "TILEIMAGEEXT");
  gramMetaWip.declareToken("FLAT", "SMOOTH", "LAYOUT");
  gramMetaWip.declareToken("DOUBLECONSTANT", "INT16CONSTANT", "UINT16CONSTANT", "FLOAT16CONSTANT", "INT32CONSTANT", "UINT32CONSTANT");
  gramMetaWip.declareToken("INT64CONSTANT", "UINT64CONSTANT");
  gramMetaWip.declareToken("SUBROUTINE", "DEMOTE", "FUNCTION");
  gramMetaWip.declareToken("PAYLOADNV", "PAYLOADINNV", "HITATTRNV", "CALLDATANV", "CALLDATAINNV");
  gramMetaWip.declareToken("PAYLOADEXT", "PAYLOADINEXT", "HITATTREXT", "CALLDATAEXT", "CALLDATAINEXT");
  gramMetaWip.declareToken("PATCH", "SAMPLE", "NONUNIFORM");
  gramMetaWip.declareToken("COHERENT", "VOLATILE", "RESTRICT", "READONLY", "WRITEONLY", "NONTEMPORAL", "DEVICECOHERENT", "QUEUEFAMILYCOHERENT", "WORKGROUPCOHERENT");
  gramMetaWip.declareToken("SUBGROUPCOHERENT", "NONPRIVATE", "SHADERCALLCOHERENT");
  gramMetaWip.declareToken("NOPERSPECTIVE", "EXPLICITINTERPAMD", "PERVERTEXEXT", "PERVERTEXNV", "PERPRIMITIVENV", "PERVIEWNV", "PERTASKNV", "PERPRIMITIVEEXT", "TASKPAYLOADWORKGROUPEXT");
  gramMetaWip.declareToken("PRECISE");

  gramMetaWip.declareNterm("variable_identifier");
  gramMetaWip.declareNterm("primary_expression", "postfix_expression", "integer_expression");
  gramMetaWip.declareNterm("function_call", "function_call_or_method", "function_call_generic");
  gramMetaWip.declareNterm("function_call_header_no_parameters", "function_call_header_with_parameters");
  gramMetaWip.declareNterm("function_call_header", "function_identifier");
  gramMetaWip.declareNterm("unary_expression", "unary_operator");
  gramMetaWip.declareNterm("multiplicative_expression", "additive_expression", "shift_expression");
  gramMetaWip.declareNterm("relational_expression", "equality_expression", "and_expression");
  gramMetaWip.declareNterm("exclusive_or_expression", "inclusive_or_expression", "logical_and_expression");
  gramMetaWip.declareNterm("logical_xor_expression", "logical_or_expression", "conditional_expression");
  gramMetaWip.declareNterm("assignment_expression", "assignment_operator");
  gramMetaWip.declareNterm("expression", "constant_expression", "declaration");
  gramMetaWip.declareNterm("block_structure", "identifier_list", "function_prototype", "function_declarator");
  gramMetaWip.declareNterm("function_header_with_parameters", "function_header");
  gramMetaWip.declareNterm("parameter_declarator", "parameter_declaration", "parameter_type_specifier");
  gramMetaWip.declareNterm("init_declarator_list", "single_declaration", "fully_specified_type");
  gramMetaWip.declareNterm("invariant_qualifier", "interpolation_qualifier");
  gramMetaWip.declareNterm("layout_qualifier", "layout_qualifier_id_list", "layout_qualifier_id");
  gramMetaWip.declareNterm("precise_qualifier", "type_qualifier", "single_type_qualifier", "storage_qualifier");
  gramMetaWip.declareNterm("non_uniform_qualifier");
  gramMetaWip.declareNterm("type_name_list", "type_specifier", "array_specifier");
  gramMetaWip.declareNterm("type_parameter_specifier_opt", "type_parameter_specifier", "type_parameter_specifier_list");
  gramMetaWip.declareNterm("type_specifier_nonarray", "precision_qualifier");
  gramMetaWip.declareNterm("struct_specifier", "struct_declaration_list", "struct_declaration");
  gramMetaWip.declareNterm("struct_declarator_list", "struct_declarator");
  gramMetaWip.declareNterm("initializer", "initializer_list");
  gramMetaWip.declareNterm("declaration_statement", "statement", "simple_statement", "demote_statement");
  gramMetaWip.declareNterm("compound_statement", "statement_no_new_scope", "statement_scoped", "compound_statement_no_new_scope");
  gramMetaWip.declareNterm("statement_list", "expression_statement", "selection_statement");
  gramMetaWip.declareNterm("selection_statement_nonattributed", "selection_rest_statement");
  gramMetaWip.declareNterm("condition");
  gramMetaWip.declareNterm("switch_statement", "switch_statement_nonattributed", "switch_statement_list", "case_label");
  gramMetaWip.declareNterm("iteration_statement", "iteration_statement_nonattributed");
  gramMetaWip.declareNterm("for_init_statement", "conditionopt", "for_rest_statement", "jump_statement");
  gramMetaWip.declareNterm("translation_unit", "external_declaration");
  gramMetaWip.declareNterm("function_definition", "attribute", "attribute_list", "single_attribute");
  gramMetaWip.declareNterm("spirv_requirements_list", "spirv_requirements_parameter");
  gramMetaWip.declareNterm("spirv_extension_list", "spirv_capability_list");
  gramMetaWip.declareNterm("spirv_execution_mode_qualifier", "spirv_execution_mode_parameter_list");
  gramMetaWip.declareNterm("spirv_execution_mode_parameter", "spirv_execution_mode_id_parameter_list");
  gramMetaWip.declareNterm("spirv_storage_class_qualifier", "spirv_decorate_qualifier");
  gramMetaWip.declareNterm("spirv_decorate_parameter_list", "spirv_decorate_parameter");
  gramMetaWip.declareNterm("spirv_decorate_id_parameter_list", "spirv_decorate_id_parameter", "spirv_decorate_string_parameter_list");
  gramMetaWip.declareNterm("spirv_type_specifier", "spirv_type_parameter_list", "spirv_type_parameter");
  gramMetaWip.declareNterm("spirv_instruction_qualifier", "spirv_instruction_qualifier_list", "spirv_instruction_qualifier_id");

  return gramMetaWip;
}

void main() {
  import std.stdio;

  writeln(parserMeta);
}