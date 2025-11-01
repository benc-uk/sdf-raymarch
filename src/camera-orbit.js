// ==========================================================================
// Orbital Camera Class
// (C) Ben Coleman 2025
// License: MIT (see LICENSE file)
// Orbital camera with mouse controls for WebGL applications
// ==========================================================================

import Camera from './camera.js'

export default class CameraOrbital extends Camera {
  angleTheta = 0
  anglePhi = 0
  radius = 5
  minPitch = 0.0

  /**
   * @param {[number, number, number]} target - Point camera is orbiting around
   * @param {number} fov - Field of view in radians
   * @param {HTMLCanvasElement} canvas - Canvas element for mouse events
   * @param {number} pitch - Initial pitch angle in radians
   * @param {number} radius - Initial orbit radius
   */
  constructor(target, fov, canvas, pitch, angle, radius) {
    super([0, 0, 0], target, fov, canvas.width / canvas.height)
    this.radius = radius
    this.anglePhi = pitch
    this.angleTheta = angle

    // grab mouse movement to rotate camera
    this.addMouseAndTouchControls(canvas, (moveX, moveY, wheel) => {
      this.angleTheta += moveX * 0.002
      this.anglePhi += moveY * 0.002

      // Clamp phi angle to avoid flipping at poles
      const maxPhi = Math.PI / 2 - 0.01
      const minPhi = -maxPhi
      this.anglePhi = Math.max(minPhi, Math.min(maxPhi, this.anglePhi))

      if (this.anglePhi < this.minPitch) {
        this.anglePhi = this.minPitch
      }

      // Apply zoom to radius
      this.radius += wheel * 0.01
      if (this.radius < 1.0) this.radius = 1.0

      this.update()
    })

    this.update()
  }

  update() {
    this.pos = [
      this.radius * Math.sin(this.angleTheta) * Math.cos(this.anglePhi) + this.target[0],
      this.radius * Math.sin(this.anglePhi) + this.target[1],
      this.radius * Math.cos(this.angleTheta) * Math.cos(this.anglePhi) + this.target[2],
    ]
  }
}
