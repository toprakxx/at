const canvas = document.getElementById("surface");
const ctx = canvas.getContext("2d", { alpha: false }); // disable alpha for perf

// Cached values 
let wasm = null;
let wasmMemory = null;
let imageDataBuffer = null;
let canvasWidth = 0;
let canvasHeight = 0;
let byteLength = 0;

const textDecoder = new TextDecoder();

export function js_print(strPtr, keyLen) {
  console.log(textDecoder.decode(new Uint8Array(wasmMemory.buffer, strPtr, keyLen)));
}

export function updateCanvas() {
  const bufferPtr = wasm.canvas_getBuffer();
  // Use set() with subarray for fast bulk copy
  imageDataBuffer.data.set(new Uint8ClampedArray(wasmMemory.buffer, bufferPtr, byteLength));
  ctx.putImageData(imageDataBuffer, 0, 0);
}

///////////// end of zig interface

// key cde lookup
const keyCodeMap = {
  Backspace: 8, Tab: 9, Enter: 13, NumpadEnter: 13,
  ShiftLeft: 16, ShiftRight: 16, ControlLeft: 17, ControlRight: 17,
  AltLeft: 18, AltRight: 18, Pause: 19, CapsLock: 20, Escape: 27, Space: 32,
  PageUp: 138, PageDown: 139, End: 140, Home: 141,
  ArrowLeft: 142, ArrowUp: 143, ArrowRight: 144, ArrowDown: 145, Insert: 146,
  Comma: 44, Minus: 45, Period: 46, Slash: 47,
  Digit0: 48, Digit1: 49, Digit2: 50, Digit3: 51, Digit4: 52,
  Digit5: 53, Digit6: 54, Digit7: 55, Digit8: 56, Digit9: 57,
  Semicolon: 59, Equal: 61, Quote: 39,
  KeyA: 65, KeyB: 66, KeyC: 67, KeyD: 68, KeyE: 69, KeyF: 70, KeyG: 71,
  KeyH: 72, KeyI: 73, KeyJ: 74, KeyK: 75, KeyL: 76, KeyM: 77, KeyN: 78,
  KeyO: 79, KeyP: 80, KeyQ: 81, KeyR: 82, KeyS: 83, KeyT: 84, KeyU: 85,
  KeyV: 86, KeyW: 87, KeyX: 88, KeyY: 89, KeyZ: 90,
  BracketLeft: 91, Backslash: 92, BracketRight: 93, Backquote: 96,
  F1: 112, F2: 113, F3: 114, F4: 115, F5: 116, F6: 117,
  F7: 118, F8: 119, F9: 120, F10: 121, F11: 122, F12: 123,
  Delete: 127, Super: 157
};
const preventDefaultKeys = new Set(Object.values(keyCodeMap));

function setupKbInput() {
  window.addEventListener("keydown", (e) => {
    const key = keyCodeMap[e.code] || 0;
    wasm.keyboard_keyDown(key);
    if (preventDefaultKeys.has(key)) e.preventDefault();
  });
  window.addEventListener("keyup", (e) => {
    wasm.keyboard_keyUp(keyCodeMap[e.code] || 0);
  });
}

async function init() {
  setupKbInput();
  const { instance } = await WebAssembly.instantiateStreaming(
    fetch("zig-out/bin/bfgame.wasm"),
    { env: { js_print, updateCanvas } }
  );
  
  wasm = instance.exports;
  wasmMemory = wasm.memory;
  
  wasm.interface_init();
  
  canvasWidth = wasm.canvas_getWidth();
  canvasHeight = wasm.canvas_getHeight();
  byteLength = canvasWidth * canvasHeight * 4;
  
  canvas.width = canvasWidth;
  canvas.height = canvasHeight;
  imageDataBuffer = ctx.createImageData(canvasWidth, canvasHeight);
  
  wasm.canvas_clearBuffer();
  requestAnimationFrame(gameloop);
}

function gameloop() {
  wasm.update();
  updateCanvas();
  requestAnimationFrame(gameloop);
}

init();
