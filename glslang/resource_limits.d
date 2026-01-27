module glslang.resource_limits;

struct TLimits {
  bool nonInductiveForLoops = 1;
  bool whileLoops = 1;
  bool doWhileLoops = 1;
  bool generalUniformIndexing = 1;
  bool generalAttributeMatrixVectorIndexing = 1;
  bool generalVaryingIndexing = 1;
  bool generalSamplerIndexing = 1;
  bool generalVariableIndexing = 1;
  bool generalConstantMatrixVectorIndexing = 1;
}

struct TBuiltInResourceRec {
  int maxLights = 32;
  int maxClipPlanes = 6;
  int maxTextureUnits = 32;
  int maxTextureCoords = 32;
  int maxVertexAttribs = 64;
  int maxVertexUniformComponents = 4096;
  int maxVaryingFloats = 64;
  int maxVertexTextureImageUnits = 32;
  int maxCombinedTextureImageUnits = 80;
  int maxTextureImageUnits = 32;
  int maxFragmentUniformComponents = 4096;
  int maxDrawBuffers = 32;
  int maxVertexUniformVectors = 128;
  int maxVaryingVectors = 8;
  int maxFragmentUniformVectors = 16;
  int maxVertexOutputVectors = 16;
  int maxFragmentInputVectors = 15;
  int minProgramTexelOffset = -8;
  int maxProgramTexelOffset = 7;
  int maxClipDistances = 8;
  int maxComputeWorkGroupCountX = 65535;
  int maxComputeWorkGroupCountY = 65535;
  int maxComputeWorkGroupCountZ = 65535;
  int maxComputeWorkGroupSizeX = 1024;
  int maxComputeWorkGroupSizeY = 1024;
  int maxComputeWorkGroupSizeZ = 64;
  int maxComputeUniformComponents = 1024;
  int maxComputeTextureImageUnits = 16;
  int maxComputeImageUniforms = 8;
  int maxComputeAtomicCounters = 8;
  int maxComputeAtomicCounterBuffers = 1;
  int maxVaryingComponents = 60;
  int maxVertexOutputComponents = 64;
  int maxGeometryInputComponents = 64;
  int maxGeometryOutputComponents = 128;
  int maxFragmentInputComponents = 128;
  int maxImageUnits = 8;
  int maxCombinedImageUnitsAndFragmentOutputs = 8;
  int maxCombinedShaderOutputResources = 8;
  int maxImageSamples = 0;
  int maxVertexImageUniforms = 0;
  int maxTessControlImageUniforms = 0;
  int maxTessEvaluationImageUniforms = 0;
  int maxGeometryImageUniforms = 0;
  int maxFragmentImageUniforms = 8;
  int maxCombinedImageUniforms = 8;
  int maxGeometryTextureImageUnits = 16;
  int maxGeometryOutputVertices = 256;
  int maxGeometryTotalOutputComponents = 1024;
  int maxGeometryUniformComponents = 1024;
  int maxGeometryVaryingComponents = 64;
  int maxTessControlInputComponents = 128;
  int maxTessControlOutputComponents = 128;
  int maxTessControlTextureImageUnits = 16;
  int maxTessControlUniformComponents = 1024;
  int maxTessControlTotalOutputComponents = 4096;
  int maxTessEvaluationInputComponents = 128;
  int maxTessEvaluationOutputComponents = 128;
  int maxTessEvaluationTextureImageUnits = 16;
  int maxTessEvaluationUniformComponents = 1024;
  int maxTessPatchComponents = 120;
  int maxPatchVertices = 32;
  int maxTessGenLevel = 64;
  int maxViewports = 16;
  int maxVertexAtomicCounters = 0;
  int maxTessControlAtomicCounters = 0;
  int maxTessEvaluationAtomicCounters = 0;
  int maxGeometryAtomicCounters = 0;
  int maxFragmentAtomicCounters = 8;
  int maxCombinedAtomicCounters = 8;
  int maxAtomicCounterBindings = 1;
  int maxVertexAtomicCounterBuffers = 0;
  int maxTessControlAtomicCounterBuffers = 0;
  int maxTessEvaluationAtomicCounterBuffers = 0;
  int maxGeometryAtomicCounterBuffers = 0;
  int maxFragmentAtomicCounterBuffers = 1;
  int maxCombinedAtomicCounterBuffers = 1;
  int maxAtomicCounterBufferSize = 16384;
  int maxTransformFeedbackBuffers = 4;
  int maxTransformFeedbackInterleavedComponents = 64;
  int maxCullDistances = 8;
  int maxCombinedClipAndCullDistances = 8;
  int maxSamples = 4;
  int maxMeshOutputVerticesNV = 256;
  int maxMeshOutputPrimitivesNV = 512;
  int maxMeshWorkGroupSizeX_NV = 32;
  int maxMeshWorkGroupSizeY_NV = 1;
  int maxMeshWorkGroupSizeZ_NV = 1;
  int maxTaskWorkGroupSizeX_NV = 32;
  int maxTaskWorkGroupSizeY_NV = 1;
  int maxTaskWorkGroupSizeZ_NV = 1;
  int maxMeshViewCountNV = 4;
  int maxMeshOutputVerticesEXT = 256;
  int maxMeshOutputPrimitivesEXT = 256;
  int maxMeshWorkGroupSizeX_EXT = 128;
  int maxMeshWorkGroupSizeY_EXT = 128;
  int maxMeshWorkGroupSizeZ_EXT = 128;
  int maxTaskWorkGroupSizeX_EXT = 128;
  int maxTaskWorkGroupSizeY_EXT = 128;
  int maxTaskWorkGroupSizeZ_EXT = 128;
  int maxMeshViewCountEXT = 4;
  int maxDualSourceDrawBuffersEXT = 1;

  TLimits limits;
}

immutable class TBuiltInResource {
  private TBuiltInResourceRec rec;

  alias rec this;
}

static DefaultTBuiltInResource = new TBuiltInResource;
