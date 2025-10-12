import vertShader from '../shaders/main.vert.glsl?raw'
import fragShader from '../shaders/main.frag.glsl?raw'

import * as twgl from 'twgl.js'

import { initGL } from './gl.js'
import { Camera } from './camera.js'

const gl = initGL('canvas', {
  width: 400,
  height: 600,
  fitToContainer: true,
  resizeCanvas: true,
})

const fullScreenBuffInfo = twgl.createBufferInfoFromArrays(gl, {
  position: [-1, -1, 0, 1, -1, 0, -1, 1, 0, -1, 1, 0, 1, -1, 0, 1, 1, 0],
})
const progInfo = twgl.createProgramInfo(gl, [vertShader, fragShader])

const camera = new Camera([0, 0, 3], [0, 2.0, -10], (50 * Math.PI) / 180, gl.canvas.width / gl.canvas.height)

const uniforms = {
  u_resolution: [gl.canvas.width, gl.canvas.height],
  u_aspect: gl.canvas.width / gl.canvas.height,
  u_inverseViewProjectionMatrix: camera.inverseViewProjectionMatrix,
  u_camPos: camera.pos,
  u_time: 0,
}

// May move some of this to the render loop later
gl.useProgram(progInfo.program)
twgl.setBuffersAndAttributes(gl, progInfo, fullScreenBuffInfo)

// Classic WebGL render loop
function render(ts) {
  uniforms.u_time = ts * 0.001
  twgl.setUniforms(progInfo, uniforms)
  twgl.drawBufferInfo(gl, fullScreenBuffInfo)

  requestAnimationFrame(render)
}

render(0)
