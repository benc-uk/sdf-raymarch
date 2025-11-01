// ==========================================================================
// Camera class
// (C) Ben Coleman 2025
// License: MIT (see LICENSE file)
// Simple camera implementation for WebGL applications
// ==========================================================================

import * as twgl from 'twgl.js'

export class Camera {
  #pos = [0, 0, 0]
  #target = [0, 0, -1]
  #fov = Math.PI / 4
  #up = [0, 1, 0]
  #aspectRatio = 1
  #viewMatrix = null
  #projectionMatrix = null
  #viewProjectionMatrix = null
  #inverseViewProjectionMatrix = null

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

    // Matrix properties, initialized to identity
    this.#viewMatrix = twgl.m4.identity()
    this.#projectionMatrix = twgl.m4.identity()
    this.#viewProjectionMatrix = twgl.m4.identity()
    this.#inverseViewProjectionMatrix = twgl.m4.identity()

    // Initialize matrices
    this._updateProjectionMatrix(aspectRatio)
    this._updateViewMatrix()
  }

  /**
   * @param {number} aspectRatio
   */
  _updateProjectionMatrix(aspectRatio) {
    this.#projectionMatrix = twgl.m4.perspective(this.#fov, aspectRatio, 0.1, 100)
    this._updateViewProjectionMatrix()
  }

  _updateViewMatrix() {
    const cameraMatrix = twgl.m4.lookAt(this.pos, this.target, this.#up)
    this.#viewMatrix = twgl.m4.inverse(cameraMatrix)
    this._updateViewProjectionMatrix()
  }

  _updateViewProjectionMatrix() {
    if (this.#projectionMatrix && this.#viewMatrix) {
      this.#viewProjectionMatrix = twgl.m4.multiply(this.#projectionMatrix, this.#viewMatrix)
      this.#inverseViewProjectionMatrix = twgl.m4.inverse(this.#viewProjectionMatrix)
    }
  }

  get pos() {
    return this.#pos
  }

  set pos(newPos) {
    this.#pos = newPos
    this._updateViewMatrix()
  }

  get target() {
    return this.#target
  }

  set target(newTarget) {
    this.#target = newTarget
    this._updateViewMatrix()
  }

  set fov(newFov) {
    this.#fov = newFov
    this._updateProjectionMatrix(this.#projectionMatrix[0] / this.#projectionMatrix[5])
  }

  get fov() {
    return this.#fov
  }

  get aspectRatio() {
    return this.#aspectRatio
  }

  get inverseViewProjectionMatrix() {
    return this.#inverseViewProjectionMatrix
  }
}
