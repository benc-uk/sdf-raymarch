#version 300 es 
precision highp float;

//#include sdflib

const float EPSILON = 0.02;
const int MAX_MARCHING_STEPS = 100;
const float MAX_VIEW_DISTANCE = 40.0;
const float CHECK_SIZE = 1.3;

Light LIGHTS[1] = Light[](Light(vec3(3.0, 6.0, 6.0), vec3(1.0, 1.0, 1.0)));
Material MATERIALS[3] = Material[](blankMat, Material(vec3(0.102, 0.604, 0.82), 1.0, 0.9, 48.0, false, false, -1), Material(vec3(0.1, 0.6, 0.1), 1.0, 1.0, 12.0, false, false, 1));

// Simple hash-based procedural noise to avoid texture sampling artifacts
vec3 hash3(vec3 p) {
  p = fract(p * vec3(0.1031, 0.1030, 0.0973));
  p += dot(p, p.yxz + 19.19);
  return fract((p.xxy + p.yxx) * p.zyx);
}

float noise3D(vec3 p) {
  vec3 pi = floor(p);
  vec3 pf = fract(p);
  vec3 w = pf * pf * (3.0 - 2.0 * pf);

  return mix(mix(mix(dot(hash3(pi + vec3(0, 0, 0)) - 0.5, pf - vec3(0, 0, 0)), dot(hash3(pi + vec3(1, 0, 0)) - 0.5, pf - vec3(1, 0, 0)), w.x), mix(dot(hash3(pi + vec3(0, 1, 0)) - 0.5, pf - vec3(0, 1, 0)), dot(hash3(pi + vec3(1, 1, 0)) - 0.5, pf - vec3(1, 1, 0)), w.x), w.y), mix(mix(dot(hash3(pi + vec3(0, 0, 1)) - 0.5, pf - vec3(0, 0, 1)), dot(hash3(pi + vec3(1, 0, 1)) - 0.5, pf - vec3(1, 0, 1)), w.x), mix(dot(hash3(pi + vec3(0, 1, 1)) - 0.5, pf - vec3(0, 1, 1)), dot(hash3(pi + vec3(1, 1, 1)) - 0.5, pf - vec3(1, 1, 1)), w.x), w.y), w.z);
}

Hit map(vec3 p) {
  // rotate sphere with u_time
  float t = u_time * 0.6;
  mat3 rotY = mat3(cos(t), 0.0, -sin(t), 0.0, 1.0, 0.0, sin(t), 0.0, cos(t));
  vec3 spherePos = rotY * p;

  // Bumpy sphere
  float displacementAmount = 0.07;
  vec3 sphereNormal = normalize(spherePos);

  // Use procedural noise
  float scale = 12.0;
  float noise = noise3D(spherePos * scale);
  // Displace sphere position along normal
  spherePos += sphereNormal * noise * displacementAmount;

  float sphereD = sdfSphere(spherePos, 1.0);

  // Bumpy green ground
  float groundY = -2.9;
  vec3 groundPos = vec3(p.x, p.y - groundY, p.z + u_time * 2.0);
  float groundNoise = noise3D(groundPos * 0.6);
  groundPos -= vec3(0.0, 1.0, 0.0) * groundNoise * 1.8;
  float groundD = sdfPlane(groundPos, vec3(0.0, 1.0, 0.0), 0.0);

  float minD = 1e20;
  int matID = -1;

  if(groundD < minD) {
    minD = groundD;
    matID = 2;
  }

  if(sphereD < minD) {
    minD = sphereD;
    matID = 1;
  }

  return Hit(minD, matID);
}

//#include renderlib