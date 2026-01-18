import freetype;
import freetype.config.ftoption;
import freetype.ftmodapi;
import freetype.ftsystem;
import freetype.fttypes;

struct FT_LibraryRec {
  FT_Memory memory;

  FT_Int version_major;
  FT_Int version_minor;
  FT_Int version_patch;

  FT_UInt num_modules;
  FT_Module[FT_MAX_MODULES] modules;

  FT_ListRec renderers;
  // FT_Renderer cur_renderer;
  FT_Module auto_hinter;


}

struct FT_ModuleRec {
  const FT_Module_Class* clazz;
  
}