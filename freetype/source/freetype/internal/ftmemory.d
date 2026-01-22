module freetype.internal.ftmemory;

import freetype;

import std.conv;

string FT_FREE(string ptr) => FT_MEM_FREE(ptr);
string FT_DEBUG_INNER(string exp) => iq{ ($(exp)) }.text;

string FT_MEM_FREE(string ptr) {
  return iq{
    $(FT_BEGIN_STMNT)
      $(FT_DEBUG_INNER(
        iq{ft_mem_free( memory, ($(ptr)) )}.text
      ));
      ($(ptr)) = null;
    $(FT_END_STMNT)
  }.text;
}
