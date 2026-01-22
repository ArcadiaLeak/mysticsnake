module harfbuzz.hb_blob;

import harfbuzz;

enum hb_memory_mode_t {
  HB_MEMORY_MODE_DUPLICATE,
  HB_MEMORY_MODE_READONLY,
  HB_MEMORY_MODE_WRITABLE,
  HB_MEMORY_MODE_READONLY_MAY_MAKE_WRITABLE
}

struct hb_blob_t {
  ~this() { destroy_user_data(); }

  void destroy_user_data() {
    if (destroy_cb) {
      destroy_cb(user_data);
      user_data = null;
      destroy_cb = null;
    }
  }

  private {
    bool try_make_writable();
    bool try_make_writable_inplace();
    bool try_make_writable_inplace_unix();
  }

  char[] as_bytes() inout => data[0..length].dup;
  Type* as(Type)() inout => as_bytes().as!Type(); 

  char* data = null;
  uint length = 0;
  hb_memory_mode_t mode = cast(hb_memory_mode_t) 0;

  void* user_data = null;
  hb_destroy_func_t destroy_cb = null;
}
