module glslang.c_interface;

import glslang;

private struct vec(T) {
  T[] data;

  this(ref inout(vec) other) {
    data = other.data.dup;
  }
}

struct glslang_input_t {
  glslang_source_t language;
  EShLanguage stage;
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
  TBuiltInResource resource;
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

struct glslang_limits_t {
  bool non_inductive_for_loops;
  bool while_loops;
  bool do_while_loops;
  bool general_uniform_indexing;
  bool general_attribute_matrix_vector_indexing;
  bool general_varying_indexing;
  bool general_sampler_indexing;
  bool general_variable_indexing;
  bool general_constant_matrix_vector_indexing;
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

TShader glslang_shader_create(glslang_input_t input) {
  auto shader = new TShader(input.stage);
  shader.setStrings([input.code]);
  shader.setEnvInput(
    input.language,
    input.stage,
    input.client,
    input.default_version);
  shader.setEnvClient(input.client, input.client_version);
  shader.setEnvTarget(input.target_language, input.target_language_version);

  return shader;
}

bool glslang_shader_preprocess(
  TShader shader,
  glslang_input_t input,
  out string preprocessedGLSL
) {
  return shader.preprocess(
    input.resource,
    input.default_version,
    input.default_profile,
    input.force_default_version_and_profile != 0,
    input.forward_compatible != 0,
    input.messages,
    preprocessedGLSL
  );
}
