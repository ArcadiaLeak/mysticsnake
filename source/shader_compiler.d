import glslang;
import scenegraph.vk.vulkan;

import std.stdio;
import std.string;

class ShaderCompiler {
public:
  static void Initialize() {
    if (!s_initialized) {
      glslang_initialize_process();
      s_initialized = true;
    }
  }

  static void Finalize() {
    if (s_initialized) {
      glslang_finalize_process();
      s_initialized = false;
    }
  }

  static const(uint[]) CompileGLSLtoSPIRV(
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
    
    if (spirvSize == 0 || spirvCode == null) {
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

  static VkShaderModule CreateShaderModule(
    VkDevice device,
    in uint[] spirvCode
  ) {
    VkShaderModuleCreateInfo createInfo;
    createInfo.sType = VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO;
    createInfo.codeSize = spirvCode.length * uint.sizeof;
    createInfo.pCode = spirvCode.ptr;
    
    VkShaderModule shaderModule;
    if (vkCreateShaderModule(device, &createInfo, null, &shaderModule) != VK_SUCCESS) {
      throw new Exception("Failed to create shader module");
    }
    
    return shaderModule;
  }

private:
  static bool s_initialized;
};