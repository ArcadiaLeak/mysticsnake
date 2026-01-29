module glslang.machine_independent.parse_helper;

import glslang;

class TParseContext : TParseContextBase {
  this(
    TSymbolTable symbolTable, TIntermediate interm, bool parsingBuiltIns,
    int version_, glslang_profile_t profile, in SpvVersion spvVersion,
    EShLanguage language, TInfoSink, bool forwardCompatible,
    glslang_messages_t messages = glslang_messages_t.MSG_DEFAULT_BIT,
    string entryPoint = null
  ) @safe {
    super(
      symbolTable, interm, parsingBuiltIns, version_, profile, spvVersion,
      language, infoSink, forwardCompatible, messages, entryPoint
    );
  }
}
