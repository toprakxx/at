// DO NOT EXPORT ANY FUNCTIONS OUTSIDE OF THIS FILE

// keep code c style for js compatibility

const std = @import("std");
pub const Canvas = @import("canvas.zig").Canvas;
pub const pixel = @import("pixel.zig");
pub const io = @import("io.zig");
const Keyboard = io.Keyboard;
const KeyCode = io.KeyCode;
// comptime {
//     _ = canvas;
//     _ = pixel;
//     _ = io;
// }

var interface_kb: Keyboard = undefined;

var initialized: bool = false;

export fn interface_init() void {
    if (!initialized) {
        // debug.print("Initializing interface");
        interface_kb = Keyboard.new();
    }
}

export fn keyboard_keyDown(key: u8) void {
    interface_kb.keyDown(@enumFromInt(key));
}
export fn keyboard_keyUp(key: u8) void {
    interface_kb.keyUp(@enumFromInt(key));
}
export fn canvas_getWidth() u32 {
    return Canvas.width;
}
export fn canvas_getHeight() u32 {
    return Canvas.height;
}
export fn canvas_getBuffer() [*]u32 {
    return canvas.getBuffer();
}
export fn canvas_clearBuffer() void {
    canvas.clearBuffer();
}
// program entry
var b: u24 = 128;
var canvas: Canvas = Canvas.new();

pub export fn update() void {
    var keeb = Keyboard.new();
    // Test with 'W' (87) and 'A' (65)
    if (keeb.iskeyDown(.w)) {
        b = b + 1;
    }
    if (keeb.iskeyDown(.a)) {
        b = b - 1;
    }

    for (0..Canvas.height) |i| { // y
        for (0..Canvas.width) |j| { // x
            const r: u8 = @intCast((j * 255) / Canvas.width);
            const g: u8 = @intCast((i * 255) / Canvas.height);
            const rgb = (@as(u24, r) << 16) | (@as(u24, g) << 8) | b;
            canvas.buffer[j + (i * Canvas.width)] = pixel.Pixel.fromRGB(rgb);
        }
    }
}
