#version 300 es
precision highp float;

// Most basic vertex shader for rendering a full-screen quad

in vec4 position;
out vec2 imgCoord;   // Pre-normalized image coordinates [0, 1]
void main() {
  gl_Position = position;
  imgCoord = position.xy * 0.5 + 0.5;
}