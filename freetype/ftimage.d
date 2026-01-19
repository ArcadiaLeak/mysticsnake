import freetype;

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

alias FT_Pos = long;

alias FT_Raster_NewFunc = int function(
  void* memory,
  FT_Raster* raster
);

alias FT_Raster_DoneFunc = void function(
  FT_Raster raster
);

alias FT_Raster_ResetFunc = void function(
  FT_Raster raster,
  char* pool_base,
  ulong pool_size
);

alias FT_Raster_SetModeFunc = int function(
  FT_Raster raster,
  ulong mode,
  void* args
);

alias FT_Raster_RenderFunc = int function(
  FT_Raster raster,
  FT_Raster_Params* params
);

alias FT_Raster_Render_Func = FT_Raster_RenderFunc;

struct FT_Vector {
  FT_Pos x;
  FT_Pos y;
}

struct FT_BBox {
  FT_Pos xMin, yMin;
  FT_Pos xMax, yMax;
}

struct FT_Raster_Funcs {
  FT_Glyph_Format glyph_format;

  FT_Raster_NewFunc raster_new;
  FT_Raster_ResetFunc raster_reset;
  FT_Raster_SetModeFunc raster_set_mode;
  FT_Raster_RenderFunc raster_render;
  FT_Raster_DoneFunc raster_done;
}

struct FT_Outline {
  ushort n_contours;
  ushort n_points;

  FT_Vector* points;
  char* tags;
  ushort* contours;

  int flags;
}

struct FT_Bitmap {
  uint rows;
  uint width;
  int pitch;
  ubyte* buffer;
  ushort num_grays;
  ubyte pixel_mode;
  ubyte palette_mode;
  void* palette;
}
