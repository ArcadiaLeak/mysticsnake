import glslang;

import std.stdio;
import std.string;

enum SDL_GPU_BUFFERUSAGE_VERTEX = 1u << 0; /**< Buffer is a vertex buffer. */
enum SDL_GPU_BUFFERUSAGE_INDEX = 1u << 1; /**< Buffer is an index buffer. */
enum SDL_GPU_BUFFERUSAGE_INDIRECT = 1u << 2; /**< Buffer is an indirect buffer. */
enum SDL_GPU_BUFFERUSAGE_GRAPHICS_STORAGE_READ = 1u << 3; /**< Buffer supports storage reads in graphics stages. */
enum SDL_GPU_BUFFERUSAGE_COMPUTE_STORAGE_READ = 1u << 4; /**< Buffer supports storage reads in the compute stage. */
enum SDL_GPU_BUFFERUSAGE_COMPUTE_STORAGE_WRITE = 1u << 5; /**< Buffer supports storage writes in the compute stage. */

enum SDL_INIT_AUDIO = 0x00000010u; /**< `SDL_INIT_AUDIO` implies `SDL_INIT_EVENTS` */
enum SDL_INIT_VIDEO = 0x00000020u; /**< `SDL_INIT_VIDEO` implies `SDL_INIT_EVENTS`, should be initialized on the main thread */
enum SDL_INIT_JOYSTICK = 0x00000200u; /**< `SDL_INIT_JOYSTICK` implies `SDL_INIT_EVENTS` */
enum SDL_INIT_HAPTIC = 0x00001000u;
enum SDL_INIT_GAMEPAD = 0x00002000u; /**< `SDL_INIT_GAMEPAD` implies `SDL_INIT_JOYSTICK` */
enum SDL_INIT_EVENTS = 0x00004000u;
enum SDL_INIT_SENSOR = 0x00008000u; /**< `SDL_INIT_SENSOR` implies `SDL_INIT_EVENTS` */
enum SDL_INIT_CAMERA = 0x00010000u; /**< `SDL_INIT_CAMERA` implies `SDL_INIT_EVENTS` */

enum SDL_GPU_SHADERFORMAT_INVALID = 0;
enum SDL_GPU_SHADERFORMAT_PRIVATE = 1u << 0; /**< Shaders for NDA'd platforms. */
enum SDL_GPU_SHADERFORMAT_SPIRV = 1u << 1; /**< SPIR-V shaders for Vulkan. */
enum SDL_GPU_SHADERFORMAT_DXBC = 1u << 2; /**< DXBC SM5_1 shaders for D3D12. */
enum SDL_GPU_SHADERFORMAT_DXIL = 1u << 3; /**< DXIL SM6_0 shaders for D3D12. */
enum SDL_GPU_SHADERFORMAT_MSL = 1u << 4; /**< MSL shaders for Metal. */
enum SDL_GPU_SHADERFORMAT_METALLIB = 1u << 5; /**< Precompiled metallib shaders for Metal. */

static bool s_initialized = false;

static void glslangInitialize() {
  if (!s_initialized) {
    glslang_initialize_process();
    s_initialized = true;
  }
}

static void glslangFinalize() {
  if (s_initialized) {
    glslang_finalize_process();
    s_initialized = false;
  }
}

const(uint[]) compileGLSLtoSPIRV(
  string source,
  string filename,
  bool vertexShader
) {
  if (!s_initialized) {
    throw new Exception("ShaderCompiler not initialized. Call Initialize() first.");
  }
  
  glslang_stage_t glslangStage = vertexShader ? GLSLANG_STAGE_VERTEX : GLSLANG_STAGE_FRAGMENT;
  glslang_resource_t* default_resource = glslang_default_resource();

  glslang_input_t input = glslang_input_t();
  input.language = GLSLANG_SOURCE_GLSL;
  input.stage = glslangStage;
  input.client = GLSLANG_CLIENT_VULKAN;
  input.client_version = GLSLANG_TARGET_VULKAN_1_0;
  input.target_language = GLSLANG_TARGET_SPV;
  input.target_language_version = GLSLANG_TARGET_SPV_1_0;
  input.code = source.toStringz;
  input.default_version = 310;
  input.default_profile = GLSLANG_ES_PROFILE;
  input.force_default_version_and_profile = false;
  input.forward_compatible = false;
  input.messages = GLSLANG_MSG_DEFAULT_BIT;
  input.resource = default_resource;

  glslang_shader_t* shader = glslang_shader_create(&input);
  if (!shader) {
    throw new Exception("Failed to create shader");
  }

  int parseResult = glslang_shader_preprocess(shader, &input);
  if (!parseResult) {
    string infoLog = glslang_shader_get_info_log(shader).fromStringz.idup;
    string infoDebugLog = glslang_shader_get_info_debug_log(shader).fromStringz.idup;
    
    debug stderr.writef("Shader preprocessing failed for: %s\n", filename);
    debug stderr.writef("Info log: %s\n", infoLog ? infoLog : "No info log");
    debug stderr.writef("Debug log:: %s\n", infoDebugLog ? infoDebugLog : "No debug log");
    
    glslang_shader_delete(shader);
    throw new Exception("Shader preprocessing failed");
  }

  parseResult = glslang_shader_parse(shader, &input);
  if (!parseResult) {
    string infoLog = glslang_shader_get_info_log(shader).fromStringz.idup;
    string infoDebugLog = glslang_shader_get_info_debug_log(shader).fromStringz.idup;
    
    debug stderr.writef("Shader parsing failed for: %s\n", filename);
    debug stderr.writef("Info log: %s\n", infoLog ? infoLog : "No info log");
    debug stderr.writef("Debug log:: %s\n", infoDebugLog ? infoDebugLog : "No debug log");
    
    glslang_shader_delete(shader);
    throw new Exception("Shader parsing failed");
  }

  glslang_program_t* program = glslang_program_create();
  glslang_program_add_shader(program, shader);
  
  int linkResult = glslang_program_link(
    program,
    GLSLANG_MSG_SPV_RULES_BIT | GLSLANG_MSG_VULKAN_RULES_BIT
  );
  if (!linkResult) {
    string infoLog = glslang_program_get_info_log(program).fromStringz.idup;
    string infoDebugLog = glslang_program_get_info_debug_log(program).fromStringz.idup;
    
    debug stderr.writef("Shader linking failed for: %s\n", filename);
    debug stderr.writef("Info log: %s\n", infoLog ? infoLog : "No info log");
    debug stderr.writef("Debug log:: %s\n", infoDebugLog ? infoDebugLog : "No debug log");
    
    glslang_program_delete(program);
    glslang_shader_delete(shader);
    throw new Exception("Shader linking failed");
  }

  glslang_program_map_io(program);
  glslang_program_SPIRV_generate(program, input.stage);
  
  size_t spirvSize = glslang_program_SPIRV_get_size(program);
  const uint* spirvCode = glslang_program_SPIRV_get_ptr(program);
  
  if (spirvSize == 0 || spirvCode is null) {
    debug stderr.writef("Failed to generate SPIR-V for: %s\n", filename);

    glslang_program_delete(program);
    glslang_shader_delete(shader);
    throw new Exception("SPIR-V generation failed");
  }

  string spirvMessages = glslang_program_SPIRV_get_messages(program).fromStringz.idup;
  if (spirvMessages && spirvMessages.length > 0) {
    debug writef("SPIR-V messages for %s: %s\n", filename, spirvMessages);
  }
  
  auto spirv = spirvCode[0..spirvSize].dup;

  glslang_program_delete(program);
  glslang_shader_delete(shader);

  return spirv;
}

