// ============================================================================================
// WebGL Mini Library
// This module provides a mid-level interface for initializing and managing a WebGL2 context
// ============================================================================================

/** @type {WebGL2RenderingContext} */
let gl

/**
 * @typedef {Object} InitGLOptions
 * @property {number} [width=800] - Width of the canvas.
 * @property {number} [height=600] - Height of the canvas.
 * @property {boolean} [fitToContainer=true] - Whether the canvas CSS style to cover the entire container.
 * @property {boolean} [resizeCanvas=false] - Whether to resize the internal canvas to always match the display size.
 * @property {boolean} [pixelRendering=false] - Whether to disable smoothing (useful for pixel art).
 * @property {string} [backgroundColor='#000'] - Background color in CSS color string format.
 * @property {Object} [glOptions={}] - Additional WebGL context options.
 * @property {boolean} [showFPS=false] - Whether to display an FPS counter overlay.
 * @property {number} [fpsUpdateInterval=2000] - Interval in milliseconds for updating the FPS display.
 */

/** @type {InitGLOptions} */
const defaults = {
  width: 800,
  height: 600,
  fitToContainer: true,
  resizeCanvas: false,
  pixelRendering: false,
  backgroundColor: '#000',
  glOptions: {},
  showFPS: false,
  fpsUpdateInterval: 2000,
}

// --------------------------------------------------------------------------------------------
// Optional FPS Meter state
// --------------------------------------------------------------------------------------------
let fpsEnabled = false
let fpsDiv = null
let fpsFrameCount = 0
let fpsLastUpdate = 0
let fpsInterval = 2000

/**
 * Initializes the WebGL context with the given canvas selector and options.
 * @param {string} selector - CSS selector for the canvas element.
 * @param {InitGLOptions} options - Options for initializing the WebGL context.
 * @returns {WebGL2RenderingContext} The initialized WebGL context.
 */
export function initGL(selector = 'canvas', options = defaults) {
  if (gl) {
    console.warn('WebGL context already initialized.')
    return gl
  }

  // Merge defaults with provided options
  options = { ...defaults, ...options }

  const canvas = /** @type {HTMLCanvasElement | null} */ (document.querySelector(selector))

  if (!canvas) {
    throw new Error(`No canvas found with selector: ${selector}`)
  }

  if (options.width) {
    canvas.width = options.width
  }

  if (options.height) {
    canvas.height = options.height
  }

  if (options.pixelRendering) {
    canvas.style.imageRendering = 'pixelated'
    canvas.style.imageRendering = 'crisp-edges'
  }

  if (options.backgroundColor) {
    canvas.style.backgroundColor = options.backgroundColor
  }

  if (options.fitToContainer) {
    window.addEventListener('resize', () => {
      const size = fit(canvas)
      if (options.resizeCanvas) resize(canvas, size[0], size[1])
    })
  }

  gl = /** @type {WebGL2RenderingContext | null} */ (canvas.getContext('webgl2', options.glOptions))

  if (!gl) {
    throw new Error('WebGL2 not supported')
  }

  gl.viewport(0, 0, gl.canvas.width, gl.canvas.height)

  // Initial fit and resize if needed
  if (options.fitToContainer) {
    const size = fit(canvas)
    if (options.resizeCanvas) resize(canvas, size[0], size[1])
  }

  console.log(`Initialized WebGL context: ${canvas.width}x${canvas.height}`)

  // Setup FPS overlay if requested
  if (options.showFPS) {
    fpsEnabled = true
    fpsInterval = options.fpsUpdateInterval || 2000
    fpsDiv = document.createElement('div')
    fpsDiv.textContent = '... FPS'
    fpsDiv.style.position = 'fixed'
    fpsDiv.style.top = '4px'
    fpsDiv.style.right = '8px'
    fpsDiv.style.zIndex = '1000'
    fpsDiv.style.padding = '4px 12px'
    fpsDiv.style.background = 'rgba(0,0,0,0.4)'
    fpsDiv.style.color = '#0f0'
    fpsDiv.style.borderRadius = '6px'
    fpsDiv.style.font = '16px monospace'
    fpsDiv.style.pointerEvents = 'none'
    fpsDiv.style.userSelect = 'none'
    document.body.appendChild(fpsDiv)
  }

  return gl
}

export function getGL() {
  if (!gl) {
    throw new Error('WebGL context not initialized. Call initGL() first.')
  }
  return gl
}

function resize(canvas, width, height) {
  canvas.width = width
  canvas.height = height
  if (gl) {
    gl.viewport(0, 0, canvas.width, canvas.height)
  }
}

function fit(canvas) {
  const aspectRatio = canvas.width / canvas.height

  // Get container dimensions (or use window if no parent)
  const container = canvas.parentElement || document.body
  const containerRect = container.getBoundingClientRect()
  const containerWidth = containerRect.width || window.innerWidth
  const containerHeight = containerRect.height || window.innerHeight
  const containerAspectRatio = containerWidth / containerHeight

  let displayWidth, displayHeight

  // Calculate display size while maintaining aspect ratio
  if (aspectRatio > containerAspectRatio) {
    // Canvas is wider than container - fit to width
    displayWidth = containerWidth
    displayHeight = containerWidth / aspectRatio
  } else {
    // Canvas is taller than container - fit to height
    displayHeight = containerHeight
    displayWidth = containerHeight * aspectRatio
  }

  displayHeight = Math.floor(displayHeight)
  displayWidth = Math.floor(displayWidth)

  // Apply the calculated dimensions
  canvas.style.width = displayWidth + 'px'
  canvas.style.height = displayHeight + 'px'
  canvas.style.display = 'block'
  canvas.style.margin = 'auto'

  return [displayWidth, displayHeight]
}

// --------------------------------------------------------------------------------------------
// Frame update hook (call once per rendered frame, pass in the rAF timestamp)
// --------------------------------------------------------------------------------------------
/**
 * Update per-frame stats (currently only FPS). Safe to call even if disabled.
 * @param {number} [ts=performance.now()] - The high-resolution timestamp (from requestAnimationFrame).
 */
export function glFrameUpdate(ts = performance.now()) {
  if (!fpsEnabled) return
  fpsFrameCount++
  if (fpsLastUpdate === 0) fpsLastUpdate = ts
  const elapsed = ts - fpsLastUpdate
  if (elapsed >= fpsInterval) {
    const fps = (fpsFrameCount / elapsed) * 1000
    if (fpsDiv) fpsDiv.textContent = fps.toFixed(1) + ' FPS'
    fpsFrameCount = 0
    fpsLastUpdate = ts
  }
}
