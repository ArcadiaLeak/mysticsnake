T FT_STATIC_BYTE_CAST(T, alias var)() {
  return cast(T) (cast(char) var);
}