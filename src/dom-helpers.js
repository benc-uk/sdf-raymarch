// ============================================================================================
// DOM Mini Library
// (C) Ben Coleman 2025
// License: MIT (see LICENSE file)
// Just some simple DOM helper functions
// ============================================================================================

/**
 * Simple display helper
 * @param {HTMLElement} el
 */
export function hide(el) {
  el.style.visibility = 'hidden'
}

/**
 * Simple  display helper
 * @param {HTMLElement} el
 */
export function show(el) {
  el.style.visibility = 'visible'
}

/**
 * Simple display helper
 * @param {HTMLElement} el
 */
export function toggle(el) {
  if (el.style.display === 'none' || getComputedStyle(el).display === 'none') {
    el.style.display = 'block'
  } else {
    el.style.display = 'none'
  }
}

/**
 * Helper to get canvas element typed as HTMLCanvasElement
 * @param {string} selector
 * @returns {HTMLCanvasElement}
 */
export function getCanvas(selector) {
  return /** @type {HTMLCanvasElement} */ (document.querySelector(selector || 'canvas'))
}

/**
 * Helper to get select element typed as HTMLSelectElement
 * @param {string} selector
 * @returns {HTMLSelectElement}
 */
export function getSelect(selector) {
  return /** @type {HTMLSelectElement} */ (document.querySelector(selector))
}

export function getElement(selector) {
  return /** @type {HTMLElement} */ (document.querySelector(selector))
}

/**
 * Helper to get button element typed as HTMLButtonElement
 * @param {string} selector
 * @returns {HTMLButtonElement}
 */
export function getButton(selector) {
  return /** @type {HTMLButtonElement} */ (document.querySelector(selector))
}

/**
 *
 * @param {HTMLSelectElement} selectEl
 * @returns {string}
 */
export function getSelectedValue(selectEl) {
  return selectEl.options[selectEl.selectedIndex].value
}

/**
 * Remove element from DOM
 * @param {string} selector
 */
export function remove(selector) {
  const el = document.querySelector(selector)
  if (el && el.parentNode) {
    el.parentNode.removeChild(el)
  }
}
