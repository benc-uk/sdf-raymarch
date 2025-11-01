// ==========================================================================
// Orbital Camera Class
// (C) Ben Coleman 2025
// License: MIT (see LICENSE file)
// Orbital camera with mouse controls for WebGL applications
// ==========================================================================

import { Camera } from './camera.js'

export class CameraOrbital extends Camera {
  #angleTheta = 0
  #anglePhi = 0
  #mouseLocked = false
  #lastTouchX = null
  #lastTouchY = null

  radius = 5
  minPitch = 0.0

  /**
   * @param {[number, number, number]} target - Point camera is orbiting around
   * @param {number} fov - Field of view in radians
   * @param {HTMLCanvasElement} canvas - Canvas element for mouse events
   * @param {number} pitch - Initial pitch angle in radians
   * @param {number} radius - Initial orbit radius
   */
  constructor(target, fov, canvas, pitch, radius) {
    super([0, 0, 0], target, fov, canvas.width / canvas.height)
    this.radius = radius
    this.#anglePhi = pitch

    // grab mouse movement to rotate camera
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
        this.#angleTheta += movementX * 0.002

        const movementY = e.movementY || 0
        this.#anglePhi += movementY * 0.002

        // Clamp phi angle to avoid flipping at poles
        const maxPhi = Math.PI / 2 - 0.01
        const minPhi = -maxPhi
        this.#anglePhi = Math.max(minPhi, Math.min(maxPhi, this.#anglePhi))

        if (this.#anglePhi < this.minPitch) {
          this.#anglePhi = this.minPitch
        }

        this.update()
      }
    })

    canvas.addEventListener('touchmove', (e) => {
      if (e.touches.length === 1) {
        const touch = e.touches[0]
        const movementX = touch.clientX - (this.#lastTouchX || touch.clientX)
        const movementY = touch.clientY - (this.#lastTouchY || touch.clientY)

        this.#angleTheta += movementX * 0.01
        this.#anglePhi += movementY * 0.01

        // Clamp phi angle to avoid flipping at poles
        const maxPhi = Math.PI / 2 - 0.01
        const minPhi = -maxPhi
        this.#anglePhi = Math.max(minPhi, Math.min(maxPhi, this.#anglePhi))

        if (this.#anglePhi < this.minPitch) {
          this.#anglePhi = this.minPitch
        }

        this.update()

        this.#lastTouchX = touch.clientX
        this.#lastTouchY = touch.clientY
      }
    })

    canvas.addEventListener('wheel', (e) => {
      e.preventDefault()
      this.radius += e.deltaY * 0.006
      this.radius = Math.max(1, this.radius) // Prevent radius from going below 1
      this.update()
    })

    this.update()
  }

  update() {
    this.pos = [
      this.radius * Math.sin(this.#angleTheta) * Math.cos(this.#anglePhi) + this.target[0],
      this.radius * Math.sin(this.#anglePhi) + this.target[1],
      this.radius * Math.cos(this.#angleTheta) * Math.cos(this.#anglePhi) + this.target[2],
    ]
  }
}
