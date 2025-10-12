// ==========================================================================
// Camera class
// Handles position, orientation, and movement based on user controls
// ==========================================================================

import * as twgl from 'twgl.js'

export class Camera {
  #pos
  #target
  #fov
  #up
  #aspectRatio

  /**
   * @param {[number, number, number]} pos - Camera position
   * @param {[number, number, number]} target - Point camera is looking at
   * @param {number} fov - Field of view in radians
   * @param {number} aspectRatio - Aspect ratio of the viewport
   */
  constructor(pos, target, fov, aspectRatio) {
    this.#pos = pos
    this.#target = target
    this.#fov = fov
    this.#up = [0, 1, 0]
    this.#aspectRatio = aspectRatio

    // Matrix properties
    this.viewMatrix = null
    this.projectionMatrix = null
    this.viewProjectionMatrix = null
    this.inverseViewProjectionMatrix = null

    // Initialize matrices
    this.updateProjectionMatrix(aspectRatio)
    this.updateViewMatrix()
  }

  /**
   * @param {number} aspectRatio
   */
  updateProjectionMatrix(aspectRatio) {
    this.projectionMatrix = twgl.m4.perspective(this.#fov, aspectRatio, 0.1, 100)
    this.updateViewProjectionMatrix()
  }

  updateViewMatrix() {
    const cameraMatrix = twgl.m4.lookAt(this.pos, this.target, this.#up)
    this.viewMatrix = twgl.m4.inverse(cameraMatrix)
    this.updateViewProjectionMatrix()
  }

  updateViewProjectionMatrix() {
    if (this.projectionMatrix && this.viewMatrix) {
      this.viewProjectionMatrix = twgl.m4.multiply(this.projectionMatrix, this.viewMatrix)
      this.inverseViewProjectionMatrix = twgl.m4.inverse(this.viewProjectionMatrix)
    }
  }

  get pos() {
    return this.#pos
  }

  set pos(newPos) {
    this.#pos = newPos
    this.updateViewMatrix()
  }

  get target() {
    return this.#target
  }

  set target(newTarget) {
    this.#target = newTarget
    this.updateViewMatrix()
  }

  set fov(newFov) {
    this.#fov = newFov
    this.updateProjectionMatrix(this.projectionMatrix[0] / this.projectionMatrix[5])
  }

  get fov() {
    return this.#fov
  }

  get aspectRatio() {
    return this.#aspectRatio
  }

  update() {
    // Placeholder for future movement/rotation logic
  }
}
