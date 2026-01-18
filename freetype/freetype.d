import freetype.ftimage;
import freetype.fttypes;

struct FT_Glyph_Metrics {
  FT_Pos width;
  FT_Pos height;

  FT_Pos horiBearingX;
  FT_Pos horiBearingY;
  FT_Pos horiAdvance;
  
  FT_Pos vertBearingX;
  FT_Pos vertBearingY;
  FT_Pos vertAdvance;
}

struct FT_Bitmap_Size {
  FT_Short height;
  FT_Short width;

  FT_Pos size;

  FT_Pos x_ppem;
  FT_Pos y_ppem;
}