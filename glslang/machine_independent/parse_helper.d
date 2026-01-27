module glslang.machine_independent.parse_helper;

import glslang;

class TParseContextBase : TParseVersions {
  this(
    TSymbolTable symbolTable, TIntermediate interm, bool parsingBuiltins, int version_,
    glslang_profile_t profile, in SpvVersion, glslang_stage_t language,
    TInfoSink infoSink, bool forwardCompatible, glslang_messages_t messages,
    string entryPoint = null
  ) {
    super(
      interm, version_, profile, spvVersion, language, infoSink,
      forwardCompatible, messages
    );
    /*
    scopeManager = "::"; this.symbolTable = symbolTable; statementNestingLevel = 0;
    loopNestingLevel = 0; structNestingLevel = 0; blockNestingLevel = 0; controlFlowNestingLevel = 0;
    currentFunctionType = null; postEntryPointReturn = false; contextPragma = ContextPragma(true, false);
    beginInvocationInterlockCount = 0; endInvocationInterlockCount = 0;
    this.parsingBuiltins = parsingBuiltins; scanContext = null; ppContext = null;
    limits = resources.limits; globalUniformBlock = null; globalUniformBinding = TQualifier.layoutBindingEnd;
    globalUniformSet = TQualifier.layoutSetEnd; atomicCounterBlockSet = TQualifier.layoutSetEnd;

    if (spvVersion.spv >= glslang_target_language_version_t.TARGET_SPV_1_3)
      intermediate.setUseStorageBuffer();
    
    if (entryPoint != null)
      sourceEntryPointName = entryPoint;
    */
  }
}

class TParseContext : TParseContextBase {
  this(
    TSymbolTable symbolTable, TIntermediate interm, bool parsingBuiltIns,
    int version_, glslang_profile_t profile, in SpvVersion spvVersion,
    glslang_stage_t language, TInfoSink, bool forwardCompatible,
    glslang_messages_t messages = glslang_messages_t.MSG_DEFAULT_BIT,
    string entryPoint = null
  ) {
    super(
      symbolTable, interm, parsingBuiltIns, version_, profile, spvVersion,
      language, infoSink, forwardCompatible, messages, entryPoint
    );
  }
}
