#version 300 es 
precision highp float;

//#include sdflib

const float EPSILON = 0.006;
const int MAX_MARCHING_STEPS = 128;
const float MAX_VIEW_DISTANCE = 30.0;
const float CHECK_SIZE = 1.3;

const Light LIGHTS[2] = Light[](Light(vec3(5.0, 8.0, 5.0), vec3(1.0, 0.95, 0.9)), Light(vec3(-4.0, 6.0, -3.0), vec3(0.84, 0.53, 0.25)));
const Material MATERIALS[5] = Material[](Material(vec3(0.6, 0.6, 0.6), 1.0, 0.0, 1.0, true, true, -1),      // Ground is grey
Material(vec3(0.83, 0.26, 0.09), 1.0, 0.3, 6.0, false, true, -1),  // Reddish
Material(vec3(0.21, 0.16, 0.88), 1.0, 0.9, 64.0, false, false, -1),// Bluish
Material(vec3(0.1, 0.8, 0.1), 1.0, 1.0, 3.0, false, true, -1),     // Shiny green
Material(vec3(0.19, 0.27, 0.37), 1.0, 0.1, 1.0, false, false, -1)  // Dark metallic grey
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

//#include renderlib
