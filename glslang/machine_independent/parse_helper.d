module glslang.machine_independent.parse_helper;

import glslang;

struct TPragma {
  this(bool o, bool d) @safe { optimize = o; debug_ = d; }
  bool optimize;
  bool debug_;
  TPragmaTable pragmaTable;
}

class TParseContextBase : TParseVersions {
  public {
    string scopeMangler;
    TSymbolTable symbolTable;
    int statementNestingLevel;
    int loopNestingLevel;
    int structNestingLevel;
    int blockNestingLevel;
    int controlFlowNestingLevel;
    TType currentFunctionType;
    bool postEntryPointReturn;
    TPragma contextPragma;
    int beginInvocationInterlockCount;
    int endInvocationInterlockCount;
  }
  
  protected {
    const bool parsingBuiltins;
    TScanContext scanContext;
    TPpContext ppContext;
    TBuiltInResourceRec resources;
    string sourceEntryPointName;

    TVariable globalUniformBlock;
    uint globalUniformBinding;
    uint globalUniformSet;

    uint atomicCounterBlockSet;
  }

  ref TLimits limits() => resources.limits;

  this(
    TSymbolTable symbolTable, TIntermediate interm, bool parsingBuiltins, int version_,
    glslang_profile_t profile, in SpvVersion, EShLanguage language,
    TInfoSink infoSink, bool forwardCompatible, glslang_messages_t messages,
    string entryPoint = null
  ) @safe {
    super(
      interm, version_, profile, spvVersion, language, infoSink,
      forwardCompatible, messages
    );
    scopeMangler = "::"; this.symbolTable = symbolTable; statementNestingLevel = 0;
    loopNestingLevel = 0; structNestingLevel = 0; blockNestingLevel = 0; controlFlowNestingLevel = 0;
    currentFunctionType = null; postEntryPointReturn = false; contextPragma = TPragma(true, false);
    beginInvocationInterlockCount = 0; endInvocationInterlockCount = 0;
    this.parsingBuiltins = parsingBuiltins; scanContext = null; ppContext = null;
    globalUniformBlock = null; globalUniformBinding = TQualifier.layoutBindingEnd;
    globalUniformSet = TQualifier.layoutSetEnd; atomicCounterBlockSet = TQualifier.layoutSetEnd;

    if (spvVersion.spv >= glslang_target_language_version_t.TARGET_SPV_1_3)
      intermediate.setUseStorageBuffer();
    
    if (entryPoint != null)
      sourceEntryPointName = entryPoint;
  }

  void setScanContext(TScanContext c) @safe { scanContext = c; }
  void setPpContext(TPpContext c) @safe { ppContext = c; }
}

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
