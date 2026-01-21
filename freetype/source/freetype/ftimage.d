module freetype.ftimage;

import freetype;

import std.conv;

string FT_IMAGE_TAG(
  string _x1, string _x2, string _x3, string _x4
) => iq{(
  ($(FT_STATIC_BYTE_CAST(q{ulong}, _x1)) << 24) |
  ($(FT_STATIC_BYTE_CAST(q{ulong}, _x2)) << 16) |
  ($(FT_STATIC_BYTE_CAST(q{ulong}, _x3)) <<  8) |
   $(FT_STATIC_BYTE_CAST(q{ulong}, _x4))
)}.text;

enum FT_Glyph_Format : ulong {
  FT_GLYPH_FORMAT_NONE = mixin(FT_IMAGE_TAG(q{0}, q{0}, q{0}, q{0})),

  FT_GLYPH_FORMAT_COMPOSITE = mixin(FT_IMAGE_TAG(q{'c'}, q{'o'}, q{'m'}, q{'p'})),
  FT_GLYPH_FORMAT_BITMAP = mixin(FT_IMAGE_TAG(q{'b'}, q{'i'}, q{'t'}, q{'s'})),
  FT_GLYPH_FORMAT_OUTLINE = mixin(FT_IMAGE_TAG(q{'o'}, q{'u'}, q{'t'}, q{'l'})),
  FT_GLYPH_FORMAT_PLOTTER = mixin(FT_IMAGE_TAG(q{'p'}, q{'l'}, q{'o'}, q{'t'})),
  FT_GLYPH_FORMAT_SVG = mixin(FT_IMAGE_TAG(q{'S'}, q{'V'}, q{'G'}, q{' '}))
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

alias FT_SpanFunc = void function(
  int y,
  int count,
  FT_Span* spans,
  void* user
);

struct FT_Span {
  short x;
  ushort len;
  char coverage;
}

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

struct FT_Raster_Params {
  FT_Bitmap* target;
  void* source;
  int flags;
  FT_SpanFunc gray_spans;
  size_t black_spans;
  size_t bit_test;
  size_t bit_set;
  void* user;
  FT_BBox clip_box;
}
