#version 300 es 
precision highp float;

//#include sdflib

const float EPSILON = 0.006;
const int MAX_MARCHING_STEPS = 128;
const float MAX_VIEW_DISTANCE = 25.0;
const float CHECK_SIZE = 1.3;

const Light LIGHTS[2] = Light[](Light(vec3(5.0, 8.0, 5.0), vec3(0.67, 0.97, 0.97)), Light(vec3(-3.0, 4.0, 0.0), vec3(0.3, 0.45, 0.91)));
const Material MATERIALS[3] = Material[](Material(vec3(0.34, 0.09, 0.17), 1.0, 0.0, 1.0, false, false, 0),  // floor reddish
Material(vec3(0.9, 0.9, 0.95), 0.6, 0.8, 164.0, false, false, -1), // china like
Material(vec3(0.22, 0.57, 0.11), 1.0, 1.0, 100.0, false, true, -1));  // green slime

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

//#include renderlib