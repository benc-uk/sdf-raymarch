#version 300 es 
precision highp float;

in vec2 imgCoord;
out vec4 pixel;

uniform mat4 u_inverseViewProjectionMatrix;
uniform vec3 u_camPos;
uniform float u_sphereData[24]; // 3 spheres * 8 floats per sphere
uniform int u_numSpheres;
uniform vec3 u_lightDir;
uniform float u_ambientStrength;
uniform float u_specularPower;
uniform float u_specularStrength;
uniform vec3 u_bgColorTop;
uniform vec3 u_bgColorBottom;

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

// Hit information structure
struct HitInfo {
  bool hit;
  float t;
  vec3 point;
  vec3 normal;
  vec3 color;
};

// Helper to extract sphere data from uniform array
void getSphereData(int index, out vec3 center, out float radius, out vec3 color) {
  int offset = index * 8;
  center = vec3(u_sphereData[offset], u_sphereData[offset + 1], u_sphereData[offset + 2]);
  radius = u_sphereData[offset + 3];
  color = vec3(u_sphereData[offset + 4], u_sphereData[offset + 5], u_sphereData[offset + 6]);
}

// Ray-sphere intersection
// Returns distance along ray, or -1.0 if no hit
float intersectSphere(vec3 ro, vec3 rd, vec3 sphereCenter, float sphereRadius) {
  vec3 oc = ro - sphereCenter;
  float a = dot(rd, rd);
  float b = 2.0 * dot(oc, rd);
  float c = dot(oc, oc) - sphereRadius * sphereRadius;
  float discriminant = b * b - 4.0 * a * c;

  if(discriminant < 0.0) {
    return -1.0; // No intersection
  }

  float t = (-b - sqrt(discriminant)) / (2.0 * a);
  return t > 0.0 ? t : -1.0;
}

// Intersect ray with all spheres and return closest hit
HitInfo intersectScene(vec3 ro, vec3 rd) {
  HitInfo closestHit;
  closestHit.hit = false;
  closestHit.t = 1e10; // Large number

  for(int i = 0; i < u_numSpheres; i++) {
    vec3 center;
    float radius;
    vec3 color;
    getSphereData(i, center, radius, color);

    float t = intersectSphere(ro, rd, center, radius);

    if(t > 0.0 && t < closestHit.t) {
      closestHit.hit = true;
      closestHit.t = t;
      closestHit.point = ro + rd * t;
      closestHit.normal = normalize(closestHit.point - center);
      closestHit.color = color;
    }
  }

  return closestHit;
}

void main() {
  // Convert image coordinates to NDC [-1, 1]
  vec2 uv = imgCoord * 2.0 - 1.0;

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

  // Intersect ray with all spheres
  HitInfo hit = intersectScene(ro, rd);

  if(hit.hit) {
    // Simple lighting
    vec3 lightDir = normalize(u_lightDir);
    float diffuse = max(dot(hit.normal, lightDir), 0.0);
    float ambient = u_ambientStrength;

    // Add specular highlight
    vec3 viewDir = normalize(-rd);
    vec3 reflectDir = reflect(-lightDir, hit.normal);
    float specular = pow(max(dot(viewDir, reflectDir), 0.0), u_specularPower) * u_specularStrength;

    vec3 color = hit.color * (diffuse + ambient) + vec3(specular);
    pixel = vec4(color, 1.0);
  } else {
    // Background color (uv.y = -1 at bottom, +1 at top)
    vec3 bgColor = mix(u_bgColorBottom, u_bgColorTop, uv.y * 0.5 + 0.5);
    pixel = vec4(bgColor, 1.0);
  }
}