#version 300 es 
precision highp float;

#include sdflib

in vec2 imgCoord;
out vec4 pixel;

uniform float u_time;
uniform vec3 u_cameraPos;
uniform mat4 u_inverseViewProjectionMatrix;

const float EPSILON = 0.006;
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

  p1.y -= sin(u_time * 2.5) * 0.7 + 1.2;
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
  Hit hit = Hit(1e20, -1);

  // Ray march through scene objects
  for(int i = 0; i < 100; i++) {
    hit = map(ro + rd * t);
    t += hit.d;

    if(hit.d < EPSILON) {
      hit.d = t;
      break;
    }

    if(t > 20.0) {
      hit.d = 1e20;
      hit.matID = -1;
      break;
    }
  }

  // Raytrace floor without SDF, it's just a plane at y=0
  // For reasons I don't fully understand treating the ground as an SDF causes problems
  float floorD = (0.0 - ro.y) / rd.y;

  // Check if floor is closer than other hits
  if(floorD > 0.0 && floorD < hit.d) {
    hit.d = floorD;
    hit.matID = 0; // Ground material
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

    // Check if ground or regular object
    if(hit.matID == 0) {
      n = vec3(0.0, 1.0, 0.0);
    } else {
      n = getNormal(p);
    }

    // Distance-based filtered checker pattern in XZ plane for ground
    if(mat.isChecker) {
      float checkerSize = 1.3;
      float distance = hit.d;
      float fadeDistance = 0.0; // Distance at which checker starts fading
      float maxDistance = 60.0;  // Distance at which checker completely disappears

      // Calculate fade factor based on distance
      float fadeFactor = 1.0 - smoothstep(fadeDistance, maxDistance, distance);

      // Only apply checker if we're close enough
      if(fadeFactor > 0.0) {
        vec2 checker = fract(p.xz / checkerSize);

        // Create antialiased checker pattern using smoothstep
        float checkerPattern = step(0.5, checker.x) + step(0.5, checker.y);
        checkerPattern = mod(checkerPattern, 2.0);

        // Apply checker with distance fade
        float checkerInfluence = checkerPattern * 0.6 * fadeFactor;
        mat.color = mix(mat.color, mat.color * 0.4, checkerInfluence);
      }
    }

    // Add some ambient light
    col += vec3(0.09, 0.08, 0.08);

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
      vec3 viewDir = normalize(ro - p);
      vec3 reflectDir = reflect(-lightDir, n);
      float spec = pow(max(dot(viewDir, reflectDir), 0.0), mat.hardness);
      col += vec3(1.0) * spec * mat.specular * shadowFactor * lightCol;

      // Reflection for reflective materials, needs more rays!
      if(mat.isReflective) {
        vec3 reflectDir = reflect(rd, n);
        Hit reflectHit = raycast(p + n * EPSILON * 10.0, reflectDir);
        if(reflectHit.matID != -1) {
          vec3 reflectP = p + reflectDir * reflectHit.d;
          vec3 reflectN = getNormal(reflectP);
          Material reflectMat = MATERIALS[reflectHit.matID];
          float reflectDiff = max(dot(reflectN, lightDir), 0.0) * reflectMat.diffuse;
          vec3 reflectCol = reflectMat.color * reflectDiff;
          col += reflectCol * 0.3;
        }
      }
    }
  }

  // Phew! Set the final pixel colour
  pixel = vec4(col, 1.0);
}