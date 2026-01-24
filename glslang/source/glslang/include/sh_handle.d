module glslang.include.sh_handle;

import glslang;

class TCompiler {
  protected {
    glslang_stage_t language;
  }

  this(glslang_stage_t l, TInfoSink i) {
    language = l;
  }

  glslang_stage_t getLanguage() => language;
}
