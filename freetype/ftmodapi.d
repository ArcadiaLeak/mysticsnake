module freetype.ftmodapi;

import freetype;
import freetype.fttypes;

alias FT_Module_Interface = FT_Pointer;

alias FT_Module_Constructor = FT_Error function(FT_Module modul);

alias FT_Module_Destructor = FT_Error function(FT_Module modul);

alias FT_Module_Requester = FT_Module_Interface function(
  FT_Module modul,
  const(char*) name
);

struct FT_Module_Class {
  FT_Module_Constructor module_init;
  FT_Module_Destructor module_done;
  FT_Module_Requester get_interface;
}