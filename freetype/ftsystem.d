alias FT_Memory = FT_MemoryRec*;

alias FT_Alloc_Func = void* function(
  FT_Memory memory,
  long size
);

alias FT_Free_Func = void function(
  FT_Memory memory,
  void* block
);

alias FT_Realloc_Func = void* function(
  FT_Memory memory,
  long cur_size,
  long new_size,
  void* block
);

struct FT_MemoryRec {
  void* user;
  FT_Alloc_Func alloc;
  FT_Free_Func free;
  FT_Realloc_Func realloc;
}
