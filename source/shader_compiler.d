import glslang;

class ShaderCompiler {
public:
  static void Initialize() {
    if (!s_initialized) {
      glslang_initialize_process();
      s_initialized = true;
    }
  }

private:
  static bool s_initialized;
};