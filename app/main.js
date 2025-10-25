import vertShader from '../shaders/main.vert.glsl?raw'
import scene1Frag from '../shaders/scene1.frag.glsl?raw'
import sdfLibFrag from '../shaders/sdf-lib.frag.glsl?raw'

import * as twgl from 'twgl.js'
import { glFrameUpdate, initGL } from './gl.js'
import { Camera } from './camera.js'

const gl = initGL('canvas', {
  width: 800,
  height: 600,
  fitToContainer: true,
  resizeCanvas: false,
  showFPS: true,
})

const camera = new Camera([-1, 2, 5], [0, 0, 0], Math.PI / 4, gl.canvas.width / gl.canvas.height)

// Camera orbit parameters
const cameraRadius = 6
const cameraHeight = 3
const rotationSpeed = 0.4

let timeoutId = null
const canvas = /** @type {HTMLCanvasElement} */ (document.querySelector('canvas'))
const sceneSelector = /** @type {HTMLSelectElement} */ (document.querySelector('select'))

function prependSdfLib(shaderSrc) {
  return shaderSrc.replace('#include sdflib', sdfLibFrag)
}

const sceneMap = {
  scene1: prependSdfLib(scene1Frag),
  scene2: prependSdfLib(scene1Frag),
  scene3: prependSdfLib(scene1Frag), // Placeholder
}

const uniforms = {
  u_resolution: [gl.canvas.width, gl.canvas.height],
  u_aspect: gl.canvas.width / gl.canvas.height,
  u_time: 0,
  u_inverseViewProjectionMatrix: camera.inverseViewProjectionMatrix,
  u_cameraPos: camera.pos,
}

let progInfo
let fullScreenBuffInfo

// Classic WebGL render loop
function render(ts) {
  uniforms.u_time = ts * 0.001

  // Update camera position to orbit around the target
  const angle = uniforms.u_time * rotationSpeed
  const newCameraPos = /** @type {[number, number, number]} */ ([Math.cos(angle) * cameraRadius, cameraHeight, Math.sin(angle) * cameraRadius])

  // Update camera position while keeping the same target
  camera.pos = newCameraPos

  // Update uniforms with new camera data
  uniforms.u_inverseViewProjectionMatrix = camera.inverseViewProjectionMatrix
  uniforms.u_cameraPos = camera.pos

  twgl.setUniforms(progInfo, uniforms)
  twgl.drawBufferInfo(gl, fullScreenBuffInfo)

  glFrameUpdate(ts)
  requestAnimationFrame(render)
}

function switchScene(sceneName) {
  fullScreenBuffInfo = twgl.createBufferInfoFromArrays(gl, {
    position: [-1, -1, 0, 1, -1, 0, -1, 1, 0, -1, 1, 0, 1, -1, 0, 1, 1, 0],
  })

  const sceneFrag = sceneMap[sceneName]
  progInfo = twgl.createProgramInfo(gl, [vertShader, sceneFrag])

  // May move some of this to the render loop later
  gl.useProgram(progInfo.program)
  twgl.setBuffersAndAttributes(gl, progInfo, fullScreenBuffInfo)
}

sceneSelector.addEventListener('change', (e) => {
  //@ts-ignore
  const scene = e.target.value
  console.log(`Switching to scene: ${scene}`)
  switchScene(scene)
})

canvas.addEventListener('mousemove', () => {
  sceneSelector.classList.remove('hidden')
  sceneSelector.classList.add('visible')

  if (timeoutId) clearTimeout(timeoutId)

  timeoutId = setTimeout(() => {
    sceneSelector.classList.remove('visible')
    sceneSelector.classList.add('hidden')
  }, 3000)
})

canvas.addEventListener('mouseleave', () => {
  sceneSelector.classList.remove('visible')
  sceneSelector.classList.add('hidden')
})

switchScene('scene1')
render()
