// ==========================================================================
// Directional Camera Class
// (C) Ben Coleman 2025
// License: MIT (see LICENSE file)
// Camera that moves in a fixed direction
// ==========================================================================

import Camera from './camera.js'

export default class CameraDirectional extends Camera {
  #direction = [0, 0, 0]
  speed = 0.1
  #startPos = null
  #startTarget = null

  /**
   * @param {[number, number, number]} pos - Camera position
   * @param {[number, number, number]} target - Point camera is looking at
   * @param {[number, number, number]} direction - Direction of movement
   * @param {number} speed - Movement speed
   * @param {number} fov - Field of view in radians
   * @param {number} aspectRatio - Aspect ratio of the viewport
   */
  constructor(pos, target, direction, speed, fov, aspectRatio) {
    console.log(`input ${pos} ${target} ||| ${direction}`)

    super(pos, target, fov, aspectRatio)

    // normalize moveDir
    const len = Math.hypot(direction[0], direction[1], direction[2])
    direction = [direction[0] / len, direction[1] / len, direction[2] / len]

    this.#direction = direction
    this.#startPos = [...pos]
    this.#startTarget = [...target]

    this.speed = speed
  }

  /**
   * Update camera position based on direction and speed
   * @param {number} ts - Timestamp in absolute milliseconds
   */
  update(ts) {
    ts *= 0.001

    // modulate direction using sin wave for more interesting movement

    this.pos = [
      this.#startPos[0] + this.#direction[0] * this.speed * ts,
      this.#startPos[1] + this.#direction[1] * this.speed * ts,
      this.#startPos[2] + this.#direction[2] * this.speed * ts,
    ]

    this.target = [
      this.#startTarget[0] + this.#direction[0] * this.speed * ts,
      this.#startTarget[1] + this.#direction[1] * this.speed * ts,
      this.#startTarget[2] + this.#direction[2] * this.speed * ts,
    ]

    // move lookat target up and down with a sine wave for a bit of variety
    const waveHeight = Math.sin(ts * 0.6) * 2.0
    this.target[0] += waveHeight

    super._updateViewMatrix()
  }
}
