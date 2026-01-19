public import freetype.config;
public import freetype.internal;
public import freetype.ftimage;
public import freetype.ftmodapi;
public import freetype.ftrender;
public import freetype.ftsystem;
public import freetype.fttypes;

FT_UInt32 FT_ENC_TAG(alias a, alias b, alias c, alias d)() {
  return (FT_STATIC_BYTE_CAST!(FT_UInt32, a) << 24) |
    (FT_STATIC_BYTE_CAST!(FT_UInt32, b) << 16) |
    (FT_STATIC_BYTE_CAST!(FT_UInt32, c) << 8) |
    FT_STATIC_BYTE_CAST!(FT_UInt32, d);
}

enum FT_Encoding : FT_UInt32 {
  FT_ENCODING_NONE = FT_ENC_TAG!(0, 0, 0, 0),

  FT_ENCODING_MS_SYMBOL = FT_ENC_TAG!('s', 'y', 'm', 'b'),
  FT_ENCODING_UNICODE = FT_ENC_TAG!('u', 'n', 'i', 'c'),

  FT_ENCODING_SJIS = FT_ENC_TAG!('s', 'j', 'i', 's'),
  FT_ENCODING_PRC = FT_ENC_TAG!('g', 'b', ' ', ' '),
  FT_ENCODING_BIG5 = FT_ENC_TAG!('b', 'i', 'g', '5'),
  FT_ENCODING_WANSUNG = FT_ENC_TAG!('w', 'a', 'n', 's'),
  FT_ENCODING_JOHAB = FT_ENC_TAG!('j', 'o', 'h', 'a'),

  FT_ENCODING_GB2312 = FT_ENCODING_PRC,
  FT_ENCODING_MS_SJIS = FT_ENCODING_SJIS,
  FT_ENCODING_MS_GB2312 = FT_ENCODING_PRC,
  FT_ENCODING_MS_BIG5 = FT_ENCODING_BIG5,
  FT_ENCODING_MS_WANSUNG = FT_ENCODING_WANSUNG,
  FT_ENCODING_MS_JOHAB = FT_ENCODING_JOHAB,

  FT_ENCODING_ADOBE_STANDARD = FT_ENC_TAG!('A', 'D', 'O', 'B'),
  FT_ENCODING_ADOBE_EXPERT = FT_ENC_TAG!('A', 'D', 'B', 'E'),
  FT_ENCODING_ADOBE_CUSTOM = FT_ENC_TAG!('A', 'D', 'B', 'C'),
  FT_ENCODING_ADOBE_LATIN_1 = FT_ENC_TAG!('l', 'a', 't', '1'),

  FT_ENCODING_OLD_LATIN_2 = FT_ENC_TAG!('l', 'a', 't', '2'),

  FT_ENCODING_APPLE_ROMAN = FT_ENC_TAG!('a', 'r', 'm', 'n')
}

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

struct FT_GlyphSlotRec {
  FT_Library library;
  FT_Face face;
  FT_GlyphSlot next;
  FT_UInt glyph_index;
  FT_Generic generic;

  FT_Glyph_Metrics metrics;
  FT_Fixed linearHoriAdvance;
  FT_Fixed linearVertAdvance;
  FT_Vector advance;

  FT_Glyph_Format format;

  FT_Bitmap bitmap;
  FT_Int bitmap_left;
  FT_Int bitmap_top;

  FT_Outline outline;

  FT_UInt num_subglyphs;
  FT_SubGlyph subglyphs;

  void* control_data;
  long control_len;

  FT_Pos lsb_delta;
  FT_Pos rsb_delta;

  void* other;
  
  FT_Slot_Internal internal;
}

struct FT_FaceRec {
  FT_Long num_faces;
  FT_Long face_index;

  FT_Long face_flags;
  FT_Long style_flags;

  FT_Long num_glyphs;

  FT_String* family_name;
  FT_String* style_name;

  FT_Int num_fixed_sizes;
  FT_Bitmap_Size* available_sizes;

  FT_Int num_charmaps;
  FT_CharMap* charmaps;

  FT_Generic generic;

  FT_BBox bbox;

  FT_UShort units_per_EM;
  FT_Short ascender;
  FT_Short descender;
  FT_Short height;

  FT_Short max_advance_width;
  FT_Short max_advance_height;

  FT_Short underline_position;
  FT_Short underline_thickness;

  FT_GlyphSlot glyph;
  FT_Size size;
  FT_CharMap charmap;

  FT_Driver driver;
  FT_Memory memory;
  FT_Stream stream;

  FT_ListRec sizes_list;

  FT_Generic autohint;
  void* extensions;

  FT_Face_Internal internal;
}

struct FT_CharMapRec {
  FT_Face face;
  FT_Encoding encoding;
  FT_UShort platform_id;
  FT_UShort encoding_id;
}

alias FT_Library = FT_LibraryRec*;

alias FT_Module = FT_ModuleRec*;

alias FT_Renderer = FT_RendererRec*;

alias FT_GlyphSlot = FT_GlyphSlotRec*;

alias FT_Slot_Internal = FT_Slot_InternalRec*;

alias FT_SubGlyph = FT_SubGlyphRec*;

alias FT_CharMap = FT_CharMapRec*;

alias FT_Face = FT_FaceRec*;

alias FT_Raster = void*;
