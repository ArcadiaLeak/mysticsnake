module glslang.c_interface;

import glslang;

private struct vec(T) {
  T[] data;

  this(ref inout(vec) other) {
    data = other.data.dup;
  }
}

struct glslang_shader_t {
  TShader* shader;
  string preprocessedGLSL;
  vec!string baseResourceSetBinding;
}

struct glslang_input_t {
  glslang_source_t language;
  glslang_stage_t stage;
  glslang_client_t client;
  glslang_target_client_version_t client_version;
  glslang_target_language_t target_language;
  glslang_target_language_version_t target_language_version;
  string code;
  int default_version;
  glslang_profile_t default_profile;
  int force_default_version_and_profile;
  int forward_compatible;
  glslang_messages_t messages;
  glslang_resource_t* resource;
  glsl_include_callbacks_t callbacks;
  void* callbacks_ctx;
}

struct glsl_include_callbacks_t {
  glsl_include_system_func include_system;
  glsl_include_local_func include_local;
  glsl_free_include_result_func free_include_result;
}

struct glsl_include_result_t {
  string header_name;
  string header_data;
  size_t header_length;
}

alias glsl_include_system_func = glsl_include_result_t* function(
  void* ctx,
  string header_name,
  string includer_name,
  size_t include_depth
);

alias glsl_include_local_func = glsl_include_result_t* function(
  void* ctx,
  string header_name,
  string includer_name,
  size_t include_depth
);

alias glsl_free_include_result_func = int function(
  void* ctx,
  glsl_include_result_t* result
);
