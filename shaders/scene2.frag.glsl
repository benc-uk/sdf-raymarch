#version 300 es 
precision highp float;

//#include sdflib

in vec2 imgCoord;
out vec4 pixel;

uniform float u_time;
uniform vec3 u_cameraPos;
uniform mat4 u_inverseViewProjectionMatrix;

const float EPSILON = 0.006;
const int MAX_MARCHING_STEPS = 128;
const float MAX_VIEW_DISTANCE = 25.0;
const float CHECK_SIZE = 1.3;

const Light LIGHTS[2] = Light[](Light(vec3(5.0, 8.0, 5.0), vec3(0.67, 0.97, 0.97)), Light(vec3(-4.0, 6.0, -3.0), vec3(1.0, 0.79, 0.61)));
const Material MATERIALS[3] = Material[](Material(vec3(0.34, 0.09, 0.17), 1.0, 0.0, 1.0, false, false),  // floor reddish
Material(vec3(0.9, 0.9, 0.95), 0.6, 0.8, 164.0, false, false), // china like
Material(vec3(0.22, 0.57, 0.11), 1.0, 1.0, 100.0, false, true));  // green slime

float mapCup(vec3 p) {
  float outer = sdfCutHollowSphere(p + vec3(0.0, -2.8, 0.0), 1.8, -0.3, 0.02);

  float ridge = sdfTorus(p + vec3(0.0, -2.4, 0.0), vec2(1.8, 0.05));
  outer = opUnionSm(outer, ridge, 0.1);

  // carve out dimples using sdfSphere and opSubSm
  for(int i = 0; i < 8; i++) {
    float angle = float(i) / 8.0 * 6.28318;
    float r = 1.3;
    vec3 dimplePos = vec3(cos(angle) * r, 1.9, sin(angle) * r);
    float dimple = sdfSphere(p - dimplePos, 0.35);
    outer = opUnionSm(dimple, outer, 0.3);
  }

  float stem = sdfCylinder(p + vec3(0.0, 0.0, 0.0), vec2(0.5, 1.0));
  float base = sdfTorus(p, vec2(0.61, 0.15));
  stem = opUnionSm(stem, base, 0.2);

  return opUnionSm(outer, stem, 0.2);
}

float mapSlime(vec3 p) {
  float surf = sdfCylinder(p + vec3(0.0, -2.35, 0.0), vec2(1.75, 0.01));

  // bubbles rising and falling
  vec3 p1 = p;
  p1 += vec3(0.0, sin(u_time * 3.2) * 1.1 - 2.9, 0.8);
  float bubble1 = sdfSphere(p1, 0.25);

  vec3 p2 = p;
  p2 += vec3(1.0, sin(0.4 + u_time * 3.1) * 1.0 - 3.0, -0.2);
  float bubble2 = sdfSphere(p2, 0.12);

  vec3 p3 = p;
  p3 += vec3(-1.2, cos(3.0 + u_time * 2.9) * 1.2 - 3.1, 0.4);
  float bubble3 = sdfSphere(p3, 0.18);

  vec3 p4 = p;
  p4 += vec3(-0.3, sin(1.5 + u_time * 3.3) * 1.0 - 2.8, -0.9);
  float bubble4 = sdfSphere(p4, 0.31);

  float bubbles = min(bubble1, min(bubble2, min(bubble3, bubble4)));

  return opUnionSm(surf, bubbles, 0.4);
}

// Map function combining all scene objects
// This returns a distance and material ID
Hit map(vec3 p) {
  float d1 = sdfPlane(p, vec3(0.0, 1.0, 0.0), 0.0); // Ground plane
  float d2 = mapCup(p);
  float d3 = mapSlime(p);

  float minD = 1e20;
  int matID = -1;

  if(d1 < minD) {
    minD = d1;
    matID = 0; // Ground material
  }
  if(d2 < minD) {
    minD = d2;
    matID = 1; // Cup material
  }
  if(d3 < minD) {
    minD = d3;
    matID = 2; // Slime material
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