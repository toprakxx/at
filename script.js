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
const textEncoder = new TextEncoder();

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
const keysDown = new Uint8Array(256);

function setupKbInput() {
  window.addEventListener("keydown", (e) => {
    const code = keyCodeMap[e.code];
    if (code !== undefined) {
      e.preventDefault();
      keysDown[code] = 1;
    }
  });
  window.addEventListener("keyup", (e) => {
    const code = keyCodeMap[e.code];
    if (code !== undefined) {
      e.preventDefault();
      keysDown[code] = 0;
    }
  });
}

function allocString(str) {
    const bytes = textEncoder.encode(str);
    const ptr = wasm.alloc(bytes.length);
    if (!ptr) throw new Error("OOM");
    const buffer = new Uint8Array(wasmMemory.buffer, ptr, bytes.length);
    buffer.set(bytes);
    return { ptr, len: bytes.length };
}

let sceneNamePtr = 0;
let sceneNameLen = 0;
let entityId = 0;
let cubeRot = 0.0;
let rotPtr = 0; // buffer for rotation data

async function init() {
  setupKbInput();
  const { instance } = await WebAssembly.instantiateStreaming(
    fetch("zig-out/bin/bfgame.wasm"),
    { env: { js_print, updateCanvas } }
  );
  
  wasm = instance.exports;
  wasmMemory = wasm.memory;
  
  if (!wasm.interface_init()) {
      console.error("Failed to init interface");
      return;
  }
  
  // Create Scene
  const sceneName = "Main";
  const str = allocString(sceneName);
  sceneNamePtr = str.ptr;
  sceneNameLen = str.len;
  wasm.renderer_add_scene(sceneNamePtr, sceneNameLen);

  // Load OBJ
  const response = await fetch("testmodel.obj"); // Ensure this file exists or use dummy data if not
  const objText = await response.text();
  const objBytes = textEncoder.encode(objText);
  
  const objPtr = wasm.alloc(objBytes.length);
  new Uint8Array(wasmMemory.buffer, objPtr, objBytes.length).set(objBytes);
  
  // Load Entity
  entityId = wasm.load_obj(sceneNamePtr, sceneNameLen, objPtr, objBytes.length);
  
  wasm.free(objPtr, objBytes.length);
  // Keep sceneNamePtr allocated for later use
  
  // Alloc rotation buffer
  rotPtr = wasm.alloc(4 * 4); // 4 floats * 4 bytes
  
  canvasWidth = wasm.canvas_getWidth();
  canvasHeight = wasm.canvas_getHeight();
  byteLength = canvasWidth * canvasHeight * 4;
  
  canvas.width = canvasWidth;
  canvas.height = canvasHeight;
  imageDataBuffer = ctx.createImageData(canvasWidth, canvasHeight);
  
  wasm.canvas_clearBuffer();
  requestAnimationFrame(gameloop);
}

// Simple quaternion from axis angle helper
function quatFromAxisAngle(x, y, z, angle, outDist) {
    const halfAngle = angle * 0.5;
    const s = Math.sin(halfAngle);
    outDist[0] = x * s;
    outDist[1] = y * s;
    outDist[2] = z * s;
    outDist[3] = Math.cos(halfAngle);
}

function multiplyQuaternions(q1, q2, out) {
    const x =  q1[0] * q2[3] + q1[1] * q2[2] - q1[2] * q2[1] + q1[3] * q2[0];
    const y = -q1[0] * q2[2] + q1[1] * q2[3] + q1[2] * q2[0] + q1[3] * q2[1];
    const z =  q1[0] * q2[1] - q1[1] * q2[0] + q1[2] * q2[3] + q1[3] * q2[2];
    const w = -q1[0] * q2[0] - q1[1] * q2[1] - q1[2] * q2[2] + q1[3] * q2[3];
    out[0] = x; out[1] = y; out[2] = z; out[3] = w;
}


function gameloop() {
  if (keysDown[keyCodeMap.KeyW]) {
      cubeRot += 0.05;
  }
  if (keysDown[keyCodeMap.KeyS]) {
      cubeRot -= 0.05;
  }
  cubeRot += 0.02;

  // Calculate rotation (JS equivalent of logic in Zig)
  // mesh.rotation = zm.quatFromAxisAngle(zm.f32x4(0.0, 1.0, 0.0, 0.0), cube_rot);
  // mesh.rotation = zm.qmul(mesh.rotation, zm.quatFromAxisAngle(zm.f32x4(1.0, 0.0, 0.0, 0.0), cube_rot * 0.5));
  
  const q1 = new Float32Array(4);
  const q2 = new Float32Array(4);
  const finalQ = new Float32Array(4);
  
  quatFromAxisAngle(0, 1, 0, cubeRot, q1);
  quatFromAxisAngle(1, 0, 0, cubeRot * 0.5, q2);
  multiplyQuaternions(q1, q2, finalQ);
  
  // Send to WASM
  const rotBuf = new Float32Array(wasmMemory.buffer, rotPtr, 4);
  rotBuf.set(finalQ);
  
  wasm.modify_entity_feature(sceneNamePtr, sceneNameLen, entityId, 1, rotPtr); // 1 = Rotation
  
  wasm.update();
  updateCanvas();
  requestAnimationFrame(gameloop);
}

// ─── 2D API ──────────────────────────────────────────────────────────────────
// color is 0xRRGGBBAA  (e.g. 0xFF0000FF = opaque red)
// All functions take pre-allocated scenePtr/sceneLen to avoid per-call alloc.
// Use allocString(sceneName) once and cache the result.

export function createRect(scenePtr, sceneLen, x, y, w, h, color) {
    return wasm.rect2d_create(scenePtr, sceneLen, x, y, w, h, color >>> 0);
}

// rgbaBytes: Uint8Array of raw RGBA pixels (e.g. from ImageData.data or a canvas).
// The bytes are copied into WASM memory; caller does NOT need to keep them alive.
// Returns { id, ptr } — keep ptr to free later with wasm.free(ptr, bytes.length).
export function createSprite(scenePtr, sceneLen, x, y, w, h, rgbaBytes, texW, texH) {
    const ptr = wasm.alloc(rgbaBytes.length);
    if (!ptr) throw new Error("OOM");
    new Uint8Array(wasmMemory.buffer, ptr, rgbaBytes.length).set(rgbaBytes);
    const id = wasm.sprite_create(scenePtr, sceneLen, x, y, w, h, ptr, texW, texH);
    return { id, ptr };
}

export function setPos2D(scenePtr, sceneLen, entityId, x, y) {
    wasm.entity2d_set_pos(scenePtr, sceneLen, entityId, x, y);
}

export function setRectColor(scenePtr, sceneLen, entityId, color) {
    wasm.rect2d_set_color(scenePtr, sceneLen, entityId, color >>> 0);
}

// Upload new texture bytes to an existing sprite (e.g. for animation frames).
// Returns the new ptr so the old one can be freed: wasm.free(oldPtr, oldLen).
export function setSpriteTexture(scenePtr, sceneLen, entityId, rgbaBytes, texW, texH) {
    const ptr = wasm.alloc(rgbaBytes.length);
    if (!ptr) throw new Error("OOM");
    new Uint8Array(wasmMemory.buffer, ptr, rgbaBytes.length).set(rgbaBytes);
    wasm.sprite_set_texture(scenePtr, sceneLen, entityId, ptr, texW, texH);
    return ptr;
}

// ─── Tilemap API ─────────────────────────────────────────────────────────────
// .atmap text is loaded via fetch/FileReader, then passed here.
// Tileset bytes come from an <img> drawn onto a 2D canvas → ImageData.

// Load an .atmap string into a scene, returns entity id.
export function loadTilemap(scenePtr, sceneLen, atmap_text) {
    const bytes = textEncoder.encode(atmap_text);
    const ptr = wasm.alloc(bytes.length);
    if (!ptr) throw new Error("OOM");
    new Uint8Array(wasmMemory.buffer, ptr, bytes.length).set(bytes);
    const id = wasm.tilemap_load(scenePtr, sceneLen, ptr, bytes.length);
    wasm.free(ptr, bytes.length);
    return id;
}

// Create an empty tilemap. Layers default to no-collision, all tiles 0.
export function createTilemap(scenePtr, sceneLen, tileW, tileH, mapW, mapH, numLayers) {
    return wasm.tilemap_create(scenePtr, sceneLen, tileW, tileH, mapW, mapH, numLayers);
}

// Set RGBA bytes on a specific tileset slot (0-based).
// Returns the WASM ptr (keep alive; free when done).
export function setTileset(scenePtr, sceneLen, entityId, slot, rgbaBytes, tsW, tsH, tsCols) {
    const ptr = wasm.alloc(rgbaBytes.length);
    if (!ptr) throw new Error("OOM");
    new Uint8Array(wasmMemory.buffer, ptr, rgbaBytes.length).set(rgbaBytes);
    wasm.tilemap_set_tileset(scenePtr, sceneLen, entityId, slot, ptr, tsW, tsH, tsCols);
    return ptr;
}

// Append a new tileset and return its index (or -1 if at capacity).
export function addTileset(scenePtr, sceneLen, entityId, rgbaBytes, tsW, tsH, tsCols) {
    const ptr = wasm.alloc(rgbaBytes.length);
    if (!ptr) throw new Error("OOM");
    new Uint8Array(wasmMemory.buffer, ptr, rgbaBytes.length).set(rgbaBytes);
    const idx = wasm.tilemap_add_tileset(scenePtr, sceneLen, entityId, ptr, tsW, tsH, tsCols);
    return (idx >>> 0) === 0xFFFFFFFF ? -1 : idx;
}

// Assign which tileset a layer uses.
export function setLayerTileset(scenePtr, sceneLen, entityId, layer, tilesetIdx) {
    wasm.tilemap_set_layer_tileset(scenePtr, sceneLen, entityId, layer, tilesetIdx);
}

export function setTile(scenePtr, sceneLen, entityId, layer, tx, ty, tileId) {
    wasm.tilemap_set_tile(scenePtr, sceneLen, entityId, layer, tx, ty, tileId);
}

export function getTile(scenePtr, sceneLen, entityId, layer, tx, ty) {
    return wasm.tilemap_get_tile(scenePtr, sceneLen, entityId, layer, tx, ty);
}

// Scroll the tilemap (pixel offset applied before rendering).
export function setTilemapOffset(scenePtr, sceneLen, entityId, ox, oy) {
    wasm.tilemap_set_offset(scenePtr, sceneLen, entityId, ox, oy);
}

// Returns true if AABB (world pixels) overlaps a solid tile.
export function tilemapCollides(scenePtr, sceneLen, entityId, x, y, w, h) {
    return wasm.tilemap_collides(scenePtr, sceneLen, entityId, x, y, w, h) !== 0;
}

export function setLayerCollision(scenePtr, sceneLen, entityId, layer, enabled) {
    wasm.tilemap_set_layer_collision(scenePtr, sceneLen, entityId, layer, enabled ? 1 : 0);
}

init();
  
