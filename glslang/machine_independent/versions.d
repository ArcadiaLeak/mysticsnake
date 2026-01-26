module glslang.machine_independent.versions;

enum glslang_profile_t {
  NO_PROFILE = 1 << 0,
  CORE_PROFILE = 1 << 1,
  COMPATIBILITY_PROFILE = 1 << 2,
  ES_PROFILE = 1 << 3
}

string ProfileName(glslang_profile_t profile) {
  final switch (profile) {
    case glslang_profile_t.NO_PROFILE: return "none";
    case glslang_profile_t.CORE_PROFILE: return "core";
    case glslang_profile_t.COMPATIBILITY_PROFILE: return "compatibility";
    case glslang_profile_t.ES_PROFILE: return "es";
  }
}

struct SpvVersion {
  uint spv = 0;
  int vulkanGlsl;
  int vulkan;
  int openGl;
  bool vulkanRelaxed;
}
