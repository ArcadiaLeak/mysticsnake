import freetype;

alias FT_Renderer_RenderFunc = FT_Error function(
  FT_Renderer renderer,
  FT_GlyphSlot slot,
  FT_Render_Mode mode,
  FT_Vector* origin
);

alias FT_Renderer_TransformFunc = FT_Error function(
  FT_Renderer renderer,
  FT_GlyphSlot slot,
  FT_Matrix* matrix,
  FT_Vector* delta
);

alias FT_Renderer_GetCBoxFunc = void function(
  FT_Renderer renderer,
  FT_GlyphSlot slot,
  FT_BBox* cbox
);

alias FT_Renderer_SetModeFunc = FT_Error function(
  FT_Renderer renderer,
  FT_ULong mode_tag,
  FT_Pointer mode_ptr
);

struct FT_Renderer_Class {
  FT_Module_Class root;

  FT_Glyph_Format glyph_format;

}