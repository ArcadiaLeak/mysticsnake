module freetype.tttables;

import freetype;

struct TT_PCLT {
  FT_Fixed Version;
  FT_ULong FontNumber;
  FT_UShort Pitch;
  FT_UShort xHeight;
  FT_UShort Style;
  FT_UShort TypeFamily;
  FT_UShort CapHeight;
  FT_UShort SymbolSet;
  FT_Char[16] TypeFace;
  FT_Char[8] CharacterComponent;
  FT_Char[6] FileName;
  FT_Char StrokeWeight;
  FT_Char WidthType;
  FT_Byte SerifStyle;
  FT_Byte Reserved;
}
