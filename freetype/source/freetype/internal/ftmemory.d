module freetype.internal.ftmemory;

import freetype;

import std.conv;

string FT_FREE(string ptr) =>
  FT_MEM_FREE(ptr);

string FT_MEM_FREE(string ptr) {
  string debugInnerRet = FT_DEBUG_INNER(
    iq{ft_mem_free( memory, ($(ptr)) )}.text
  );

  return iq{
    $(FT_BEGIN_STMNT)
      $(debugInnerRet);
      ($(ptr)) = null;
    $(FT_END_STMNT)
  }.text;
}

string FT_DEBUG_INNER(string exp) => iq{ ($(exp)) }.text;
