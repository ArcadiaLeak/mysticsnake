module bison.glslgram.unary_expression;

import bison;

private void declrule(string tags ...) {
  foreach (tag; tags) {
    grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
    grammar_current_rule_symbol_append(symbol_get(tag));
    grammar_current_rule_end();
  }
}

void type_specifier_nonarray() {
  declare_sym(symbol_get("type_specifier_nonarray"), symbol_class_t.nterm_sym);

  declrule("VOID", "FLOAT", "INT", "UINT", "BOOL");
  declrule("VEC2", "VEC3", "VEC4", "BVEC2", "BVEC3", "BVEC4");
  declrule("IVEC2", "IVEC3", "IVEC4", "UVEC2", "UVEC3", "UVEC4");
  declrule("MAT2", "MAT3", "MAT4", "MAT2X2", "MAT2X3", "MAT2X4");
  declrule("MAT3X2", "MAT3X3", "MAT3X4", "MAT4X2", "MAT4X3", "MAT4X4");
  declrule("DOUBLE", "BFLOAT16_T", "FLOATE5M2_T", "FLOATE4M3_T");
  declrule("FLOAT16_T", "FLOAT32_T", "FLOAT64_T", "INT8_T", "UINT8_T");
  declrule("INT16_T", "UINT16_T", "INT32_T", "UINT32_T", "INT64_T", "UINT64_T");
  declrule("DVEC2", "DVEC3", "DVEC4", "BF16VEC2", "BF16VEC3", "BF16VEC4");
  declrule("DVEC2", "DVEC3", "DVEC4", "BF16VEC2", "BF16VEC3", "BF16VEC4");
  declrule("FE5M2VEC2", "FE5M2VEC3", "FE5M2VEC4", "FE4M3VEC2", "FE4M3VEC3", "FE4M3VEC4");
  declrule("F16VEC2", "F16VEC3", "F16VEC4", "F32VEC2", "F32VEC3", "F32VEC4");
  declrule("F64VEC2", "F64VEC3", "F64VEC4", "I8VEC2", "I8VEC3", "I8VEC4");
  declrule("I16VEC2", "I16VEC3", "I16VEC4", "I32VEC2", "I32VEC3", "I32VEC4");
  declrule("I64VEC2", "I64VEC3", "I64VEC4", "U8VEC2", "U8VEC3", "U8VEC4");
  declrule("U16VEC2", "U16VEC3", "U16VEC4", "U32VEC2", "U32VEC3", "U32VEC4");
  declrule("U64VEC2", "U64VEC3", "U64VEC4", "DMAT2", "DMAT3", "DMAT4");
  declrule("DMAT2X2", "DMAT2X3", "DMAT2X4", "DMAT3X2", "DMAT3X3", "DMAT3X4");
  declrule("DMAT4X2", "DMAT4X3", "DMAT4X4", "F16MAT2", "F16MAT3", "F16MAT4");
  declrule("F16MAT2X2", "F16MAT2X3", "F16MAT2X4", "F16MAT3X2", "F16MAT3X3", "F16MAT3X4");
  declrule("F16MAT4X2", "F16MAT4X3", "F16MAT4X4", "F32MAT2", "F32MAT3", "F32MAT4");
  declrule("F32MAT2X2", "F32MAT2X3", "F32MAT2X4", "F32MAT3X2", "F32MAT3X3", "F32MAT3X4");
  declrule("F32MAT4X2", "F32MAT4X3", "F32MAT4X4", "F64MAT2", "F64MAT3", "F64MAT4");
  declrule("F64MAT2X2", "F64MAT2X3", "F64MAT2X4", "F64MAT3X2", "F64MAT3X3", "F64MAT3X4");
  declrule("F64MAT4X2", "F64MAT4X3", "F64MAT4X4");
  declrule("ACCSTRUCTNV", "ACCSTRUCTEXT", "RAYQUERYEXT", "ATOMIC_UINT");
  declrule("SAMPLER1D", "SAMPLER2D", "SAMPLER3D", "SAMPLERCUBE", "SAMPLER2DSHADOW", "SAMPLERCUBESHADOW");
  declrule("SAMPLER2DARRAY", "SAMPLER2DARRAYSHADOW", "SAMPLER1DSHADOW", "SAMPLER1DARRAY", "SAMPLER1DARRAYSHADOW", "SAMPLERCUBEARRAY");
  declrule("SAMPLERCUBEARRAYSHADOW", "F16SAMPLER1D", "F16SAMPLER2D", "F16SAMPLER3D", "F16SAMPLERCUBE", "F16SAMPLER1DSHADOW");
  declrule("F16SAMPLER2DSHADOW", "F16SAMPLERCUBESHADOW", "F16SAMPLER1DARRAY", "F16SAMPLER2DARRAY", "F16SAMPLER1DARRAYSHADOW", "F16SAMPLER2DARRAYSHADOW");
  declrule("F16SAMPLERCUBEARRAY", "F16SAMPLERCUBEARRAYSHADOW", "ISAMPLER1D", "ISAMPLER2D", "ISAMPLER3D", "ISAMPLERCUBE");
  declrule("ISAMPLER2DARRAY", "USAMPLER2D", "USAMPLER3D", "USAMPLERCUBE", "ISAMPLER1DARRAY", "ISAMPLERCUBEARRAY");

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("USAMPLER1D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("USAMPLER1DARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("USAMPLERCUBEARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("TEXTURECUBEARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("ITEXTURECUBEARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UTEXTURECUBEARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("USAMPLER2DARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("TEXTURE2D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("TEXTURE3D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("TEXTURE2DARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("TEXTURECUBE"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("ITEXTURE2D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("ITEXTURE3D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("ITEXTURECUBE"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("ITEXTURE2DARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UTEXTURE2D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UTEXTURE3D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UTEXTURECUBE"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UTEXTURE2DARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("SAMPLER"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("SAMPLERSHADOW"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("SAMPLER2DRECT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("SAMPLER2DRECTSHADOW"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16SAMPLER2DRECT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16SAMPLER2DRECTSHADOW"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("ISAMPLER2DRECT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("USAMPLER2DRECT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("SAMPLERBUFFER"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16SAMPLERBUFFER"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("ISAMPLERBUFFER"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("USAMPLERBUFFER"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("SAMPLER2DMS"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16SAMPLER2DMS"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("ISAMPLER2DMS"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("USAMPLER2DMS"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("SAMPLER2DMSARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16SAMPLER2DMSARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("ISAMPLER2DMSARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("USAMPLER2DMSARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("TEXTURE1D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16TEXTURE1D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16TEXTURE2D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16TEXTURE3D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16TEXTURECUBE"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("TEXTURE1DARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16TEXTURE1DARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16TEXTURE2DARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16TEXTURECUBEARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("ITEXTURE1D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("ITEXTURE1DARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UTEXTURE1D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UTEXTURE1DARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("TEXTURE2DRECT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16TEXTURE2DRECT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("ITEXTURE2DRECT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UTEXTURE2DRECT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("TEXTUREBUFFER"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16TEXTUREBUFFER"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("ITEXTUREBUFFER"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UTEXTUREBUFFER"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("TEXTURE2DMS"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16TEXTURE2DMS"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("ITEXTURE2DMS"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UTEXTURE2DMS"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("TEXTURE2DMSARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16TEXTURE2DMSARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("ITEXTURE2DMSARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UTEXTURE2DMSARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("IMAGE1D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16IMAGE1D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("IIMAGE1D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UIMAGE1D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("IMAGE2D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16IMAGE2D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("IIMAGE2D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UIMAGE2D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("IMAGE3D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16IMAGE3D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("IIMAGE3D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UIMAGE3D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("IMAGE2DRECT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16IMAGE2DRECT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("IIMAGE2DRECT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UIMAGE2DRECT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("IMAGECUBE"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16IMAGECUBE"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("IIMAGECUBE"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UIMAGECUBE"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("IMAGEBUFFER"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16IMAGEBUFFER"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("IIMAGEBUFFER"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UIMAGEBUFFER"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("IMAGE1DARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16IMAGE1DARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("IIMAGE1DARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UIMAGE1DARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("IMAGE2DARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16IMAGE2DARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("IIMAGE2DARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UIMAGE2DARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("IMAGECUBEARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16IMAGECUBEARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("IIMAGECUBEARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UIMAGECUBEARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("IMAGE2DMS"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16IMAGE2DMS"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("IIMAGE2DMS"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UIMAGE2DMS"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("IMAGE2DMSARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16IMAGE2DMSARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("IIMAGE2DMSARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UIMAGE2DMSARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("I64IMAGE1D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("U64IMAGE1D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("I64IMAGE2D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("U64IMAGE2D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("I64IMAGE3D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("U64IMAGE3D"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("I64IMAGE2DRECT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("U64IMAGE2DRECT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("I64IMAGECUBE"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("U64IMAGECUBE"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("I64IMAGEBUFFER"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("U64IMAGEBUFFER"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("I64IMAGE1DARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("U64IMAGE1DARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("I64IMAGE2DARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("U64IMAGE2DARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("I64IMAGECUBEARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("U64IMAGECUBEARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("I64IMAGE2DMS"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("U64IMAGE2DMS"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("I64IMAGE2DMSARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("U64IMAGE2DMSARRAY"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("SAMPLEREXTERNALOES"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("SAMPLEREXTERNAL2DY2YEXT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("ATTACHMENTEXT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("IATTACHMENTEXT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UATTACHMENTEXT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("SUBPASSINPUT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("SUBPASSINPUTMS"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16SUBPASSINPUT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("F16SUBPASSINPUTMS"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("ISUBPASSINPUT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("ISUBPASSINPUTMS"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("USUBPASSINPUT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("USUBPASSINPUTMS"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("FCOOPMATNV"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("ICOOPMATNV"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("UCOOPMATNV"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("COOPMAT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("TENSORLAYOUTNV"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("TENSORVIEWNV"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("FUNCTION"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("COOPVECNV"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("TENSORARM"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("spirv_type_specifier"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("HITOBJECTNV"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("HITOBJECTEXT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("struct_specifier"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("type_specifier_nonarray"));
  grammar_current_rule_symbol_append(symbol_get("TYPE_NAME"));
  grammar_current_rule_end();
}
