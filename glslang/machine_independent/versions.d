module glslang.machine_independent.versions;

enum string E_GL_OES_texture_3D = "GL_OES_texture_3D";
enum string E_GL_OES_standard_derivatives = "GL_OES_standard_derivatives";
enum string E_GL_EXT_frag_depth = "GL_EXT_frag_depth";
enum string E_GL_OES_EGL_image_external = "GL_OES_EGL_image_external";
enum string E_GL_OES_EGL_image_external_essl3 = "GL_OES_EGL_image_external_essl3";
enum string E_GL_EXT_YUV_target = "GL_EXT_YUV_target";
enum string E_GL_EXT_shader_texture_lod = "GL_EXT_shader_texture_lod";
enum string E_GL_EXT_shadow_samplers = "GL_EXT_shadow_samplers";

enum string E_GL_ARB_texture_rectangle = "GL_ARB_texture_rectangle";
enum string E_GL_3DL_array_objects = "GL_3DL_array_objects";
enum string E_GL_ARB_shading_language_420pack = "GL_ARB_shading_language_420pack";
enum string E_GL_ARB_texture_gather = "GL_ARB_texture_gather";
enum string E_GL_ARB_gpu_shader5 = "GL_ARB_gpu_shader5";
enum string E_GL_ARB_separate_shader_objects = "GL_ARB_separate_shader_objects";
enum string E_GL_ARB_compute_shader = "GL_ARB_compute_shader";
enum string E_GL_ARB_tessellation_shader = "GL_ARB_tessellation_shader";
enum string E_GL_ARB_enhanced_layouts = "GL_ARB_enhanced_layouts";
enum string E_GL_ARB_texture_cube_map_array = "GL_ARB_texture_cube_map_array";
enum string E_GL_ARB_texture_multisample = "GL_ARB_texture_multisample";
enum string E_GL_ARB_shader_texture_lod = "GL_ARB_shader_texture_lod";
enum string E_GL_ARB_explicit_attrib_location = "GL_ARB_explicit_attrib_location";
enum string E_GL_ARB_explicit_uniform_location = "GL_ARB_explicit_uniform_location";
enum string E_GL_ARB_shader_image_load_store = "GL_ARB_shader_image_load_store";
enum string E_GL_ARB_shader_atomic_counters = "GL_ARB_shader_atomic_counters";
enum string E_GL_ARB_shader_atomic_counter_ops = "GL_ARB_shader_atomic_counter_ops";
enum string E_GL_ARB_shader_draw_parameters = "GL_ARB_shader_draw_parameters";
enum string E_GL_ARB_shader_group_vote = "GL_ARB_shader_group_vote";
enum string E_GL_ARB_derivative_control = "GL_ARB_derivative_control";
enum string E_GL_ARB_shader_texture_image_samples = "GL_ARB_shader_texture_image_samples";
enum string E_GL_ARB_viewport_array = "GL_ARB_viewport_array";
enum string E_GL_ARB_gpu_shader_int64 = "GL_ARB_gpu_shader_int64";
enum string E_GL_ARB_gpu_shader_fp64 = "GL_ARB_gpu_shader_fp64";
enum string E_GL_ARB_shader_ballot = "GL_ARB_shader_ballot";
enum string E_GL_ARB_sparse_texture2 = "GL_ARB_sparse_texture2";
enum string E_GL_ARB_sparse_texture_clamp = "GL_ARB_sparse_texture_clamp";
enum string E_GL_ARB_shader_stencil_export = "GL_ARB_shader_stencil_export";
enum string E_GL_ARB_post_depth_coverage = "GL_ARB_post_depth_coverage";
enum string E_GL_ARB_shader_viewport_layer_array = "GL_ARB_shader_viewport_layer_array";
enum string E_GL_ARB_fragment_shader_interlock = "GL_ARB_fragment_shader_interlock";
enum string E_GL_ARB_shader_clock = "GL_ARB_shader_clock";
enum string E_GL_ARB_uniform_buffer_object = "GL_ARB_uniform_buffer_object";
enum string E_GL_ARB_sample_shading = "GL_ARB_sample_shading";
enum string E_GL_ARB_shader_bit_encoding = "GL_ARB_shader_bit_encoding";
enum string E_GL_ARB_shader_image_size = "GL_ARB_shader_image_size";
enum string E_GL_ARB_shader_storage_buffer_object = "GL_ARB_shader_storage_buffer_object";
enum string E_GL_ARB_shading_language_packing = "GL_ARB_shading_language_packing";
enum string E_GL_ARB_texture_query_lod = "GL_ARB_texture_query_lod";
enum string E_GL_ARB_vertex_attrib_64bit = "GL_ARB_vertex_attrib_64bit";
enum string E_GL_ARB_draw_instanced = "GL_ARB_draw_instanced";
enum string E_GL_ARB_fragment_coord_conventions = "GL_ARB_fragment_coord_conventions";
enum string E_GL_ARB_bindless_texture = "GL_ARB_bindless_texture";
enum string E_GL_ARB_conservative_depth = "GL_ARB_conservative_depth";

enum string E_GL_KHR_shader_subgroup_basic = "GL_KHR_shader_subgroup_basic";
enum string E_GL_KHR_shader_subgroup_vote = "GL_KHR_shader_subgroup_vote";
enum string E_GL_KHR_shader_subgroup_arithmetic = "GL_KHR_shader_subgroup_arithmetic";
enum string E_GL_KHR_shader_subgroup_ballot = "GL_KHR_shader_subgroup_ballot";
enum string E_GL_KHR_shader_subgroup_shuffle = "GL_KHR_shader_subgroup_shuffle";
enum string E_GL_KHR_shader_subgroup_shuffle_relative = "GL_KHR_shader_subgroup_shuffle_relative";
enum string E_GL_KHR_shader_subgroup_rotate = "GL_KHR_shader_subgroup_rotate";
enum string E_GL_KHR_shader_subgroup_clustered = "GL_KHR_shader_subgroup_clustered";
enum string E_GL_KHR_shader_subgroup_quad = "GL_KHR_shader_subgroup_quad";
enum string E_GL_KHR_memory_scope_semantics = "GL_KHR_memory_scope_semantics";
enum string E_GL_KHR_cooperative_matrix = "GL_KHR_cooperative_matrix";

enum string E_GL_EXT_shader_atomic_int64 = "GL_EXT_shader_atomic_int64";

enum string E_GL_EXT_shader_non_constant_global_initializers = "GL_EXT_shader_non_constant_global_initializers";
enum string E_GL_EXT_shader_image_load_formatted = "GL_EXT_shader_image_load_formatted";

enum string E_GL_EXT_shader_16bit_storage = "GL_EXT_shader_16bit_storage";
enum string E_GL_EXT_shader_8bit_storage = "GL_EXT_shader_8bit_storage";

enum TExtensionBehavior {
  EBhMissing = 0,
  EBhRequire,
  EBhEnable,
  EBhWarn,
  EBhDisable,
  EBhDisablePartial
}

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
