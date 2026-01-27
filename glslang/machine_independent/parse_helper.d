module glslang.machine_independent.parse_helper;

import glslang;

class TParseContextBase {}

class TParseContext : TParseContextBase {
  this(
    TSymbolTable, TIntermediate, bool parsingBuiltIns, int version_,
    glslang_profile_t profile, in SpvVersion spvVersion, glslang_stage_t,
    TInfoSink, bool forwardCompatible,
    glslang_messages_t messages = glslang_messages_t.MSG_DEFAULT_BIT,
    string entryPoint = null
  ) {}
}
