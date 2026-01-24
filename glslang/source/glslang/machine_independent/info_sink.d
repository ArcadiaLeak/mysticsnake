module glslang.machine_independent.info_sink;

enum TPrefixType {
  EPrefixNone,
  EPrefixWarning,
  EPrefixError,
  EPrefixInternalError,
  EPrefixUnimplemented,
  EPrefixNote
}

struct TInfoSinkBase {
  protected {
    string sink;
  }

  void append(string s) {
    sink ~= s;
  }

  void message(TPrefixType msg, string s) {
    prefix(msg);
    append(s);
    append("\n");
  }

  void prefix(TPrefixType message) {
    final switch (message) {
      case TPrefixType.EPrefixNone:
        break;
      case TPrefixType.EPrefixWarning:
        append("WARNING: ");
        break;
      case TPrefixType.EPrefixError:
        append("ERROR: ");
        break;
      case TPrefixType.EPrefixInternalError:
        append("INTERNAL ERROR: ");
        break;
      case TPrefixType.EPrefixUnimplemented:
        append("UNIMPLEMENTED: ");
        break;
      case TPrefixType.EPrefixNote:
        append("NOTE: ");
        break;
    }
  }
}

class TInfoSink {
  TInfoSinkBase info;
}
