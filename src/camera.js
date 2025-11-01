// ==========================================================================
// Camera class
// (C) Ben Coleman 2025
// License: MIT (see LICENSE file)
// Simple camera implementation for WebGL applications
// With position, target, fov and aspect ratio and mouse/touch controls
// ==========================================================================

import * as twgl from 'twgl.js'

export default class Camera {
  #pos = [0, 0, 0]
  #target = [0, 0, -1]
  #fov = Math.PI / 4
  #up = [0, 1, 0]
  #aspectRatio = 1
  #viewMatrix = null
  #projectionMatrix = null
  #viewProjectionMatrix = null
  #inverseViewProjectionMatrix = null

  // Used for mouse/touch controls only
  #mouseLocked
  #lastTouchX
  #lastTouchY

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
    const cameraMatrix = twgl.m4.lookAt(this.#pos, this.#target, this.#up)
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

  /**
   * Enable mouse and touch controls for the camera, this is overridden in subclasses
   * @param {HTMLCanvasElement} canvas Canvas to capture and handle movements
   * @param {(moveX:number, moveY:number, wheel:number) => void} moveCallback
   */
  addMouseAndTouchControls(canvas, moveCallback) {
    canvas.addEventListener('click', () => {
      if (!this.#mouseLocked) {
        canvas.requestPointerLock()
        this.#mouseLocked = true
      } else {
        document.exitPointerLock()
        this.#mouseLocked = false
      }
    })

    canvas.addEventListener('mousemove', (e) => {
      if (document.pointerLockElement === canvas) {
        const movementX = e.movementX || 0
        const movementY = e.movementY || 0

        moveCallback(movementX, movementY, 0)
      }
    })

    canvas.addEventListener('touchmove', (e) => {
      if (e.touches.length === 1) {
        const touch = e.touches[0]
        const movementX = touch.clientX - (this.#lastTouchX || touch.clientX)
        const movementY = touch.clientY - (this.#lastTouchY || touch.clientY)

        moveCallback(movementX, movementY, 0)

        this.#lastTouchX = touch.clientX
        this.#lastTouchY = touch.clientY
      }
    })

    canvas.addEventListener('wheel', (e) => {
      moveCallback(0, 0, e.deltaY)
    })
  }
}
