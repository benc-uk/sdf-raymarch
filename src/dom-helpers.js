export function hide(el) {
  el.style.display = 'none'
}

export function show(el) {
  el.style.display = 'block'
}

export function toggle(el) {
  if (el.style.display === 'none' || getComputedStyle(el).display === 'none') {
    el.style.display = 'block'
  } else {
    el.style.display = 'none'
  }
}
