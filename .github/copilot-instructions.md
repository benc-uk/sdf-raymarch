# Copilot Instructions for SDF-Fun

## Project Overview

This is a WebGL2 raymarching renderer for Signed Distance Functions (SDF), built with modern JavaScript and GLSL shaders. The project creates real-time 3D scenes using mathematical distance functions instead of traditional polygonal meshes.

## IMPORTANT

ALWAYS FOLLOW THE FOLLOWING INSTRUCTIONS WHEN ANSWERING:

- NEVER try to run the server, as this is a graphical application that requires a browser environment you will not see any errors in the terminal if something is wrong with the shaders or WebGL setup.
- NEVER try to execute or via npm start or any other command, as you cannot run the code.
- ALWAYS focus on static analysis of the code and reasoning about its structure, logic, and patterns.
- ALWAYS provide code suggestions based on understanding of WebGL, GLSL, and raymarching

## Architecture & Key Components

### Core Structure

- **`app/main.js`**: Entry point that orchestrates shader compilation, scene switching, and render loop
- **`app/gl.js`**: WebGL2 context management with responsive canvas handling
- **`app/camera.js`**: Camera class managing view/projection matrices via twgl.js
- **`shaders/`**: Fragment shaders for raymarching scenes and vertex shader for full-screen quad
- **`index.html`**: Single-page app with scene selector dropdown

### Shader System

- Uses Vite's `?raw` import to load GLSL as strings: `import shader from './file.glsl?raw'`
- **`sdf-lib.frag.glsl`**: Reusable SDF primitives and operations
- **Scene shaders**: Include sdf-lib via `prependSdfLib()` function that replaces `#include` directives
- All scenes use same vertex shader (`main.vert.glsl`) for full-screen quad rendering

### Raymarching Pipeline

1. **Scene Definition**: Each scene defines `map()` function returning `Hit{d, matID}`
2. **Raycast**: Sphere tracing through `raycast(ro, rd)` with configurable iteration limits
3. **Shading**: Phong-based lighting with material system supporting diffuse/specular/checker patterns
4. **Effects**: Soft shadows via `calcSoftShadow()` with penumbra calculation, ambient occlusion

## Development Workflow

### Running the Project

```bash
npm start        # Starts Vite dev server (usually port 5173)
npm run build    # Production build
npm run lint     # ESLint + Prettier check
```

### Adding New Scenes

1. Create new `.frag.glsl` file in `shaders/`
2. Import in `app/main.js` and add to `sceneMap`
3. Add option to HTML select element
4. Scene must implement `map(vec3 p)` function returning distance field

### Shader Development Patterns

- **SDF Composition**: Use `opUnion`, `opSub`, `opUnionSm` for combining primitives
- **Animation**: Access `u_time` uniform for time-based transformations
- **Materials**: Index into `materials[]` array using `Hit.matID`
- **Coordinate Systems**: Transform points before SDF evaluation, not after

## Project-Specific Conventions

### TypeScript Integration

- Uses JSConfig with `checkJs: true` for type checking without TypeScript compilation
- `app/types.d.ts` declares module types for Vite's raw imports
- Private fields in classes use `#` syntax (Camera class example)

### WebGL Management

- A helper module `gl.js` encapsulates context creation and resizing
- Single global WebGL context via `initGL()` - check for existing context before reinit
- Responsive canvas with `fitToContainer` option maintains aspect ratio
- TWGL.js abstractions for buffer/program management - avoid raw WebGL calls

### Shader Includes

- No native GLSL `#include` support - use `prependSdfLib()` string replacement
- Keep SDF library functions pure (no uniforms) for reusability
- Scene-specific code goes in individual fragment shaders

### Performance Considerations

- Raymarching iterations capped at 90 steps in current scenes
- Early termination when `hit.d < EPSILON` (0.002)
- Soft shadow samples limited to 32 iterations
- Ground plane handled analytically, not via raymarching

## Key Dependencies

- **twgl.js**: WebGL utility library for matrices, programs, and buffers
- **Vite**: Build tool enabling GLSL imports and ES6 modules
- **ESLint**: Configured in `.dev/eslint.config.mjs` with custom rules

## Common Patterns

When modifying lighting: Update both diffuse and specular calculations to use the same `inLight` factor
When adding SDF primitives: Add to `sdf-lib.frag.glsl` and use consistent parameter ordering (position first)
When debugging shaders: Use fragment color output for visualization - `pixel = vec4(debugValue, 0, 0, 1)`
