alias FT_String = char;

alias FT_Short = short;

alias FT_Int = int;

alias FT_UInt = uint;

alias FT_Long = long;

alias FT_ULong = ulong;

alias FT_F2Dot14 = short;

alias FT_26Dot6 = long;

alias FT_Fixed = long;

alias FT_Error = int;

alias FT_Pointer = void*;

struct FT_ListRec {
  FT_ListNode head;
  FT_ListNode tail;
}

struct FT_ListNodeRec {
  FT_ListNode prev;
  FT_ListNode next;
  void* data;
}

alias FT_List = FT_ListRec*;

alias FT_ListNode = FT_ListNodeRec*;