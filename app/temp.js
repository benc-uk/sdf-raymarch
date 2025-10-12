  // Convert image coordinates to NDC [-1, 1]
  vec2 uv = imgCoord * 2.0 - 1.0;
  uv.x *= u_aspect;

  // Use inverse view-projection matrix to compute ray direction
  // Create points in clip space (near and far plane)
  vec4 nearPoint = vec4(uv, -1.0, 1.0); // Near plane in NDC
  vec4 farPoint = vec4(uv, 1.0, 1.0);   // Far plane in NDC

  // Transform to world space
  vec4 nearWorld = u_inverseViewProjectionMatrix * nearPoint;
  vec4 farWorld = u_inverseViewProjectionMatrix * farPoint;

  // Perspective divide
  nearWorld /= nearWorld.w;
  farWorld /= farWorld.w;

  // Ray setup
  vec3 ro = u_camPos; // Ray origin at camera position
  vec3 rd = normalize(farWorld.xyz - nearWorld.xyz); // Ray direction from near to far

  float d = length(uv * 1.2);
  vec3 col = palette(d);
  pixel = vec4(col, 1.0);