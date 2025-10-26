#version 300 es
precision highp float;

// Most basic vertex shader for rendering a full-screen quad

in vec4 position;
out vec2 imgCoord;   // NDC coordinates [-1,-1] to [1,1] for use in fragment shader

void main() {
  gl_Position = position;
  imgCoord = position.xy;
}