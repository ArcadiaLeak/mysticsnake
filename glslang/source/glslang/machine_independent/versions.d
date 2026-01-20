module glslang.machine_independent.versions;

enum EProfile {
  EBadProfile = 0,
  ENoProfile = 1 << 0,
  ECoreProfile = 1 << 1,
  ECompatibilityProfile = 1 << 2,
  EEsProfile = 1 << 3
}

struct SpvVersion {
  uint spv = 0;
  int vulkanGlsl;
  int vulkan;
  int openGl;
  bool vulkanRelaxed;
}
