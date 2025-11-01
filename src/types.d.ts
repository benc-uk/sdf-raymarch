declare module '*?raw' {
  const content: string
  export default content
}

declare module '*.json' {
  const content: string
  export default content
}

declare interface CameraBase {
  pos: [number, number, number]
  target: [number, number, number]
  fov: number
  aspectRatio: number
  inverseViewProjectionMatrix: Float32Array
  addMouseAndTouchControls(canvas: HTMLCanvasElement, moveCallback: (moveX: number, moveY: number, wheel: number) => void): void
}
