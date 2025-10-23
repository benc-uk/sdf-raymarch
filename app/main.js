import vertShader from '../shaders/main.vert.glsl?raw'
import scene1Frag from '../shaders/scene1.frag.glsl?raw'
// import scene2Frag from '../shaders/scene2.frag.glsl?raw'
import sdfLibFrag from '../shaders/sdf-lib.frag.glsl?raw'

import * as twgl from 'twgl.js'
import { initGL } from './gl.js'
import { Camera } from './camera.js'

const gl = initGL('canvas', {
  width: 640,
  height: 480,
  fitToContainer: true,
  resizeCanvas: true,
})

function prependSdfLib(shaderSrc) {
  return shaderSrc.replace('#include "sdf-lib.frag.glsl"', sdfLibFrag)
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
}

let progInfo
let fullScreenBuffInfo

// Classic WebGL render loop
function render(ts) {
  uniforms.u_time = ts * 0.001
  twgl.setUniforms(progInfo, uniforms)
  twgl.drawBufferInfo(gl, fullScreenBuffInfo)

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

document.querySelector('select').addEventListener('change', (e) => {
  //@ts-ignore
  const scene = e.target.value
  console.log(`Switching to scene: ${scene}`)
  switchScene(scene)
})

switchScene('scene1')
render()
