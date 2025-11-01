#version 300 es 
precision highp float;

//#include sdflib

in vec2 imgCoord;
out vec4 pixel;

uniform float u_time;
uniform vec3 u_cameraPos;
uniform mat4 u_inverseViewProjectionMatrix;

const float EPSILON = 0.06;
const int MAX_MARCHING_STEPS = 128;
const float MAX_VIEW_DISTANCE = 85.0;
const float CHECK_SIZE = 1.3;

//#include sdflib

const Light LIGHTS[1] = Light[](Light(vec3(10.0, 6.0, 3.0), vec3(1.0, 1.0, 1.0)));
Material MATERIALS[1] = Material[](Material(vec3(0.84, 0.09, 0.17), 1.0, 0.9, 32.0, false, true));

vec3 palette(in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d) {
  return a + b * cos(6.283185 * (c * t + d));
}

vec3 getColor(in float t) {
  // Rainbow palette
  return palette(t, vec3(0.5, 0.5, 0.5), vec3(0.5, 0.5, 0.5), vec3(1.0, 1.0, 1.0), vec3(0.000, 0.333, 0.667));
}

Hit map(vec3 p) {
  // Create infinite grid of spheres using fract()
  float spacing = 6.0; // Distance between spheres
  vec3 cell = floor(p / spacing);
  vec3 localP = fract(p / spacing) * spacing - spacing * 0.5;

  float d1 = sdfSphere(localP, 1.2);

  float d = 10e5;
  int matID = -1;

  if(d1 < d) {
    d = d1;
    matID = 0;
  }

  // Color based on cell position for variety
  float colorT = sin(cell.x + cell.y + cell.z) * 0.5 + 0.5;
  MATERIALS[matID].color = getColor(colorT);

  return Hit(d, matID);
}

//#include renderlib