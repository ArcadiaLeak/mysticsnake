import freetype.config.public_macros;

alias FT_Pos = long;

ulong FT_IMAGE_TAG(alias _x1, alias _x2, alias _x3, alias _x4)() {
  return (FT_STATIC_BYTE_CAST!(ulong, _x1) << 24) |
    (FT_STATIC_BYTE_CAST!(ulong, _x2) << 16) |
    (FT_STATIC_BYTE_CAST!(ulong, _x3) << 8) |
    FT_STATIC_BYTE_CAST!(ulong, _x4);
}

enum FT_Glyph_Format : ulong {
  FT_GLYPH_FORMAT_NONE = FT_IMAGE_TAG!(0, 0, 0, 0),
  
  FT_GLYPH_FORMAT_COMPOSITE = FT_IMAGE_TAG!('c', 'o', 'm', 'p'),
  FT_GLYPH_FORMAT_BITMAP = FT_IMAGE_TAG!('b', 'i', 't', 's'),
  FT_GLYPH_FORMAT_OUTLINE = FT_IMAGE_TAG!('o', 'u', 't', 'l'),
  FT_GLYPH_FORMAT_PLOTTER = FT_IMAGE_TAG!('p', 'l', 'o', 't'),
  FT_GLYPH_FORMAT_SVG = FT_IMAGE_TAG!('S', 'V', 'G', ' ')
}