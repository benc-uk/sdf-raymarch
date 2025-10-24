#version 300 es 
precision highp float;

in vec2 imgCoord;
out vec4 pixel;

uniform float u_time;
uniform vec3 u_cameraPos;
uniform mat4 u_inverseViewProjectionMatrix;

const vec3 lightPos = vec3(15.0, 19.0, 15.0);
const float EPSILON = 0.006;
const int MAX_MAT = 10;

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
};

Material materials[MAX_MAT];

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

Hit mapThing1(vec3 p) {
  vec3 p1 = p;
  p1.y -= 0.15;
  float torusD = sdfTorus(p1, vec2(0.9, 0.3));

  vec3 p2 = p;
  p2.y -= sin(u_time * 2.5) * 0.7 + 1.2;
  float sphereD = sdfSphere(p2, 0.7);

  float d = opUnionSm(sphereD, torusD, 0.5);

  return Hit(d, 1);
}

Hit mapThing2(vec3 p) {
  p += vec3(2.0, -0.59, 0.8);
  float cubeD = sdfCubeRound(p, vec3(0.5), 0.13);

  vec3 p1 = p;
  p1.y -= 1.4;
  float cylD = sdfCylinder(p1, vec2(0.3, 1.0));

  // carve four spheres from the sides of the cube with subtract
  vec3 hole1Pos = p - vec3(0.5, 0.0, 0.0);
  vec3 hole2Pos = p - vec3(-0.5, 0.0, 0.0);
  vec3 hole3Pos = p - vec3(0.0, 0.0, 0.5);
  vec3 hole4Pos = p - vec3(0.0, 0.0, -0.5);
  float holeRadius = 0.4;
  cubeD = opSub(sdfSphere(hole1Pos, holeRadius), cubeD);
  cubeD = opSub(sdfSphere(hole2Pos, holeRadius), cubeD);
  cubeD = opSub(sdfSphere(hole3Pos, holeRadius), cubeD);
  cubeD = opSub(sdfSphere(hole4Pos, holeRadius), cubeD);

  return Hit(opUnionSm(cubeD, cylD, 0.3), 2);
}

// Combined mapping for normal calculation (used only when we know we hit an object)
Hit map(vec3 p) {
  Hit hit1 = mapThing1(p);
  Hit hit2 = mapThing2(p);

  if(hit1.d < hit2.d) {
    return hit1;
  } else {
    return hit2;
  }
}

vec3 getNormal(vec3 p) {
  vec2 k = vec2(1.0, -1.0) * 0.5773 * 0.0005;
  return normalize(k.xyy * map(p + k.xyy).d +
    k.yyx * map(p + k.yyx).d +
    k.yxy * map(p + k.yxy).d +
    k.xxx * map(p + k.xxx).d);
}

Hit raycast(vec3 ro, vec3 rd) {
  float t = 0.0;
  Hit hit = Hit(0.0, -1);
  Hit groundHit = Hit(1000.0, -1);

  // raytrace floor plane
  float floorD = (0.0 - ro.y) / rd.y;
  if(floorD > 0.0) {
    groundHit.d = floorD;
    groundHit.matID = 0;
  }

  // Ray march through scene objects
  for(int i = 0; i < 90; i++) {
    hit = map(ro + rd * t);
    t += hit.d;

    if(hit.d < EPSILON) {
      hit.d = t;
      break;
    }

    if(t > 150.0) {
      hit.matID = -1;
      break;
    }
  }

  // Choose the closest hit between ground and objects
  if(hit.matID == -1 || groundHit.d < hit.d) {
    return groundHit;
  }

  return hit;
}

// Soft shadow calculation using penumbra technique
float calcSoftShadow(vec3 ro, vec3 rd, float mint, float maxt, float k) {
  float res = 1.0;
  float t = mint;
  float ph = 1.0; // Previous step height

  for(int i = 0; i < 32; i++) {
    Hit h = map(ro + rd * t);
    if(h.d < EPSILON) {
      return 0.0; // Hard shadow
    }

    // Improved penumbra calculation that reduces artifacts from overlapping shadows
    float y = h.d * h.d / (2.0 * ph);
    float d = sqrt(h.d * h.d - y * y);
    res = min(res, k * d / max(0.0, t - y));
    ph = h.d;

    t += h.d;

    if(t >= maxt)
      break;
  }

  return clamp(res, 0.0, 1.0);
}

void main() {
  materials[0] = Material(vec3(0.6, 0.6, 0.6), 0.99, 0.0, 1.0, true); // Ground
  materials[1] = Material(vec3(0.83, 0.26, 0.09), 0.99, 0.3, 6.0, false); // Greenish
  materials[2] = Material(vec3(0.21, 0.16, 0.88), 0.99, 0.9, 64.0, false); // Bluish

  // Initial ray setup  
  // Image coordinates - convert from [0,1] to [-1,1] NDC space
  vec2 uv = imgCoord * 2.0 - 1.0;
  vec4 ndc = vec4(uv, 0.0, 1.0);
  vec4 worldPos = u_inverseViewProjectionMatrix * ndc;
  worldPos /= worldPos.w;
  vec3 ro = u_cameraPos;
  vec3 rd = normalize(worldPos.xyz - ro);

  // Start raycasting
  Hit hit = raycast(ro, rd);

  vec3 col = vec3(0.0);
  vec3 p = ro + rd * hit.d;

  if(hit.matID != -1) {
    vec3 n;

    if(hit.matID == 0) {
      n = vec3(0.0, 1.0, 0.0);
    } else {
      n = getNormal(p);
    }

    Material mat = materials[hit.matID];

    if(mat.isChecker) {
      float checkerSize = 0.4;
      float checkX = floor(p.x / checkerSize);
      float checkZ = floor(p.z / checkerSize);
      if(mod(checkX + checkZ, 2.0) < 1.0) {
        mat.color *= 0.4;
      }
    }

    // Add some ambient light
    col += vec3(0.05, 0.05, 0.05);

    // Soft shadow calculation
    vec3 shadowRayDir = normalize(lightPos - p);
    float lightDistance = length(lightPos - p);
    float shadowFactor = calcSoftShadow(p + n * EPSILON * 4.0, shadowRayDir, 0.02, lightDistance, 8.0);

    // Light direction
    vec3 lightDir = normalize(lightPos - p);
    float diff = max(dot(n, lightDir), 0.0) * mat.diffuse * shadowFactor;

    // Simple shading based on normal and light direction
    col += mat.color * diff;

    // specular highlight
    vec3 viewDir = normalize(ro - p);
    vec3 reflectDir = reflect(-lightDir, n);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), mat.hardness);
    col += vec3(0.7) * spec * mat.specular * shadowFactor;
  }

  pixel = vec4(col, 1.0);
}