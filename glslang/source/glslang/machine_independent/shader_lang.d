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
  TEnvironment* environment = null
) {
  return false;
}
