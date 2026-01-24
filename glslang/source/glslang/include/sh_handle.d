module glslang.include.sh_handle;

import glslang;

class TCompiler {
  glslang_stage_t getLanguage() => language;

  this(glslang_stage_t l, TInfoSink i) {
    language = l;
  }

  TInfoSink infoSink;
protected:
  glslang_stage_t language;
}
