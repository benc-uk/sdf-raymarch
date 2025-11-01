#version 300 es 
precision highp float;

//#include sdflib

in vec2 imgCoord;
out vec4 pixel;

uniform float u_time;
uniform vec3 u_cameraPos;
uniform mat4 u_inverseViewProjectionMatrix;

const float EPSILON = 0.005;
const int MAX_MARCHING_STEPS = 380;
const float MAX_VIEW_DISTANCE = 120.0;
const float CHECK_SIZE = 1.3;

Light LIGHTS[1] = Light[](Light(vec3(0.0, 2.0, 0.0), vec3(1.0, 1.0, 1.0)));
Material MATERIALS[2] = Material[](Material(vec3(0.0, 0.0, 0.0), 0.0, 0.0, 0.0, false, false), Material(vec3(0.0, 0.0, 0.0), 1.0, 0.9, 12.0, false, false));

vec3 palette(in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d) {
  return a + b * cos(6.283185 * (c * t + d));
}

vec3 getColor(in float t) {
  // Rainbow palette
  return palette(t, vec3(0.5, 0.6, 0.5), vec3(0.4, 0.5, 0.5), vec3(1.0, 1.0, 1.0), vec3(0.000, 0.333, 0.667));
}

Hit map(vec3 p) {
  // Light follows camera
  LIGHTS[0].position = u_cameraPos + vec3(0.0, 1.0, 0.0);

  // Create infinite grid using floor() & fract()
  float spacing = 6.0;
  vec3 cell = floor(p / spacing);
  vec3 localP = fract(p / spacing) * spacing - spacing * 0.5;

  float sphereD = sdfCubeRound(localP, vec3(0.9), 0.2);

  float d = MAX_VIEW_DISTANCE;
  int matID = -1;

  if(sphereD < d) {
    d = sphereD;
    matID = 1;
  }

  MATERIALS[matID].color = getColor(sin(cell.x + cell.y + cell.z) * 0.5 + 0.5);

  return Hit(d, matID);
}

//#include renderlib