// ==========================================================================
// Main application entry point
// (C) Ben Coleman 2025
// ==========================================================================

import * as twgl from 'twgl.js'
import { glUpdateStats, initGL } from './gl.js'
import { Camera } from './camera.js'

import vertShader from '../shaders/main.vert.glsl?raw'
import scene1Frag from '../shaders/scene1.frag.glsl?raw'
import scene2Frag from '../shaders/scene2.frag.glsl?raw'
import sdfLibFrag from '../shaders/inc-sdf-lib.frag.glsl?raw'
import renderLibFrag from '../shaders/inc-render-lib.frag.glsl?raw'

let progInfo = null
let fullScreenBuffInfo = null

const gl = initGL('canvas', {
  width: 800,
  height: 600,
  fitToContainer: true,
  resizeCanvas: false,
  showFPS: true,
})

// Camera
const cameraRadius = 6
let cameraHeight = 3
let cameraAngle = 0
let mouseLocked = false
//const rotationSpeed = 0.4
const camera = new Camera([-1, 2, 5], [0, 0, 0], Math.PI / 4, gl.canvas.width / gl.canvas.height)

// Scene management
const sceneMap = {
  'Scene: Shapes': preprocessor(scene1Frag),
  'Scene: Cauldron Slime': preprocessor(scene2Frag),
}

const uniforms = {
  u_resolution: [gl.canvas.width, gl.canvas.height],
  u_aspect: gl.canvas.width / gl.canvas.height,
  u_time: 0,
  u_inverseViewProjectionMatrix: camera.inverseViewProjectionMatrix,
  u_cameraPos: camera.pos,
}

export function initUI() {
  const sceneSelector = /** @type {HTMLSelectElement} */ (document.querySelector('select'))
  const canvas = /** @type {HTMLCanvasElement} */ (document.querySelector('canvas'))
  let timeoutId = null

  sceneSelector.innerHTML = ''
  for (const sceneName in sceneMap) {
    const option = document.createElement('option')
    option.value = sceneName
    option.textContent = sceneName
    sceneSelector.appendChild(option)
  }

  sceneSelector.addEventListener('change', (e) => {
    //@ts-ignore
    const scene = e.target.value
    console.log(`Switching to scene: ${scene}`)
    switchScene(scene)
  })

  document.addEventListener('mousemove', () => {
    sceneSelector.classList.remove('hidden')
    sceneSelector.classList.add('visible')

    if (timeoutId) clearTimeout(timeoutId)

    timeoutId = setTimeout(() => {
      sceneSelector.classList.remove('visible')
      sceneSelector.classList.add('hidden')
    }, 3000)
  })

  document.addEventListener('mouseleave', () => {
    sceneSelector.classList.remove('visible')
    sceneSelector.classList.add('hidden')
  })

  // grab mouse movement to rotate camera
  canvas.addEventListener('click', () => {
    if (!mouseLocked) {
      canvas.requestPointerLock()
      mouseLocked = true
    } else {
      document.exitPointerLock()
      mouseLocked = false
    }
  })

  canvas.addEventListener('mousemove', (e) => {
    if (document.pointerLockElement === canvas) {
      const movementX = e.movementX || 0
      cameraAngle += movementX * 0.0008

      const movementY = e.movementY || 0
      cameraHeight += movementY * 0.008

      // Clamp camera height
      cameraHeight = Math.max(1.4, Math.min(10, cameraHeight))
    }
  })
}

// Switches the current scene by updating the fragment shader.
export function switchScene(sceneName) {
  fullScreenBuffInfo = twgl.createBufferInfoFromArrays(gl, {
    position: [-1, -1, 0, 1, -1, 0, -1, 1, 0, -1, 1, 0, 1, -1, 0, 1, 1, 0],
  })

  camera.target = [0, 0, 0]
  cameraHeight = 3
  if (sceneName == 'Scene: Cauldron Slime') {
    camera.target = [0, 2, 0]
    cameraHeight = 4
  }

  const sceneFrag = sceneMap[sceneName]
  progInfo = twgl.createProgramInfo(gl, [vertShader, sceneFrag])

  // May move some of this to the render loop later
  gl.useProgram(progInfo.program)
  twgl.setBuffersAndAttributes(gl, progInfo, fullScreenBuffInfo)
}

// Fake shader preprocessor to carry out #include directives
function preprocessor(shaderSrc) {
  let out = shaderSrc.replace('//#include sdflib', sdfLibFrag)
  out = out.replace('//#include renderlib', renderLibFrag)
  return out
}

// Classic WebGL render loop
function render(ts) {
  uniforms.u_time = ts * 0.001

  // Update camera position to orbit around the target
  const angle = cameraAngle // + uniforms.u_time * 0.3
  const height = cameraHeight // + Math.sin(uniforms.u_time * 0.3) * 0.8
  const newCameraPos = /** @type {[number, number, number]} */ ([Math.cos(angle) * cameraRadius, height, Math.sin(angle) * cameraRadius])

  // Update camera position while keeping the same target
  camera.pos = newCameraPos

  // Update uniforms with new camera data
  uniforms.u_inverseViewProjectionMatrix = camera.inverseViewProjectionMatrix
  uniforms.u_cameraPos = camera.pos

  twgl.setUniforms(progInfo, uniforms)
  twgl.drawBufferInfo(gl, fullScreenBuffInfo)

  glUpdateStats(ts) // only for FPS tracking, not strictly necessary
  requestAnimationFrame(render)
}

// !ENTRYPOINT HERE!
initUI()
switchScene('Scene: Shapes')
render(0)
