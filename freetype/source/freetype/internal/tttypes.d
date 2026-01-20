module freetype.internal.tttypes;

import freetype;

struct TT_GlyphZoneRec {
  FT_UShort n_points;
  FT_UShort n_contours;

  FT_Vector* org;
  FT_Vector* cur;
  FT_Vector* orus;

  FT_Byte* tags;
  FT_UShort* contours;

  FT_UShort first_point;
}

alias TT_Interpreter = FT_Error function(
  void* exec_context
);

alias TT_ExecContext = TT_ExecContextRec*;

alias TT_GlyphZone = TT_GlyphZoneRec*;

alias TT_Size = TT_SizeRec*;
