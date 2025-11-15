// ============================================================================================
// Gradient Noise textures
// (C) Ben Coleman 2025
// License: MIT (see LICENSE file)
// Generates gradient & simplex noise, as WebGL textures
// ============================================================================================

import * as twgl from 'twgl.js'

// ============================================================================================
// Simplex Noise Implementation
// Based on Stefan Gustavson's implementation
// ============================================================================================
class SimplexNoise {
  constructor(seed = Math.random()) {
    // Permutation table with optional seeding
    this.p = []
    const random = this._seededRandom(seed)
    for (let i = 0; i < 256; i++) {
      this.p[i] = Math.floor(random() * 256)
    }

    // Double permutation to avoid overflow
    this.perm = []
    this.permMod12 = []
    for (let i = 0; i < 512; i++) {
      this.perm[i] = this.p[i & 255]
      this.permMod12[i] = this.perm[i] % 12
    }

    // Gradients for 2D/3D
    this.grad3 = [
      [1, 1, 0],
      [-1, 1, 0],
      [1, -1, 0],
      [-1, -1, 0],
      [1, 0, 1],
      [-1, 0, 1],
      [1, 0, -1],
      [-1, 0, -1],
      [0, 1, 1],
      [0, -1, 1],
      [0, 1, -1],
      [0, -1, -1],
    ]

    // Skewing and unskewing factors
    this.F2 = 0.5 * (Math.sqrt(3.0) - 1.0)
    this.G2 = (3.0 - Math.sqrt(3.0)) / 6.0
    this.F3 = 1.0 / 3.0
    this.G3 = 1.0 / 6.0
  }

  _seededRandom(seed) {
    let s = seed
    return function () {
      s = Math.sin(s) * 10000
      return s - Math.floor(s)
    }
  }

  // 2D simplex noise
  noise2D(xin, yin) {
    let n0, n1, n2

    const s = (xin + yin) * this.F2
    const i = Math.floor(xin + s)
    const j = Math.floor(yin + s)
    const t = (i + j) * this.G2
    const X0 = i - t
    const Y0 = j - t
    const x0 = xin - X0
    const y0 = yin - Y0

    let i1, j1
    if (x0 > y0) {
      i1 = 1
      j1 = 0
    } else {
      i1 = 0
      j1 = 1
    }

    const x1 = x0 - i1 + this.G2
    const y1 = y0 - j1 + this.G2
    const x2 = x0 - 1.0 + 2.0 * this.G2
    const y2 = y0 - 1.0 + 2.0 * this.G2

    const ii = i & 255
    const jj = j & 255
    const gi0 = this.permMod12[ii + this.perm[jj]]
    const gi1 = this.permMod12[ii + i1 + this.perm[jj + j1]]
    const gi2 = this.permMod12[ii + 1 + this.perm[jj + 1]]

    let t0 = 0.5 - x0 * x0 - y0 * y0
    if (t0 < 0) {
      n0 = 0.0
    } else {
      t0 *= t0
      n0 = t0 * t0 * this.dot2(this.grad3[gi0], x0, y0)
    }

    let t1 = 0.5 - x1 * x1 - y1 * y1
    if (t1 < 0) {
      n1 = 0.0
    } else {
      t1 *= t1
      n1 = t1 * t1 * this.dot2(this.grad3[gi1], x1, y1)
    }

    let t2 = 0.5 - x2 * x2 - y2 * y2
    if (t2 < 0) {
      n2 = 0.0
    } else {
      t2 *= t2
      n2 = t2 * t2 * this.dot2(this.grad3[gi2], x2, y2)
    }

    return 70.0 * (n0 + n1 + n2)
  }

  // 3D simplex noise
  noise3D(xin, yin, zin) {
    let n0, n1, n2, n3

    const s = (xin + yin + zin) * this.F3
    const i = Math.floor(xin + s)
    const j = Math.floor(yin + s)
    const k = Math.floor(zin + s)
    const t = (i + j + k) * this.G3
    const X0 = i - t
    const Y0 = j - t
    const Z0 = k - t
    const x0 = xin - X0
    const y0 = yin - Y0
    const z0 = zin - Z0

    let i1, j1, k1
    let i2, j2, k2
    if (x0 >= y0) {
      if (y0 >= z0) {
        i1 = 1
        j1 = 0
        k1 = 0
        i2 = 1
        j2 = 1
        k2 = 0
      } else if (x0 >= z0) {
        i1 = 1
        j1 = 0
        k1 = 0
        i2 = 1
        j2 = 0
        k2 = 1
      } else {
        i1 = 0
        j1 = 0
        k1 = 1
        i2 = 1
        j2 = 0
        k2 = 1
      }
    } else {
      if (y0 < z0) {
        i1 = 0
        j1 = 0
        k1 = 1
        i2 = 0
        j2 = 1
        k2 = 1
      } else if (x0 < z0) {
        i1 = 0
        j1 = 1
        k1 = 0
        i2 = 0
        j2 = 1
        k2 = 1
      } else {
        i1 = 0
        j1 = 1
        k1 = 0
        i2 = 1
        j2 = 1
        k2 = 0
      }
    }

    const x1 = x0 - i1 + this.G3
    const y1 = y0 - j1 + this.G3
    const z1 = z0 - k1 + this.G3
    const x2 = x0 - i2 + 2.0 * this.G3
    const y2 = y0 - j2 + 2.0 * this.G3
    const z2 = z0 - k2 + 2.0 * this.G3
    const x3 = x0 - 1.0 + 3.0 * this.G3
    const y3 = y0 - 1.0 + 3.0 * this.G3
    const z3 = z0 - 1.0 + 3.0 * this.G3

    const ii = i & 255
    const jj = j & 255
    const kk = k & 255
    const gi0 = this.permMod12[ii + this.perm[jj + this.perm[kk]]]
    const gi1 = this.permMod12[ii + i1 + this.perm[jj + j1 + this.perm[kk + k1]]]
    const gi2 = this.permMod12[ii + i2 + this.perm[jj + j2 + this.perm[kk + k2]]]
    const gi3 = this.permMod12[ii + 1 + this.perm[jj + 1 + this.perm[kk + 1]]]

    let t0 = 0.6 - x0 * x0 - y0 * y0 - z0 * z0
    if (t0 < 0) {
      n0 = 0.0
    } else {
      t0 *= t0
      n0 = t0 * t0 * this.dot3(this.grad3[gi0], x0, y0, z0)
    }

    let t1 = 0.6 - x1 * x1 - y1 * y1 - z1 * z1
    if (t1 < 0) {
      n1 = 0.0
    } else {
      t1 *= t1
      n1 = t1 * t1 * this.dot3(this.grad3[gi1], x1, y1, z1)
    }

    let t2 = 0.6 - x2 * x2 - y2 * y2 - z2 * z2
    if (t2 < 0) {
      n2 = 0.0
    } else {
      t2 *= t2
      n2 = t2 * t2 * this.dot3(this.grad3[gi2], x2, y2, z2)
    }

    let t3 = 0.6 - x3 * x3 - y3 * y3 - z3 * z3
    if (t3 < 0) {
      n3 = 0.0
    } else {
      t3 *= t3
      n3 = t3 * t3 * this.dot3(this.grad3[gi3], x3, y3, z3)
    }

    return 32.0 * (n0 + n1 + n2 + n3)
  }

  dot2(g, x, y) {
    return g[0] * x + g[1] * y
  }

  dot3(g, x, y, z) {
    return g[0] * x + g[1] * y + g[2] * z
  }

  // Fractal Brownian Motion (FBM)
  fbm2D(x, y, octaves = 4, persistence = 0.5, lacunarity = 2.0) {
    let total = 0
    let frequency = 1
    let amplitude = 1
    let maxValue = 0

    for (let i = 0; i < octaves; i++) {
      total += this.noise2D(x * frequency, y * frequency) * amplitude
      maxValue += amplitude
      amplitude *= persistence
      frequency *= lacunarity
    }

    return total / maxValue
  }

  // Turbulence (absolute value of FBM)
  turbulence2D(x, y, octaves = 4, persistence = 0.5, lacunarity = 2.0) {
    let total = 0
    let frequency = 1
    let amplitude = 1
    let maxValue = 0

    for (let i = 0; i < octaves; i++) {
      total += Math.abs(this.noise2D(x * frequency, y * frequency)) * amplitude
      maxValue += amplitude
      amplitude *= persistence
      frequency *= lacunarity
    }

    return total / maxValue
  }
}

// ============================================================================================
// Texture Generation Functions
// ============================================================================================

/**
 * @typedef {Object} NoiseOptions
 * @property {number} [size=512] - Size of the texture (width and height)
 * @property {number} [scale=100] - Scale factor for the noise
 * @property {number} [octaves=4] - Number of octaves for FBM-based noise
 * @property {number} [persistence=0.5] - Persistence for FBM
 * @property {number} [lacunarity=2.0] - Lacunarity for FBM
 * @property {number} [seed] - Optional seed for reproducible noise
 * @property {number} [zSlice=0] - Z-coordinate slice for 3D noise
 */

/**
 * Creates a 2D simplex noise texture
 * @param {WebGL2RenderingContext} gl - WebGL context
 * @param {NoiseOptions} [options] - Noise generation options
 * @returns {WebGLTexture} WebGL texture containing the noise
 */
export function createSimplexNoise2D(gl, options = {}) {
  const { size = 512, scale = 100, seed } = options

  const simplex = new SimplexNoise(seed)
  const data = new Uint8Array(size * size * 4)

  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      const nx = x / scale
      const ny = y / scale
      const noise = simplex.noise2D(nx, ny)
      const value = Math.floor(((noise + 1) / 2) * 255)

      const idx = (y * size + x) * 4
      data[idx] = value
      data[idx + 1] = value
      data[idx + 2] = value
      data[idx + 3] = 255
    }
  }

  return twgl.createTexture(gl, {
    src: data,
    width: size,
    height: size,
    minMag: gl.LINEAR,
    wrap: gl.REPEAT,
  })
}

/**
 * Creates a 3D simplex noise texture
 * @param {WebGL2RenderingContext} gl - WebGL context
 * @param {NoiseOptions} [options] - Noise generation options
 * @returns {WebGLTexture} WebGL 3D texture containing the noise
 */
export function createSimplexNoise3D(gl, options = {}) {
  const { size = 128, scale = 100, seed } = options

  const simplex = new SimplexNoise(seed)
  const data = new Uint8Array(size * size * size * 4)

  for (let z = 0; z < size; z++) {
    for (let y = 0; y < size; y++) {
      for (let x = 0; x < size; x++) {
        const nx = x / scale
        const ny = y / scale
        const nz = z / scale
        const noise = simplex.noise3D(nx, ny, nz)
        const value = Math.floor(((noise + 1) / 2) * 255)

        const idx = (z * size * size + y * size + x) * 4
        data[idx] = value
        data[idx + 1] = value
        data[idx + 2] = value
        data[idx + 3] = 255
      }
    }
  }

  return twgl.createTexture(gl, {
    target: gl.TEXTURE_3D,
    src: data,
    width: size,
    height: size,
    depth: size,
    minMag: gl.LINEAR,
    wrap: gl.MIRRORED_REPEAT,
  })
}

/**
 * Creates a Fractal Brownian Motion (FBM) noise texture
 * @param {WebGL2RenderingContext} gl - WebGL context
 * @param {NoiseOptions} [options] - Noise generation options
 * @returns {WebGLTexture} WebGL texture containing the noise
 */
export function createFBMNoise(gl, options = {}) {
  const { size = 512, scale = 100, octaves = 4, persistence = 0.5, lacunarity = 2.0, seed } = options

  const simplex = new SimplexNoise(seed)
  const data = new Uint8Array(size * size * 4)

  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      const nx = x / scale
      const ny = y / scale
      const noise = simplex.fbm2D(nx, ny, octaves, persistence, lacunarity)
      const value = Math.floor(((noise + 1) / 2) * 255)

      const idx = (y * size + x) * 4
      data[idx] = value
      data[idx + 1] = value
      data[idx + 2] = value
      data[idx + 3] = 255
    }
  }

  return twgl.createTexture(gl, {
    src: data,
    width: size,
    height: size,
    minMag: gl.LINEAR,
    wrap: gl.REPEAT,
  })
}

/**
 * Creates a turbulence noise texture (marble-like patterns)
 * @param {WebGL2RenderingContext} gl - WebGL context
 * @param {NoiseOptions} [options] - Noise generation options
 * @returns {WebGLTexture} WebGL texture containing the noise
 */
export function createTurbulenceNoise(gl, options = {}) {
  const { size = 512, scale = 80, octaves = 5, persistence = 0.5, lacunarity = 2.0, seed } = options

  const simplex = new SimplexNoise(seed)
  const data = new Uint8Array(size * size * 4)

  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      const nx = x / scale
      const ny = y / scale
      const noise = simplex.turbulence2D(nx, ny, octaves, persistence, lacunarity)
      const value = Math.floor(noise * 255)

      const idx = (y * size + x) * 4
      data[idx] = value
      data[idx + 1] = value
      data[idx + 2] = value
      data[idx + 3] = 255
    }
  }

  return twgl.createTexture(gl, {
    src: data,
    width: size,
    height: size,
    minMag: gl.LINEAR,
    wrap: gl.REPEAT,
  })
}

/**
 * Creates a tileable simplex noise texture using 3D noise mapped to a torus
 * This ensures seamless wrapping on both axes
 * @param {WebGL2RenderingContext} gl - WebGL context
 * @param {NoiseOptions} [options] - Noise generation options
 * @returns {WebGLTexture} WebGL texture containing the tileable noise
 */
export function createTileableSimplexNoise2D(gl, options = {}) {
  const { size = 512, scale = 100, seed } = options

  const simplex = new SimplexNoise(seed)
  const data = new Uint8Array(size * size * 4)

  // Map 2D texture space onto a 4D torus to make it tileable
  // This uses the standard tiling technique for noise
  const tau = 2.0 * Math.PI

  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      // Normalize coordinates to [0, 1]
      const s = x / size
      const t = y / size

      // Map to torus in 3D space
      const angle_s = s * tau
      const angle_t = t * tau

      // Sample noise in 3D space along a torus path
      // The radius determines how much variation we get
      const radius = scale / tau
      const nx = radius * Math.cos(angle_s)
      const ny = radius * Math.sin(angle_s)
      const nz = radius * Math.cos(angle_t)

      const noise = simplex.noise3D(nx, ny, nz)
      const value = Math.floor(((noise + 1) / 2) * 255)

      const idx = (y * size + x) * 4
      data[idx] = value
      data[idx + 1] = value
      data[idx + 2] = value
      data[idx + 3] = 255
    }
  }

  return twgl.createTexture(gl, {
    src: data,
    width: size,
    height: size,
    minMag: gl.LINEAR,
    wrap: gl.REPEAT,
  })
}

export function createTileableSimplexNoise3D(gl, options = {}) {
  // Tileable 3D noise is complex; for simplicity, we return standard 3D noise here
  return createSimplexNoise3D(gl, options)
}
