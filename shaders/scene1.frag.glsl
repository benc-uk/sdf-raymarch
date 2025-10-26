#version 300 es 
precision highp float;

//zzzz#include sdflib
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

in vec2 imgCoord;
out vec4 pixel;

uniform float u_time;
uniform vec3 u_cameraPos;
uniform mat4 u_inverseViewProjectionMatrix;

const float EPSILON = 0.006;
const int MAX_MARCHING_STEPS = 128;
const float MAX_VIEW_DISTANCE = 25.0;
const float CHECK_SIZE = 1.3;

const Light LIGHTS[2] = Light[](Light(vec3(5.0, 8.0, 5.0), vec3(1.0, 0.95, 0.9)), Light(vec3(-4.0, 6.0, -3.0), vec3(0.84, 0.53, 0.25)));
const Material MATERIALS[5] = Material[](Material(vec3(0.6, 0.6, 0.6), 1.0, 0.0, 1.0, true, true),      // Ground is grey
Material(vec3(0.83, 0.26, 0.09), 1.0, 0.3, 6.0, false, true),  // Reddish
Material(vec3(0.21, 0.16, 0.88), 1.0, 0.9, 64.0, false, false),// Bluish
Material(vec3(0.1, 0.8, 0.1), 1.0, 1.0, 3.0, false, true),     // Shiny green
Material(vec3(0.19, 0.27, 0.37), 1.0, 0.1, 1.0, false, false)  // Dark metallic grey
);

// This is the red blobby object made up from a sphere and torus
float mapBlobber(vec3 p) {
  vec3 p1 = p;

  p.y -= 0.15;
  float torusD = sdfTorus(p, vec2(0.9, 0.3));

  p1.y -= sin(u_time * 1.3) * 1.1 + 0.8;
  float sphereD = sdfSphere(p1, 0.7);

  return opUnionSm(sphereD, torusD, 0.5);
}

// This is the blue cube with holes and a cylinder on top
float mapCubeThing(vec3 p) {
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

  return opUnionSm(cubeD, cylD, 0.3);
}

// Green spinning crystal made from two octahedrons
float mapCrystal(vec3 p) {
  p += vec3(-2.4, -1.5, 1.0);
  p.xz *= rot2D(u_time);

  vec3 p1 = p;
  p1.xz *= rot2D(0.7);
  float octD1 = sdfOctahedron(p, 0.6);
  float octD2 = sdfOctahedron(p1, 0.6);

  return opUnionSm(octD1, octD2, 0.2);
}

// Metallic frame box
float mapFrame(vec3 p) {
  p += vec3(-2.4, 0.0, 1.0);
  float frameD = sdfBoxFrame(p, vec3(1.0, 1.0, 1.0), 0.1);

  return frameD;
}

// Map function combining all scene objects
// This returns a distance and material ID
Hit map(vec3 p) {
  float d1 = mapBlobber(p);
  float d2 = mapCubeThing(p);
  float d3 = mapCrystal(p);
  float d4 = mapFrame(p);
  float d5 = sdfPlane(p, vec3(0.0, 1.0, 0.0), 0.0); // Ground plane

  float minD = d1;
  int matID = 1; // Red blob material

  if(d2 < minD) {
    minD = d2;
    matID = 2; // Cube thing material 
  }
  if(d3 < minD) {
    minD = d3;
    matID = 3; // Crystal material
  }
  if(d4 < minD) {
    minD = d4;
    matID = 4; // Frame material
  }
  if(d5 < minD) {
    minD = d5;
    matID = 0; // Ground material
  }

  return Hit(minD, matID);
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

  // Ray march through scene objects
  for(int i = 0; i < MAX_MARCHING_STEPS; i++) {
    hit = map(ro + rd * t);
    t += hit.d;

    if(hit.d < EPSILON) {
      hit.d = t;
      break;
    }

    if(t > MAX_VIEW_DISTANCE) {
      hit.d = 1e20;
      hit.matID = -1;
      break;
    }
  }

  return hit;
}

// Soft shadow calculation using penumbra technique
// See https://iquilezles.org/articles/rmshadows/
float calcSoftShadow(vec3 ro, vec3 rd, float mint, float maxt, float k) {
  float res = 1.0;
  float t = mint;
  float ph = 1e20;

  for(int i = 0; i < 64; i++) {
    float h = map(ro + rd * t).d;
    if(h < EPSILON)
      return 0.0; // Hard shadow

    float y = h * h / (2.0 * ph);
    float d = sqrt(h * h - y * y);
    res = min(res, k * d / max(0.0, t - y));
    ph = h;
    t += h;

    if(t >= maxt)
      break;
  }

  return clamp(res, 0.0, 1.0);
}

// Shade a point with material and normal, returns final color with lighting
vec3 shade(vec3 p, vec3 n, vec3 viewDir, Material mat, float distance) {
  // Analytical antialiased checker pattern
  if(mat.isChecker) {
    vec2 uv = p.xz / CHECK_SIZE;
    float filterWidth = distance * 0.002; // Adjust for distance

    // Add the sine functions together and apply filtering
    float checker = sin(uv.x * 6.28318) * sin(uv.y * 6.28318);
    checker = smoothstep(-filterWidth, filterWidth, checker);

    // Apply checker pattern
    mat.color = mix(mat.color, mat.color * 0.3, checker * 0.8);
  }

  vec3 col = vec3(0.06, 0.06, 0.06) * mat.color; // Ambient light

  // Loop through lights
  for(int i = 0; i < LIGHTS.length(); i++) {
    vec3 lightPos = LIGHTS[i].position;
    vec3 lightCol = LIGHTS[i].color;

    // Light direction & distance
    vec3 lightDir = normalize(lightPos - p);
    float lightDist = length(lightPos - p);

    // Soft shadow factor (penumbra sphere tracing). Offset start to reduce self-shadowing acne.
    float shadowFactor = calcSoftShadow(p + n * EPSILON * 6.0, lightDir, EPSILON, lightDist, 32.0);

    // Classic diffuse shading
    float diff = max(dot(n, lightDir), 0.0) * mat.diffuse * shadowFactor;
    col += mat.color * diff * lightCol;

    // Specular highlight using basic Blinn-Phong model
    vec3 reflectDir = reflect(-lightDir, n);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), mat.hardness);
    col += vec3(1.0) * spec * mat.specular * shadowFactor * lightCol;
  }

  return col;
}

void main() {
  vec4 worldPos = u_inverseViewProjectionMatrix * vec4(imgCoord.xy, 0.0, 1.0);
  worldPos /= worldPos.w; // Perspective

  // Our ray origin and direction
  vec3 ro = u_cameraPos;
  vec3 rd = normalize(worldPos.xyz - ro);

  // Start raycasting
  Hit hit = raycast(ro, rd);

  // Output colour for this pixel
  vec3 col = vec3(0.0);

  // Projected hit position at distance along ray
  vec3 p = ro + rd * hit.d;

  // If we hit something, calculate illumination and shading
  if(hit.matID != -1) {
    vec3 n;
    Material mat = MATERIALS[hit.matID];

    // Get normal, we can speed things up a litte for the ground plane
    if(hit.matID == 0) {
      n = vec3(0.0, 1.0, 0.0);
    } else {
      n = getNormal(p);
    }

    // Shade the point using the shade function
    vec3 viewDir = normalize(ro - p);
    col = shade(p, n, viewDir, mat, hit.d);

    // Reflection for reflective materials, needs more rays!
    for(int i = 0; i < LIGHTS.length(); i++) {
      if(mat.isReflective) {
        vec3 reflectDir = reflect(rd, n);
        Hit reflectHit = raycast(p + n * EPSILON * 10.0, reflectDir);
        if(reflectHit.matID != -1) {
          vec3 reflectP = p + reflectDir * reflectHit.d;
          vec3 reflectN = getNormal(reflectP);
          Material reflectMat = MATERIALS[reflectHit.matID];

          // Use shade() for reflection calculation
          vec3 reflectViewDir = normalize(p - reflectP);
          vec3 reflectCol = shade(reflectP, reflectN, reflectViewDir, reflectMat, reflectHit.d);
          col += reflectCol * 0.3;
        }
      }
    }
  }

  // Phew! Set the final pixel colour
  pixel = vec4(col, 1.0);
}