
const canvas = document.getElementById("surface");
const ctx = canvas.getContext("2d");


// functions for zig
export function js_print(strPtr, keyLen) {
  const strArr = new Uint8Array(wasm.memory.buffer, strPtr, keyLen);
  const str = new TextDecoder().decode(strArr);
  console.log(str)
}
export function updateCanvas() {
  ctx.putImageData(imageData, 0, 0);
}

let wasm = null;
let imageData = null;


function createCanvasImage() {
  canvas.width = wasm.getCanvasWidth();
  canvas.height = wasm.getCanvasHeight();

  const bufferPtr = wasm.getCanvasBuffer();
  const pixelData = new Uint8ClampedArray(wasm.memory.buffer, bufferPtr, canvas.width * canvas.height * 4);
  imageData = new ImageData(pixelData, canvas.width, canvas.height);
}

async function init() {
  setupKbInput();
  const { instance } = await WebAssembly.instantiateStreaming(
    fetch("zig-out/bin/bfgame.wasm"),
    {
      env:
        { js_print, updateCanvas }
    }
  );
  wasm = instance.exports;
  createCanvasImage();
  wasm.clearCanvasBuffer();
  wasm.draw();
  updateCanvas();
}



// IO

function getKbKeyVal(code) {
    switch (code) {
        case 'Backspace': return 8; // ASCII: BS
        case 'Tab': return 9; // ASCII: TAB
        case 'Enter': return 13; // ASCII: CR
        case 'NumpadEnter': return 13; // ASCII: CR
        case 'ShiftLeft': return 16;
        case 'ShiftRight': return 16;
        case 'ControlLeft': return 17;
        case 'ControlRight': return 17;
        case 'AltLeft': return 18;
        case 'AltRight': return 18;
        case 'Pause': return 19;
        case 'CapsLock': return 20;
        case 'Escape': return 27; // ASCII: ESC
        case 'Space': return 32; // ASCII: SPACE
        case 'PageUp': return 33;
        case 'PageDown': return 34;
        case 'End': return 35;
        case 'Home': return 36;
        case 'ArrowLeft': return 37;
        case 'ArrowUp': return 38;
        case 'ArrowRight': return 39;
        case 'ArrowDown': return 40;
        case 'Insert': return 45;
        case 'Comma': return 44; // ASCII: ','
        case 'Minus': return 45; // ASCII: '-'
        case 'Period': return 46; // ASCII: '.'
        case 'Slash': return 47; // ASCII: '/'
        case 'Digit0': return 48; // ASCII: '0'
        case 'Digit1': return 49; // ASCII: '1'
        case 'Digit2': return 50; // ASCII: '2'
        case 'Digit3': return 51; // ASCII: '3'
        case 'Digit4': return 52; // ASCII: '4'
        case 'Digit5': return 53; // ASCII: '5'
        case 'Digit6': return 54; // ASCII: '6'
        case 'Digit7': return 55; // ASCII: '7'
        case 'Digit8': return 56; // ASCII: '8'
        case 'Digit9': return 57; // ASCII: '9'
        case 'Semicolon': return 59; // ASCII: ';'
        case 'Equal': return 61; // ASCII: '='
        case 'Quote': return 39; // ASCII: '\''
        case 'KeyA': return 65; // ASCII: 'A'
        case 'KeyB': return 66; // ASCII: 'B'
        case 'KeyC': return 67; // ASCII: 'C'
        case 'KeyD': return 68; // ASCII: 'D'
        case 'KeyE': return 69; // ASCII: 'E'
        case 'KeyF': return 70; // ASCII: 'F'
        case 'KeyG': return 71; // ASCII: 'G'
        case 'KeyH': return 72; // ASCII: 'H'
        case 'KeyI': return 73; // ASCII: 'I'
        case 'KeyJ': return 74; // ASCII: 'J'
        case 'KeyK': return 75; // ASCII: 'K'
        case 'KeyL': return 76; // ASCII: 'L'
        case 'KeyM': return 77; // ASCII: 'M'
        case 'KeyN': return 78; // ASCII: 'N'
        case 'KeyO': return 79; // ASCII: 'O'
        case 'KeyP': return 80; // ASCII: 'P'
        case 'KeyQ': return 81; // ASCII: 'Q'
        case 'KeyR': return 82; // ASCII: 'R'
        case 'KeyS': return 83; // ASCII: 'S'
        case 'KeyT': return 84; // ASCII: 'T'
        case 'KeyU': return 85; // ASCII: 'U'
        case 'KeyV': return 86; // ASCII: 'V'
        case 'KeyW': return 87; // ASCII: 'W'
        case 'KeyX': return 88; // ASCII: 'X'
        case 'KeyY': return 89; // ASCII: 'Y'
        case 'KeyZ': return 90; // ASCII: 'Z'
        case 'BracketLeft': return 91; // ASCII: '['
        case 'Backslash': return 92; // ASCII: '\'
        case 'BracketRight': return 93; // ASCII: ']'
        case 'Backquote': return 96; // ASCII: '`'
        case 'Numpad0': return 96; // ASCII: '`'
        case 'Numpad1': return 97; // ASCII: 'a'
        case 'Numpad2': return 98; // ASCII: 'b'
        case 'Numpad3': return 99; // ASCII: 'c'
        case 'Numpad4': return 100; // ASCII: 'd'
        case 'Numpad5': return 101; // ASCII: 'e'
        case 'Numpad6': return 102; // ASCII: 'f'
        case 'Numpad7': return 103; // ASCII: 'g'
        case 'Numpad8': return 104; // ASCII: 'h'
        case 'Numpad9': return 105; // ASCII: 'i'
        case 'NumpadMultiply': return 106; // ASCII: 'j'
        case 'NumpadAdd': return 107; // ASCII: 'k'
        case 'NumpadSubtract': return 109; // ASCII: 'm'
        case 'NumpadDecimal': return 110; // ASCII: 'n'
        case 'NumpadDivide': return 111; // ASCII: 'o'
        case 'F1': return 112; // ASCII: 'p'
        case 'F2': return 113; // ASCII: 'q'
        case 'F3': return 114; // ASCII: 'r'
        case 'F4': return 115; // ASCII: 's'
        case 'F5': return 116; // ASCII: 't'
        case 'F6': return 117; // ASCII: 'u'
        case 'F7': return 118; // ASCII: 'v'
        case 'F8': return 119; // ASCII: 'w'
        case 'F9': return 120; // ASCII: 'x'
        case 'F10': return 121; // ASCII: 'y'
        case 'F11': return 122; // ASCII: 'z'
        case 'F12': return 123; // ASCII: '{'
        case 'Delete': return 127; // ASCII: DEL
        case 'MetaLeft': return 91; // ASCII: '['
        case 'MetaRight': return 92; // ASCII: '\'
        case 'ContextMenu': return 93; // ASCII: ']'
        default: return 0;
    }
}

function setupKbInput() {

    window.addEventListener("keydown", (e) => {
        key = getKbKeyVal(e.code);
        wasm.keyboard_keyDown(key);
        const keyMap = [8, 9, 13, 16, 17, 18, 19, 20, 27, 32, 33, 34, 35, 36,
            37, 38, 39, 40, 45, 46, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57,
            65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90,
            91, 92, 93, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 109, 110, 111, 112, 113, 114, 115,
            116, 117, 118, 119, 120, 121, 122, 123, 144, 145, 186, 187, 188, 189, 190, 191, 192, 219, 220, 221, 222];
        if (key.includes(keyMap)) {
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
