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

struct TT_FaceRec {
    FT_FaceRec root;

    TTC_HeaderRec ttc_header;

    FT_ULong format_tag;
    FT_UShort num_tables;
    TT_Table dir_tables;

    TT_Header header;
    TT_HoriHeader horizontal;

    TT_MaxProfile max_profile;

    FT_Bool vertical_info;
    TT_VertHeader vertical;

    FT_UShort num_names;
    TT_NameTableRec name_table;

    TT_OS2 os2;
    TT_Postscript postscript;

    FT_Byte* cmap_table;
    FT_ULong cmap_size;

    TT_Loader_GotoTableFunc goto_table;

    TT_Loader_StartGlyphFunc access_glyph_frame;
    TT_Loader_EndGlyphFunc forget_glyph_frame;
    TT_Loader_ReadGlyphFunc read_glyph_header;
    TT_Loader_ReadGlyphFunc read_simple_glyph;
    TT_Loader_ReadGlyphFunc read_composite_glyph;

    void* sfnt;

    void* psnames;

  static if (TT_CONFIG_OPTION_GX_VAR_SUPPORT) {
    void* mm;

    void* tt_var;

    void* face_var;
  }

    void* psaux;

    TT_GaspRec gasp;

    TT_PCLT pclt;

    FT_ULong num_sbit_scales;
    TT_SBit_Scale sbit_scales;

    TT_Post_NamesRec postscript_names;

    FT_Palette_Data palette_data;
    FT_UShort palette_index;
    FT_Color* palette;
    FT_Bool have_foreground_color;
    FT_Color foreground_color;

    FT_ULong font_program_size;
    FT_Byte* font_program;

    FT_ULong cvt_program_size;
    FT_Byte* cvt_program;

    FT_ULong cvt_size;
    FT_Int32* cvt;

    FT_Generic extra;

    char* postscript_name;

    FT_ULong glyph_len;
    FT_ULong glyph_offset;

    FT_Bool is_cff2;

  static if (TT_CONFIG_OPTION_GX_VAR_SUPPORT) {
    FT_Bool doblend;
    GX_Blend blend;

    FT_UInt32 variation_support;

    char* var_postscript_prefix;
    FT_UInt var_postscript_prefix_len;

    FT_UInt var_default_named_instance;

    char* non_var_style_name;
  }

  
}

alias TT_Interpreter = FT_Error function(
  void* exec_context
);

alias TT_ExecContext = TT_ExecContextRec*;

alias TT_GlyphZone = TT_GlyphZoneRec*;

alias TT_Size = TT_SizeRec*;
