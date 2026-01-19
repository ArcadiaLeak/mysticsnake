struct FT_MemoryRec {
  void* user;
  FT_Alloc_Func alloc;
  FT_Free_Func free;
  FT_Realloc_Func realloc;
}

struct FT_StreamRec {
  char* base;
  ulong size;
  ulong pos;

  FT_StreamDesc descriptor;
  FT_StreamDesc pathname;
  FT_Stream_IoFunc read;
  FT_Stream_CloseFunc close;

  FT_Memory memory;
  char* cursor;
  char* limit;
}

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

alias FT_Memory = FT_MemoryRec*;

alias FT_Stream = FT_StreamRec*;
