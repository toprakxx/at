// DO NOT EXPORT ANY FUNCTIONS OUTSIDE OF THIS FILE

// keep code c style for js compatibility

const std = @import("std");
pub const Canvas = @import("canvas.zig").Canvas;
pub const pixel = @import("pixel.zig");
pub const io = @import("io.zig");
pub const TA_Allocator = @import("allocator.zig").TA_Allocator;
const Keyboard = io.Keyboard;
const KeyCode = io.KeyCode;
var allocator: TA_Allocator = undefined;
var interface_kb: Keyboard = undefined;
var canvas: Canvas = undefined;

var initialized: bool = false;

export fn interface_init() void {
    if (!initialized) {
        allocator = TA_Allocator.new();
        allocator.init(3); // create allocator with 3 arena and 1 gpa
        interface_kb = Keyboard.new();
        initialized = true;
        canvas = Canvas.new(
            800,
            600,
        );
        canvas.init();
    }
}
// uhh no need to call since js sucks ass and you cant really call it also browser cleans up aftfer the program so
// export fn interface_deinit() void {
//     if (initialized) {
//         aAllocator.deinit();
//         initialized = false;
//     }
// }
export fn keyboard_keyDown(key: u8) void {
    interface_kb.keyDown(@enumFromInt(key));
}
export fn keyboard_keyUp(key: u8) void {
    interface_kb.keyUp(@enumFromInt(key));
}
export fn canvas_getWidth() i32 {
    return canvas.width;
}
export fn canvas_getHeight() i32 {
    return canvas.height;
}
export fn canvas_getBuffer() [*]u32 {
    return canvas.getBuffer();
}
export fn canvas_clearBuffer() void {
    canvas.clearBuffer();
}
// program entry
var b: u8 = 128;

pub export fn update() void {
    if (interface_kb.iskeyDown(.w)) {
        b +%= 1;
        io.print(allocator.gpa.allocator(), "New val for b: {d}", .{b});
    }
    if (interface_kb.iskeyDown(.s)) {
        b -%= 1;
        io.print(allocator.gpa.allocator(), "New val for b: {d}", .{b});
    }

    for (0..canvas.height) |i| { // y
        for (0..canvas.width) |j| { // x
            const r: u8 = @intCast((j * 255) / canvas.width);
            const g: u8 = @intCast((i * 255) / canvas.height);
            const rgb = (@as(u24, r) << 16) | (@as(u24, g) << 8) | (@as(u24, b));
            canvas.buffer[j + (i * canvas.width)] = pixel.Pixel.fromRGB(rgb);
        }
    }
    interface_kb.endFrame();
}
