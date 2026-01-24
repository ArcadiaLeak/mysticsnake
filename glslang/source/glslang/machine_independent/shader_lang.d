module glslang.machine_independent.shader_lang;

import glslang;

struct TTarget {
  glslang_target_language_t language;
  glslang_target_language_version_t version_;
}

struct TInputLanguage {
  glslang_source_t languageFamily;
  glslang_stage_t stage;
  glslang_client_t dialect;
  int dialectVersion;
  bool vulkanRulesRelaxed;
}

struct TClient {
  glslang_client_t client;
  glslang_target_client_version_t version_;
}

struct TEnvironment {
  TInputLanguage input;
  TClient client;
  TTarget target;
}

class TShader {
  protected {
    string[] strings;
    string[] stringNames;

    glslang_stage_t stage;
    int overrideVersion;

    TEnvironment environment;
    TInfoSink infoSink;
    TCompiler compiler;
    TIntermediate intermediate;
  }

  this(glslang_stage_t s) {
    stage = s;

    infoSink = new TInfoSink;
    compiler = new TDeferredCompiled(stage, infoSink);
    intermediate = new TIntermediate(s);
  }

  void setStrings(string[] s) {
    strings = s;
  }

  void setEnvTarget(
    glslang_target_language_t lang,
    glslang_target_language_version_t version_
  ) {
    environment.target.language = lang;
    environment.target.version_ = version_;
  }

  void setEnvInput(
    glslang_source_t lang,
    glslang_stage_t envStage,
    glslang_client_t client,
    int version_
  ) {
    environment.input.languageFamily = lang;
    environment.input.stage = envStage;
    environment.input.dialect = client;
    environment.input.dialectVersion = version_;
  }

  void setEnvClient(
    glslang_client_t client,
    glslang_target_client_version_t version_
  ) {
    environment.client.client = client;
    environment.client.version_ = version_;
  }

  bool preprocess(
    const TBuiltInResource* builtInResources,
    int defaultVersion, glslang_profile_t defaultProfile,
    bool forceDefaultVersionAndProfile,
    bool forwardCompatible, glslang_messages_t message,
    out string output_string
  ) {
    return PreprocessDeferred(
      compiler, strings, stringNames, builtInResources,
      defaultVersion, defaultProfile, forceDefaultVersionAndProfile,
      overrideVersion, forwardCompatible, message, intermediate,
      output_string, &environment
    );
  }
}

class TDeferredCompiled : TCompiler {
  this(glslang_stage_t s, TInfoSink i) {
    super(s, i);
  }
}

bool PreprocessDeferred(
  TCompiler compiler,
  const string[] shaderStrings,
  const string[] stringNames,
  const TBuiltInResource* resources,
  int defaultVersion,
  glslang_profile_t defaultProfile,
  bool forceDefaultVersionAndProfile,
  int overrideVersion,
  bool forwardCompatible,
  glslang_messages_t messages,
  TIntermediate intermediate,
  out string outputString,
  const TEnvironment* environment = null
) {
  return ProcessDeferred(
    compiler, shaderStrings, stringNames, resources,
    defaultVersion, defaultProfile, forceDefaultVersionAndProfile,
    overrideVersion, forwardCompatible, messages, intermediate,
    0, false, "", environment
  );
}

bool ProcessDeferred(ProcessingContext)(
  TCompiler compiler,
  const string[] shaderStrings,
  const string[] stringNames,
  const TBuiltInResource* resources,
  int defaultVersion,
  glslang_profile_t defaultProfile,
  bool forceDefaultVersionAndProfile,
  int overrideVersion,
  bool forwardCompatible,
  glslang_messages_t messages,
  TIntermediate intermediate,
  ProcessingContext processingContext,
  bool requireNonempty,
  string sourceEntryPointName,
  const TEnvironment* environment
) {
  if (shaderStrings.length == 0) {
    return true;
  }

  const int numPre = 2;
  const int numPost = requireNonempty ? 1 : 0;
  const int numTotal = numPre + cast(int) shaderStrings.length + numPost;

  size_t[] lengths = new size_t[numTotal];
  string[] strings = new string[numTotal];
  string[] names = new string[numTotal];
  foreach(s, shaderString; shaderStrings) {
    strings[s + numPre] = shaderString;
    lengths[s + numPre] = shaderString.length;
  }
  if (stringNames.length > 0) {
    foreach(s, stringName; stringNames) {
      names[s + numPre] = stringName;
    }
  }

  SpvVersion spvVersion;
  glslang_source_t source = glslang_source_t.SOURCE_GLSL;
  glslang_stage_t stage = compiler.getLanguage;
  TranslateEnvironment(environment, messages, source, stage, spvVersion);

  return false;
}

void TranslateEnvironment(
  const TEnvironment* environment,
  ref glslang_messages_t messages,
  ref glslang_source_t source,
  ref glslang_stage_t stage,
  ref SpvVersion spvVersion
) {
  if (messages & glslang_messages_t.MSG_SPV_RULES_BIT)
    spvVersion.spv = glslang_target_language_version_t.TARGET_SPV_1_0;
  if (messages & glslang_messages_t.MSG_VULKAN_RULES_BIT) {
    spvVersion.vulkan = glslang_target_client_version_t.TARGET_VULKAN_1_0;
    spvVersion.vulkanGlsl = 100;
  } else if (spvVersion.spv != 0)
    spvVersion.openGl = 100;

  if (environment == null) return;

  if (environment.input.languageFamily != glslang_source_t.SOURCE_NONE) {
    stage = environment.input.stage;
    final switch (environment.input.dialect) {
      case glslang_client_t.CLIENT_NONE:
        break;
      case glslang_client_t.CLIENT_VULKAN:
        spvVersion.vulkanGlsl = environment.input.dialectVersion;
        spvVersion.vulkanRelaxed = environment.input.vulkanRulesRelaxed;
        break;
      case glslang_client_t.CLIENT_OPENGL:
        spvVersion.openGl = environment.input.dialectVersion;
    }
    final switch (environment.input.languageFamily) {
      case glslang_source_t.SOURCE_NONE:
        break;
      case glslang_source_t.SOURCE_GLSL:
        source = glslang_source_t.SOURCE_GLSL;
        messages = messages & ~glslang_messages_t.MSG_READ_HLSL_BIT;
        break;
      case glslang_source_t.SOURCE_HLSL:
        source = glslang_source_t.SOURCE_HLSL;
        messages = messages | glslang_messages_t.MSG_READ_HLSL_BIT;
        break;
    }
  }

  if (environment.client.client == glslang_client_t.CLIENT_VULKAN)
    spvVersion.vulkan = environment.client.version_;

  if (environment.target.language == glslang_target_language_t.TARGET_SPV)
    spvVersion.spv = environment.target.version_;
}
