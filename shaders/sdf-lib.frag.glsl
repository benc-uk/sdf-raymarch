float sdSphere(vec3 p, float s) {
  return length(p) - s;
}

float sdfCube(vec3 p, vec3 b) {
  vec3 q = abs(p) - b;
  return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float sdfTorus(vec3 p, vec2 t) {
  vec2 q = vec2(length(p.xz) - t.x, p.y);
  return length(q) - t.y;
}

float opUnionSm(float a, float b, float k) {
  float h = max(k - abs(a - b), 0.0) / k;
  return min(a, b) - h * h * k * 0.25;
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
