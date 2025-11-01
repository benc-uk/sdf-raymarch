// ==========================================================================
// Main application entry point
// (C) Ben Coleman 2025
// ==========================================================================

import * as twgl from 'twgl.js'
import { updateStats, initGL, getCanvas } from './gl.js'
import CameraOrbital from './camera-orbit.js'
import CameraDirectional from './camera-directional.js'

// These are GLSL shader chunks
import vertShader from '../shaders/main.vert.glsl?raw'
import sdfLibFrag from '../shaders/inc-sdf-lib.frag.glsl?raw'
import renderLibFrag from '../shaders/inc-render-lib.frag.glsl?raw'
import scene1Frag from '../shaders/scenes/scene1.frag.glsl?raw'
import scene2Frag from '../shaders/scenes/scene2.frag.glsl?raw'
import scene3Frag from '../shaders/scenes/scene3.frag.glsl?raw'

//@ts-ignore
import sceneMap from './scenes.json'

let progInfo = null
let fullScreenBuffInfo = null

const gl = initGL('canvas', {
  width: 1024,
  height: 576,
  fitToContainer: true,
  resizeCanvas: false,
  showFPS: true,
})

let camera = null

const uniforms = {
  u_resolution: [gl.canvas.width, gl.canvas.height],
  u_aspect: gl.canvas.width / gl.canvas.height,
  u_time: 0,
  u_inverseViewProjectionMatrix: null, // Will be set each frame
  u_cameraPos: null, // Will be set each frame
}

// Temporary map of shaders for testing without fetch
const tempSceneShaderMap = {
  'scenes/scene1.frag.glsl': scene1Frag,
  'scenes/scene2.frag.glsl': scene2Frag,
  'scenes/scene3.frag.glsl': scene3Frag,
}

export function initUI() {
  const sceneSelector = /** @type {HTMLSelectElement} */ (document.querySelector('select'))
  const canvas = getCanvas()
  let timeoutId = null

  for (const [id, scene] of Object.entries(sceneMap)) {
    const option = document.createElement('option')
    option.value = id
    option.text = scene.name
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

  // Fullscreen on double-click/tap
  canvas.addEventListener('dblclick', () => {
    if (!document.fullscreenElement) {
      document.documentElement.requestFullscreen()
    } else {
      document.exitFullscreen()
    }
  })
}

// Switches the current scene by updating the fragment shader.
export async function switchScene(sceneId) {
  const scene = sceneMap[sceneId]
  if (!scene) {
    console.error(`Scene ${sceneId} not found!`)
    return
  }

  fullScreenBuffInfo = twgl.createBufferInfoFromArrays(gl, {
    position: [-1, -1, 0, 1, -1, 0, -1, 1, 0, -1, 1, 0, 1, -1, 0, 1, 1, 0],
  })

  // Camera
  switch (scene.camera.type) {
    case 'orbit':
      camera = new CameraOrbital(scene.camera.target, scene.camera.fov, getCanvas(), scene.camera.pitch, -0.3, scene.camera.radius)

      // Optional minPitch parameter
      if (scene.camera.minPitch !== undefined) {
        camera.minPitch = scene.camera.minPitch
      }
      break
    case 'directional':
      camera = new CameraDirectional(scene.camera.position, scene.camera.target, scene.camera.direction, scene.camera.speed, scene.camera.fov, gl.canvas.width / gl.canvas.height)
      break

    default:
      console.error(`Unknown camera type: ${scene.camera.type}`)
      return
  }

  // Dynamically fetch and preprocess the fragment shader for the scene
  const sceneFrag = preprocessor(tempSceneShaderMap[scene.shaderUrl])
  // try {
  //   sceneFrag = preprocessor(await fetchShader(scene.shaderUrl))
  //   console.log(`Loaded shader for scene: ${scene.name}`)
  // } catch (err) {
  //   console.error(`Error loading shader for scene ${scene.name}:`, err)
  //   return
  // }

  progInfo = twgl.createProgramInfo(gl, [vertShader, sceneFrag], (err) => {
    console.error('Shader program creation error:', err)
  })

  // May move some of this to the render loop later
  gl.useProgram(progInfo.program)
  twgl.setBuffersAndAttributes(gl, progInfo, fullScreenBuffInfo)

  // append scene id to url fragment
  const url = new URL(window.location.toString())
  url.hash = `#${sceneId}`
  window.history.replaceState({}, '', url)
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

  camera.update(ts)

  // Update uniforms with new camera data
  uniforms.u_inverseViewProjectionMatrix = camera.inverseViewProjectionMatrix
  uniforms.u_cameraPos = camera.pos

  twgl.setUniforms(progInfo, uniforms)
  twgl.drawBufferInfo(gl, fullScreenBuffInfo)

  updateStats(ts) // only for FPS tracking, not strictly necessary
  requestAnimationFrame(render)
}

// =========================================================================
// 🪧 ENTRYPOINT HERE 🚦
// =========================================================================
initUI()

if (window.location.hash) {
  const sceneId = window.location.hash.substring(1)
  if (sceneMap[sceneId]) {
    const sceneSelector = /** @type {HTMLSelectElement} */ (document.querySelector('select'))
    sceneSelector.value = sceneId
    switchScene(sceneId)
  }
} else {
  switchScene('s1')
}

render(0)
