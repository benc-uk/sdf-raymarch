struct Hit {
  float d;
  int matID;
};

struct Material {
  vec3 color;
  float diffuse;
  float specular;
  float hardness;
  bool isChecker;
  bool isReflective;
};

struct Light {
  vec3 position;
  vec3 color;
};

float sdfPlane(vec3 p, vec3 n, float h) {
  return dot(p, n) + h; // n must be normalized
}

float sdfSphere(vec3 p, float s) {
  return length(p) - s;
}

float sdfCube(vec3 p, vec3 b) {
  vec3 q = abs(p) - b;
  return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float sdfCylinder(vec3 p, vec2 h) {
  vec2 d = abs(vec2(length(p.xz), p.y)) - h;
  return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

float sdfCubeRound(vec3 p, vec3 b, float r) {
  vec3 q = abs(p) - b;
  return length(max(q, 0.0)) - r + min(max(q.x, max(q.y, q.z)), 0.0);
}

float sdfBoxFrame(vec3 p, vec3 b, float e) {
  p = abs(p) - b;
  vec3 q = abs(p + e) - e;
  return min(min(length(max(vec3(p.x, q.y, q.z), 0.0)) + min(max(p.x, max(q.y, q.z)), 0.0), length(max(vec3(q.x, p.y, q.z), 0.0)) + min(max(q.x, max(p.y, q.z)), 0.0)), length(max(vec3(q.x, q.y, p.z), 0.0)) + min(max(q.x, max(q.y, p.z)), 0.0));
}

float sdfTorus(vec3 p, vec2 t) {
  vec2 q = vec2(length(p.xz) - t.x, p.y);
  return length(q) - t.y;
}

float sdfOctahedron(vec3 p, float s) {
  p = abs(p);
  float m = p.x + p.y + p.z - s;
  vec3 q;
  if(3.0 * p.x < m)
    q = p.xyz;
  else if(3.0 * p.y < m)
    q = p.yzx;
  else if(3.0 * p.z < m)
    q = p.zxy;
  else
    return m * 0.57735027;
  float k = clamp(0.5 * (q.z - q.y + s), 0.0, s);
  return length(vec3(q.x, q.y - s + k, q.z - k));
}

float opUnionSm(float d1, float d2, float k) {
  float h = max(k - abs(d1 - d2), 0.0) / k;
  return min(d1, d2) - h * h * k * 0.25;
}

float opSubSm(float d1, float d2, float k) {
  return -opUnionSm(-d2, d1, k);
}

float opSub(float d1, float d2) {
  return max(-d1, d2);
}

mat2 rot2D(float angle) {
  float c = cos(angle);
  float s = sin(angle);
  return mat2(c, -s, s, c);
}