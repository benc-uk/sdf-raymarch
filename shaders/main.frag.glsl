#version 300 es 
precision highp float;

in vec2 imgCoord;
out vec4 pixel;

uniform float u_aspect;
uniform float u_time;
uniform vec3 u_lightPos;

const float EPSILON = 0.0002;
const float FOV = 0.5;

float sdSphere(vec3 p, float s) {
  return length(p) - s;
}

float sdBox(vec3 p, vec3 b) {
  vec3 q = abs(p) - b;
  return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float sdTorus(vec3 p, vec2 t) {
  vec2 q = vec2(length(p.xz) - t.x, p.y);
  return length(q) - t.y;
}

float opSmoothUnion(float a, float b, float k) {
  float h = max(k - abs(a - b), 0.0) / k;
  return min(a, b) - h * h * k * 0.25;
}

float opSmoothSubtraction(float d1, float d2, float k) {
  return -opSmoothUnion(-d1, d2, k);
}

mat2 rot2D(float angle) {
  float c = cos(angle);
  float s = sin(angle);
  return mat2(c, -s, s, c);
}

float map(vec3 p) {
  vec3 spherePos = vec3(sin(u_time) * 2.0, 0.3 + cos(u_time * 3.) * 0.4, 0);
  float sphere = sdSphere(p - spherePos, 1.0);

  vec3 v = p - vec3(2.2, 1.0, 0.0);
  v.xy *= rot2D(u_time * 0.5);
  float torus = sdTorus(v, vec2(1.2, 0.38));

  vec3 q = p;
  q -= vec3(-2.0, 0.0, 0.0);
  q.xz *= rot2D(u_time * 0.378);

  float box = sdBox(q, vec3(1.0));
  float ground = p.y + 0.7;

  vec3 sphere2Pos = vec3(0.0, 0.0, -2.0 + sin(u_time * 0.5) * 1.0);
  float sphere2 = sdSphere(p - sphere2Pos, 1.3);

  return opSmoothUnion(opSmoothSubtraction(ground, sphere2, 0.3), opSmoothUnion(torus, opSmoothUnion(sphere, box, 0.25), 0.5), 0.6);
}

vec3 getNormal(vec3 p) {
  const float h = 0.00001;
  const vec2 k = vec2(1, -1);
  return normalize(k.xyy * map(p + k.xyy * h) +
    k.yyx * map(p + k.yyx * h) +
    k.yxy * map(p + k.yxy * h) +
    k.xxx * map(p + k.xxx * h));
}

void main() {
  // Image coordinates and aspect ratio correction
  vec2 uv = imgCoord * 2.0 - 1.0;
  uv.x *= u_aspect;

  // Initial ray setup
  vec3 ro = vec3(0.0, 0.0, -6);
  vec3 rd = normalize(vec3(uv * FOV, 1.0)); // Ray direction from near to far
  float t = 0.0;
  vec3 col = vec3(0.0);
  vec3 p = vec3(0.0);

  // Ray marching loop 
  for(int i = 0; i < 100; i++) {
    p = ro + rd * t;

    float d = map(p);

    t += d;

    if(d < EPSILON || t > 100.0)
      break;
  }

  if(t < 100.0) {
    vec3 n = getNormal(p);

    // Light direction
    vec3 lightDir = normalize(u_lightPos - p);
    float diff = max(dot(n, lightDir), 0.0);

    // Simple shading based on normal and light direction
    col = vec3(0.2, 0.7, 0.1) * diff;

    // specular highlight
    vec3 viewDir = normalize(ro - p);
    vec3 reflectDir = reflect(-lightDir, n);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), 16.0);
    col += vec3(0.7) * spec;

    // Add some ambient light
    col += vec3(0.05, 0.03, 0.1);
  } else {
    // Background color
    col = vec3(0.0);
  }

  pixel = vec4(col, 1.0);
}