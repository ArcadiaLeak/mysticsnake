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

struct glslang_resource_t {
  int max_lights;
  int max_clip_planes;
  int max_texture_units;
  int max_texture_coords;
  int max_vertex_attribs;
  int max_vertex_uniform_components;
  int max_varying_floats;
  int max_vertex_texture_image_units;
  int max_combined_texture_image_units;
  int max_texture_image_units;
  int max_fragment_uniform_components;
  int max_draw_buffers;
  int max_vertex_uniform_vectors;
  int max_varying_vectors;
  int max_fragment_uniform_vectors;
  int max_vertex_output_vectors;
  int max_fragment_input_vectors;
  int min_program_texel_offset;
  int max_program_texel_offset;
  int max_clip_distances;
  int max_compute_work_group_count_x;
  int max_compute_work_group_count_y;
  int max_compute_work_group_count_z;
  int max_compute_work_group_size_x;
  int max_compute_work_group_size_y;
  int max_compute_work_group_size_z;
  int max_compute_uniform_components;
  int max_compute_texture_image_units;
  int max_compute_image_uniforms;
  int max_compute_atomic_counters;
  int max_compute_atomic_counter_buffers;
  int max_varying_components;
  int max_vertex_output_components;
  int max_geometry_input_components;
  int max_geometry_output_components;
  int max_fragment_input_components;
  int max_image_units;
  int max_combined_image_units_and_fragment_outputs;
  int max_combined_shader_output_resources;
  int max_image_samples;
  int max_vertex_image_uniforms;
  int max_tess_control_image_uniforms;
  int max_tess_evaluation_image_uniforms;
  int max_geometry_image_uniforms;
  int max_fragment_image_uniforms;
  int max_combined_image_uniforms;
  int max_geometry_texture_image_units;
  int max_geometry_output_vertices;
  int max_geometry_total_output_components;
  int max_geometry_uniform_components;
  int max_geometry_varying_components;
  int max_tess_control_input_components;
  int max_tess_control_output_components;
  int max_tess_control_texture_image_units;
  int max_tess_control_uniform_components;
  int max_tess_control_total_output_components;
  int max_tess_evaluation_input_components;
  int max_tess_evaluation_output_components;
  int max_tess_evaluation_texture_image_units;
  int max_tess_evaluation_uniform_components;
  int max_tess_patch_components;
  int max_patch_vertices;
  int max_tess_gen_level;
  int max_viewports;
  int max_vertex_atomic_counters;
  int max_tess_control_atomic_counters;
  int max_tess_evaluation_atomic_counters;
  int max_geometry_atomic_counters;
  int max_fragment_atomic_counters;
  int max_combined_atomic_counters;
  int max_atomic_counter_bindings;
  int max_vertex_atomic_counter_buffers;
  int max_tess_control_atomic_counter_buffers;
  int max_tess_evaluation_atomic_counter_buffers;
  int max_geometry_atomic_counter_buffers;
  int max_fragment_atomic_counter_buffers;
  int max_combined_atomic_counter_buffers;
  int max_atomic_counter_buffer_size;
  int max_transform_feedback_buffers;
  int max_transform_feedback_interleaved_components;
  int max_cull_distances;
  int max_combined_clip_and_cull_distances;
  int max_samples;
  int max_mesh_output_vertices_nv;
  int max_mesh_output_primitives_nv;
  int max_mesh_work_group_size_x_nv;
  int max_mesh_work_group_size_y_nv;
  int max_mesh_work_group_size_z_nv;
  int max_task_work_group_size_x_nv;
  int max_task_work_group_size_y_nv;
  int max_task_work_group_size_z_nv;
  int max_mesh_view_count_nv;
  int max_mesh_output_vertices_ext;
  int max_mesh_output_primitives_ext;
  int max_mesh_work_group_size_x_ext;
  int max_mesh_work_group_size_y_ext;
  int max_mesh_work_group_size_z_ext;
  int max_task_work_group_size_x_ext;
  int max_task_work_group_size_y_ext;
  int max_task_work_group_size_z_ext;
  int max_mesh_view_count_ext;
  int max_dual_source_draw_buffers_ext;
  glslang_limits_t limits;
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
