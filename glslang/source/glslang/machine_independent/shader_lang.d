module glslang.machine_independent.shader_lang;

import glslang;

import std.conv;
import std.range;

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
    TBuiltInResource builtInResources,
    int defaultVersion, glslang_profile_t defaultProfile,
    bool forceDefaultVersionAndProfile,
    bool forwardCompatible, glslang_messages_t message,
    out string output_string
  ) {
    return PreprocessDeferred(
      compiler, strings, stringNames, builtInResources,
      defaultVersion, defaultProfile, forceDefaultVersionAndProfile,
      overrideVersion, forwardCompatible, message, intermediate,
      output_string, environment
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
  in string[] shaderStrings,
  in string[] stringNames,
  TBuiltInResource resources,
  int defaultVersion,
  glslang_profile_t defaultProfile,
  bool forceDefaultVersionAndProfile,
  int overrideVersion,
  bool forwardCompatible,
  glslang_messages_t messages,
  TIntermediate intermediate,
  out string outputString,
  in TEnvironment environment
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
  TBuiltInResource resources,
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
  in TEnvironment environment
) {
  if (shaderStrings.length == 0) {
    return true;
  }

  const int numPre = 2;
  const int numPost = requireNonempty ? 1 : 0;
  const int numTotal = numPre + cast(int) shaderStrings.length + numPost;

  string[] strings = new string[numTotal];
  string[] names = new string[numTotal];
  foreach(s, shaderString; shaderStrings) {
    strings[s + numPre] = shaderString;
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

  scope userInput = new TInputScanner(strings.drop(numPre));
  int version_ = 0;
  glslang_profile_t profile = glslang_profile_t.NO_PROFILE;
  bool versionNotFirstToken = false;
  bool versionNotFirst = userInput.scanVersion(version_, profile, versionNotFirstToken);
  bool versionNotFound = version_ == 0;
  if (forceDefaultVersionAndProfile && source == glslang_source_t.SOURCE_GLSL) {
    if (
      !(messages & glslang_messages_t.MSG_SUPPRESS_WARNINGS_BIT) &&
      !versionNotFound &&
      (version_ != defaultVersion || profile != defaultProfile)
    ) {
      compiler.infoSink.info.append =
        "Warning, (version, profile) forced to be (" ~
        defaultVersion.to!string ~ ", " ~ ProfileName(defaultProfile) ~
        "), while in source code it is (" ~
        version_.to!string ~ ", " ~ ProfileName(profile) ~ ")\n";
    }

    if (versionNotFound) {
      versionNotFirstToken = false;
      versionNotFirst = false;
      versionNotFound = false;
    }
    version_ = defaultVersion;
    profile = defaultProfile;
  }
  if (source == glslang_source_t.SOURCE_GLSL && overrideVersion != 0) {
    version_ = overrideVersion;
  }

  bool goodVersion = DeduceVersionProfile(
    compiler.infoSink, stage, versionNotFirst, defaultVersion,
    source, version_, profile, spvVersion
  );
  bool versionWillBeError = (
    versionNotFound ||
    (profile == glslang_profile_t.ES_PROFILE &&
      version_ >= 300 && versionNotFirst)
  );
  bool warnVersionNotFirst = false;
  if (!versionWillBeError && versionNotFirstToken) {
    if (messages & glslang_messages_t.MSG_RELAXED_ERRORS_BIT)
      warnVersionNotFirst = true;
    else
      versionWillBeError = true;
  }

  intermediate.setSource = source;
  intermediate.setVersion = version_;
  intermediate.setProfile = profile;
  intermediate.setSpv = spvVersion;
  RecordProcesses(intermediate, messages, sourceEntryPointName);
  

  return false;
}

void TranslateEnvironment(
  in TEnvironment environment,
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

bool DeduceVersionProfile(
  TInfoSink infoSink,
  glslang_stage_t stage,
  bool versionNotFirst,
  int defaultVersion,
  glslang_source_t source,
  ref int version_,
  ref glslang_profile_t profile,
  in SpvVersion spvVersion
) {
  const int FirstProfileVersion = 150;
  bool correct = true;

  if (version_ == 0) {
    version_ = defaultVersion;
  }

  if (profile == glslang_profile_t.NO_PROFILE) {
    if (version_ == 300 || version_ == 310 || version_ == 320) {
      correct = false;
      infoSink.info.message(
        TPrefixType.EPrefixError,
        "#version: versions 300, 310, and 320 require specifying the 'es' profile"
      );
      profile = glslang_profile_t.ES_PROFILE;
    } else if (version_ == 100)
      profile = glslang_profile_t.ES_PROFILE;
    else if (version_ >= FirstProfileVersion)
      profile = glslang_profile_t.CORE_PROFILE;
    else
      profile = glslang_profile_t.NO_PROFILE;
  } else {
    if (version_ < 150) {
      correct = false;
      infoSink.info.message(
        TPrefixType.EPrefixError,
        "#version: versions before 150 do not allow a profile token"
      );
      if (version_ == 100)
        profile = glslang_profile_t.ES_PROFILE;
      else
        profile = glslang_profile_t.NO_PROFILE;
    } else if (version_ == 300 || version_ == 310 || version_ == 320) {
      if (profile != glslang_profile_t.ES_PROFILE) {
        correct = false;
        infoSink.info.message(
          TPrefixType.EPrefixError,
          "#version: versions 300, 310, and 320 support only the es profile"
        );
      }
      profile = glslang_profile_t.ES_PROFILE;
    } else {
      if (profile == glslang_profile_t.ES_PROFILE) {
        correct = false;
        infoSink.info.message(
          TPrefixType.EPrefixError,
          "#version: only version 300, 310, and 320 support the es profile"
        );
        if (version_ >= FirstProfileVersion)
          profile = glslang_profile_t.CORE_PROFILE;
        else
          profile = glslang_profile_t.NO_PROFILE;
      }
    }
  }

  switch (version_) {
    case 100: break;
    case 300: break;
    case 310: break;
    case 320: break;

    case 110: break;
    case 120: break;
    case 130: break;
    case 140: break;
    case 150: break;
    case 330: break;
    case 400: break;
    case 410: break;
    case 420: break;
    case 430: break;
    case 440: break;
    case 450: break;
    case 460: break;

    default:
      correct = false;
      infoSink.info.message(TPrefixType.EPrefixError, "version not supported");
      if (profile == glslang_profile_t.ES_PROFILE)
        version_ = 310;
      else {
        version_ = 450;
        profile = glslang_profile_t.CORE_PROFILE;
      }
      break;
  }

  if (
    profile == glslang_profile_t.ES_PROFILE &&
    version_ >= 300 && versionNotFirst
  ) {
    correct = false;
    infoSink.info.message(
      TPrefixType.EPrefixError,
      "#version: statement must appear first in es-profile shader; before comments or newlines"
    );
  }

  if (spvVersion.spv != 0) {
    switch (profile) {
      case glslang_profile_t.ES_PROFILE:
        if (version_ < 310) {
          correct = false;
          infoSink.info.message(
            TPrefixType.EPrefixError,
            "#version: ES shaders for SPIR-V require version 310 or higher"
          );
          version_ = 310;
        }
        break;
      case glslang_profile_t.COMPATIBILITY_PROFILE:
        infoSink.info.message(
          TPrefixType.EPrefixError,
          "#version: compilation for SPIR-V does not support the compatibility profile"
        );
        break;
      default:
        if (spvVersion.vulkan > 0 && version_ < 140) {
          correct = false;
          infoSink.info.message(
            TPrefixType.EPrefixError,
            "#version: Desktop shaders for Vulkan SPIR-V require version 140 or higher"
          );
          version_ = 140;
        }
        if (spvVersion.openGl >= 100 && version_ < 330) {
          correct = false;
          infoSink.info.message(
            TPrefixType.EPrefixError,
            "#version: Desktop shaders for OpenGL SPIR-V require version 330 or higher"
          );
        }
        break;
    }
  }

  return correct;
}

void RecordProcesses(
  TIntermediate intermediate,
  glslang_messages_t messages,
  string sourceEntryPointName
) {
  if ((messages & glslang_messages_t.MSG_RELAXED_ERRORS_BIT) != 0)
    intermediate.addProcess = "relaxed-errors";
  if ((messages & glslang_messages_t.MSG_SUPPRESS_WARNINGS_BIT) != 0)
    intermediate.addProcess = "suppress-warnings";
  if ((messages & glslang_messages_t.MSG_KEEP_UNCALLED_BIT) != 0)
    intermediate.addProcess = "keep-uncalled";
  if (sourceEntryPointName.length > 0) {
    intermediate.addProcess = "source-entrypoint";
    intermediate.addProcessArgument = sourceEntryPointName;
  }
}