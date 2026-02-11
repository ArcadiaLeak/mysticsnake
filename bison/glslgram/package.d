module bison.glslgram;

import bison.glslgram.glslnterm;
import bison.glslgram.glsltoken;

auto glslgram() {
  glsltoken();
  glslnterm();
}
