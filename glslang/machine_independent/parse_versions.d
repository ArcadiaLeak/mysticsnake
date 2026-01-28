module glslang.machine_independent.parse_versions;

import glslang;

class TParseVersions {
  public {
    bool forwardCompatible;
    glslang_profile_t profile;

    TInfoSink infoSink;

    int version_;
    EShLanguage language;
    SpvVersion spvVersion;
    TIntermediate intermediate;
  }

  protected {
    glslang_messages_t messages;
    int numErrors;
    TInputScanner currentScanner;
  }

  this(
    TIntermediate interm, int version_, glslang_profile_t profile,
    in SpvVersion spvVersion, EShLanguage language, TInfoSink infoSink,
    bool forwardCompatible, glslang_messages_t messages
  ) @safe {
    this.forwardCompatible = forwardCompatible; this.profile = profile;
    this.infoSink = infoSink; this.version_ = version_; this.language = language;
    this.spvVersion = spvVersion; intermediate = interm; this.messages = messages;
    numErrors = 0; currentScanner = null;
  }
}
