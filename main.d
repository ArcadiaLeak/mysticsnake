import sdl;
import shader;
import vulkan;

import std.string;
import std.stdio;

void createVertexShader() {
  string vertexShaderSource =
    "#version 310 es\n" ~
    "precision highp float;\n" ~
    "\n" ~
    "layout(location = 0) in vec3 inPosition;\n" ~
    "\n" ~
    "layout(std140, binding = 0) uniform UniformBufferObject {\n" ~
    "  mat4 model;\n" ~
    "  mat4 view;\n" ~
    "  mat4 proj;\n" ~
    "} ubo;\n" ~
    "\n" ~
    "void main() {\n" ~
    "  gl_Position = ubo.proj * ubo.view * ubo.model * vec4(inPosition, 1.0);\n" ~
    "}\n";

  auto vertShaderCode = compileGLSLtoSPIRV(
    vertexShaderSource,
    "cube.vert",
    true
  );

  auto vertexMetadata = SDL_ShaderCross_ReflectGraphicsSPIRV(
    cast(const(ubyte)*) vertShaderCode,
    vertShaderCode.length * uint.sizeof,
    0
  );
  scope(exit) SDL_free(vertexMetadata);

  writeln(vertexMetadata.resource_info.num_samplers);
  writeln(vertexMetadata.resource_info.num_storage_textures);
  writeln(vertexMetadata.resource_info.num_storage_buffers);
  writeln(vertexMetadata.resource_info.num_uniform_buffers);
}

void createFragmentShader() {
  string fragmentShaderSource =
    "#version 310 es\n" ~
    "precision highp float;\n" ~
    "\n" ~
    "layout(location = 0) out vec4 outColor;\n" ~
    "\n" ~
    "void main() {\n" ~
    "  outColor = vec4(1.0, 0.5, 0.2, 1.0);\n" ~
    "}\n";

  auto fragShaderCode = compileGLSLtoSPIRV(
    fragmentShaderSource,
    "cube.frag",
    false
  );

  auto fragMetadata = SDL_ShaderCross_ReflectGraphicsSPIRV(
    cast(const(ubyte)*) fragShaderCode,
    fragShaderCode.length * uint.sizeof,
    0
  );
  scope(exit) SDL_free(fragMetadata);

  writeln(fragMetadata.resource_info.num_samplers);
  writeln(fragMetadata.resource_info.num_storage_textures);
  writeln(fragMetadata.resource_info.num_storage_buffers);
  writeln(fragMetadata.resource_info.num_uniform_buffers);
}

void main() {
  SDL_Init(SDL_INIT_VIDEO);
  scope(exit) SDL_Quit();

  SDL_GPUDevice* device = SDL_CreateGPUDevice(
		SDL_GPU_SHADERFORMAT_SPIRV,
		true,
		null
  );
  scope(exit) SDL_DestroyGPUDevice(device);

  SDL_Window* window = SDL_CreateWindow(
    "Heuristic Graphic",
    640,
    480,
    0
  );
  scope(exit) SDL_DestroyWindow(window);

  SDL_ClaimWindowForGPUDevice(device, window);
  scope(exit) SDL_ReleaseWindowFromGPUDevice(device, window);

  glslangInitialize();
  scope(exit) glslangFinalize();

  createVertexShader();
  createFragmentShader();
}
