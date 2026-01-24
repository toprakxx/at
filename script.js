
const canvas = document.getElementById("surface");
const ctx = canvas.getContext("2d");


///////////// start of zig interface
export function js_print(strPtr, keyLen) {
  const strArr = new Uint8Array(wasm.memory.buffer, strPtr, keyLen);
  const str = new TextDecoder().decode(strArr);
  console.log(str)
}
export function updateCanvas() {
  ctx.putImageData(imageData, 0, 0);
}

///////////// end of zig interface



let wasm = null;
let imageData = null;


function createCanvasImage() {
  canvas.width = wasm.canvas_getWidth();
  canvas.height = wasm.canvas_getHeight();

  const bufferPtr = wasm.canvas_getBuffer();
  const pixelData = new Uint8ClampedArray(wasm.memory.buffer, bufferPtr, canvas.width * canvas.height * 4);
  imageData = new ImageData(pixelData, canvas.width, canvas.height);
}

async function init() {
  setupKbInput();
  const { instance } = await WebAssembly.instantiateStreaming(
    fetch("zig-out/bin/bfgame.wasm"),
    {
      env:
        // FIXME add exported zig functions from the interface part to here
        // bunu yapmanin daha iyi bi yolu varsa direk enve fln koyucak yapsana
        // aslinda ai a sormak lazim
        { js_print, updateCanvas }
    }
  );
  wasm = instance.exports;
  wasm.interface_init();
  createCanvasImage();
  wasm.canvas_clearBuffer();
  requestAnimationFrame(gameloop);
}
function gameloop() {
  wasm.update();
  updateCanvas();
}


// IO

function getKbKeyVal(code) {
  switch (code) {
    case 'Backspace': return 8;
    case 'Tab': return 9;
    case 'Enter': return 13;
    case 'NumpadEnter': return 13;
    case 'ShiftLeft': return 16;
    case 'ShiftRight': return 16;
    case 'ControlLeft': return 17;
    case 'ControlRight': return 17;
    case 'AltLeft': return 18;
    case 'AltRight': return 18;
    case 'Pause': return 19;
    case 'CapsLock': return 20;
    case 'Escape': return 27;
    case 'Space': return 32;
    case 'PageUp': return 138;
    case 'PageDown': return 139;
    case 'End': return 140;
    case 'Home': return 141;
    case 'ArrowLeft': return 142;
    case 'ArrowUp': return 143;
    case 'ArrowRight': return 144;
    case 'ArrowDown': return 145;
    case 'Insert': return 146;
    case 'Comma': return 44;
    case 'Minus': return 45;
    case 'Period': return 46;
    case 'Slash': return 47;
    case 'Digit0': return 48;
    case 'Digit1': return 49;
    case 'Digit2': return 50;
    case 'Digit3': return 51;
    case 'Digit4': return 52;
    case 'Digit5': return 53;
    case 'Digit6': return 54;
    case 'Digit7': return 55;
    case 'Digit8': return 56;
    case 'Digit9': return 57;
    case 'Semicolon': return 59;
    case 'Equal': return 61;
    case 'Quote': return 39;
    case 'KeyA': return 65;
    case 'KeyB': return 66;
    case 'KeyC': return 67;
    case 'KeyD': return 68;
    case 'KeyE': return 69;
    case 'KeyF': return 70;
    case 'KeyG': return 71;
    case 'KeyH': return 72;
    case 'KeyI': return 73;
    case 'KeyJ': return 74;
    case 'KeyK': return 75;
    case 'KeyL': return 76;
    case 'KeyM': return 77;
    case 'KeyN': return 78;
    case 'KeyO': return 79;
    case 'KeyP': return 80;
    case 'KeyQ': return 81;
    case 'KeyR': return 82;
    case 'KeyS': return 83;
    case 'KeyT': return 84;
    case 'KeyU': return 85;
    case 'KeyV': return 86;
    case 'KeyW': return 87;
    case 'KeyX': return 88;
    case 'KeyY': return 89;
    case 'KeyZ': return 90;
    case 'BracketLeft': return 91;
    case 'Backslash': return 92;
    case 'BracketRight': return 93;
    case 'Backquote': return 96;
    case 'F1': return 112;
    case 'F2': return 113;
    case 'F3': return 114;
    case 'F4': return 115;
    case 'F5': return 116;
    case 'F6': return 117;
    case 'F7': return 118;
    case 'F8': return 119;
    case 'F9': return 120;
    case 'F10': return 121;
    case 'F11': return 122;
    case 'F12': return 123;
    case 'Delete': return 127;
    case 'Super': return 157;
    default: return 0;
  }
}

function setupKbInput() {

  window.addEventListener("keydown", (e) => {
    const key = getKbKeyVal(e.code);
    wasm.keyboard_keyDown(key);
    const keyMap = [
      8, 9, 13, 13, 16, 16, 17, 17, 18, 18, 19, 20, 27, 32, 33, 34, 35, 36, 37, 38, 39, 40, 45, 
      44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 59, 61, 39, 65, 66, 67, 68, 69, 
      70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 
      92, 93, 96, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123,127, 157,
    ];
    if (keyMap.includes(key)) {
      e.preventDefault();
    }

  });
  window.addEventListener("keyup", (e) => {
    key = getKbKeyVal(e.code);
    wasm.keyboard_keyUp(key);
  });
}



// start execution
init();
