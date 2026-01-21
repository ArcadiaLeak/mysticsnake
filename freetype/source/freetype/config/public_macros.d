module freetype.config.public_macros;

import std.conv;

string FT_STATIC_BYTE_CAST(string type, string var) {
  return text(iq{cast($(type)) cast(char) ($(var))});
}
