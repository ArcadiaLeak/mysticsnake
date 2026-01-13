import sdl;
import shader;
import vulkan;

import std.string;
import std.stdio;

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
  auto vertMetadata = SDL_ShaderCross_ReflectGraphicsSPIRV(
    cast(const(ubyte)*) vertShaderCode,
    vertShaderCode.length * uint.sizeof,
    0
  );
  auto vertSpirvInfo = SDL_ShaderCross_SPIRV_Info(
    cast(const(ubyte)*) vertShaderCode,
    vertShaderCode.length * uint.sizeof,
    "main",
    SDL_ShaderCross_ShaderStage.SDL_SHADERCROSS_SHADERSTAGE_VERTEX,
    0
  );
  auto vertexShader = SDL_ShaderCross_CompileGraphicsShaderFromSPIRV(
    device,
    &vertSpirvInfo,
    &vertMetadata.resource_info,
    0
  );
  SDL_free(vertMetadata);

  writeln(vertexShader);
  SDL_ReleaseGPUShader(device, vertexShader);

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
  auto fragSpirvInfo = SDL_ShaderCross_SPIRV_Info(
    cast(const(ubyte)*) fragShaderCode,
    fragShaderCode.length * uint.sizeof,
    "main",
    SDL_ShaderCross_ShaderStage.SDL_SHADERCROSS_SHADERSTAGE_FRAGMENT,
    0
  );
  auto fragShader = SDL_ShaderCross_CompileGraphicsShaderFromSPIRV(
    device,
    &fragSpirvInfo,
    &fragMetadata.resource_info,
    0
  );
  SDL_free(fragMetadata);

  writeln(fragShader);
  SDL_ReleaseGPUShader(device, fragShader);

  glslangFinalize();
}
