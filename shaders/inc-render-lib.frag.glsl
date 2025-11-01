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
    // increase width with distance
    float filterWidth = fwidth(uv.x) + fwidth(uv.y) * (distance / (MAX_VIEW_DISTANCE * 0.5));

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
  vec3 rd = normalize(worldPos.xyz - u_cameraPos);

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

    // Get normal, we can speed things up a little for the ground plane
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