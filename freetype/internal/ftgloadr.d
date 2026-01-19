import freetype;

struct FT_SubGlyphRec {
  FT_Int index;
  FT_UShort flags;
  FT_Int arg1;
  FT_Int arg2;
  FT_Matrix transform;
}
