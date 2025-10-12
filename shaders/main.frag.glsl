#version 300 es 
precision highp float;

in vec2 imgCoord;
out vec4 pixel;

uniform float u_aspect;
uniform float u_time;

const float EPSILON = 0.0006;
const float FOV = 0.9;

float sdSphere(vec3 p, float s) {
  return length(p) - s;
}

float sdBox(vec3 p, vec3 b) {
  vec3 q = abs(p) - b;
  return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float smin(float a, float b, float k) {
  float h = max(k - abs(a - b), 0.0) / k;
  return min(a, b) - h * h * k * 0.25;
}

mat2 rot2D(float angle) {
  float c = cos(angle);
  float s = sin(angle);
  return mat2(c, -s, s, c);
}

float map(vec3 p) {
  vec3 spherePos = vec3(sin(u_time) * 2.0, 0, 0);

  float sphere = sdSphere(p - spherePos, 1.0);

  vec3 q = p;
  q -= vec3(-2.0, 0.0, 0.0);
  q.xz *= rot2D(u_time * 0.3);

  float box = sdBox(q, vec3(1.0));
  float ground = p.y + 0.7;

  return smin(ground, smin(sphere, box, 0.6), 0.4);
}

void main() {
  // Image coordinates and aspect ratio correction
  vec2 uv = imgCoord * 2.0 - 1.0;
  uv.x *= u_aspect;

  // Initial ray setup
  vec3 ro = vec3(0.0, 0.0, -5);
  vec3 rd = normalize(vec3(uv * FOV, 1.0)); // Ray direction from near to far
  float t = 0.0;
  vec3 col = vec3(0.0);

  // Ray marching loop 
  for(int i = 0; i < 100; i++) {
    vec3 p = ro + rd * t;

    float d = map(p);

    t += d;

    if(d < EPSILON || t > 100.0)
      break;
  }

  col = vec3(t * .04);

  pixel = vec4(col, 1.0);
}