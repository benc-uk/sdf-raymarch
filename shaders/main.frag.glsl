#version 300 es 
precision highp float;

in vec2 imgCoord;
out vec4 pixel;

uniform mat4 u_inverseViewProjectionMatrix;
uniform vec3 u_camPos;
uniform float u_aspect;

float dot2(in vec2 v) {
  return dot(v, v);
}
float dot2(in vec3 v) {
  return dot(v, v);
}
float ndot(in vec2 a, in vec2 b) {
  return a.x * b.x - a.y * b.y;
}

float sdSphere(vec3 p, float s) {
  return length(p) - s;
}

vec3 palette(float t) {
  //[[0.500 0.500 0.500] [0.666 0.666 0.666] [1.000 1.000 1.000] [0.000 0.333 0.667]]
  vec3 a = vec3(0.500, 0.500, 0.100);
  vec3 b = vec3(0.666, 0.666, 0.666);
  vec3 c = vec3(1.000, 1.000, 1.000);
  vec3 d = vec3(0.000, 0.833, 0.667);
  return a + b * cos(6.28318 * (c * t + d));
}

void main() {
  // Convert image coordinates to NDC [-1, 1]
  vec2 uv = imgCoord * 2.0 - 1.0;
  uv.x *= u_aspect;

  // Use inverse view-projection matrix to compute ray direction
  // Create points in clip space (near and far plane)
  vec4 nearPoint = vec4(uv, -1.0, 1.0); // Near plane in NDC
  vec4 farPoint = vec4(uv, 1.0, 1.0);   // Far plane in NDC

  // Transform to world space
  vec4 nearWorld = u_inverseViewProjectionMatrix * nearPoint;
  vec4 farWorld = u_inverseViewProjectionMatrix * farPoint;

  // Perspective divide
  nearWorld /= nearWorld.w;
  farWorld /= farWorld.w;

  // Ray setup
  vec3 ro = u_camPos; // Ray origin at camera position
  vec3 rd = normalize(farWorld.xyz - nearWorld.xyz); // Ray direction from near to far

  float d = length(uv * 2.2);
  vec3 col = palette(d);
  pixel = vec4(col, 1.0);
}