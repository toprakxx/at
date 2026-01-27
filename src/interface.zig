// DO NOT EXPORT ANY FUNCTIONS OUTSIDE OF THIS FILE

// keep code c style for js compatibility

const std = @import("std");
pub const Canvas = @import("canvas.zig").Canvas;
pub const pixel = @import("pixel.zig");
pub const io = @import("io.zig");
pub const TA_Allocator = @import("allocator.zig").TA_Allocator;
const Keyboard = io.Keyboard;
const KeyCode = io.KeyCode;
var aAllocator: TA_Allocator = undefined;
var interface_kb: Keyboard = undefined;
const entity = @import("entity.zig");
const ecs = @import("ecs.zig");

var initialized: bool = false;

export fn interface_init() void {
    if (!initialized) {
        aAllocator = TA_Allocator.new();
        aAllocator.init();
        interface_kb = Keyboard.new();
        initialized = true;
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
var b: u8 = 128;
var canvas: Canvas = Canvas.new();

pub export fn update() void {
    if (interface_kb.iskeyDown(.w)) {
        b +%= 1;
        io.print(aAllocator.allocator(), "New val for b: {d}", .{b});
        aAllocator.reset(.retain_capacity);
    }
    if (interface_kb.iskeyDown(.s)) {
        b -%= 1;
        io.print(aAllocator.allocator(), "New val for b: {d}", .{b});
        aAllocator.reset(.retain_capacity);
    }

    for (0..Canvas.height) |i| { // y
        for (0..Canvas.width) |j| { // x
            const r: u8 = @intCast((j * 255) / Canvas.width);
            const g: u8 = @intCast((i * 255) / Canvas.height);
            const rgb = (@as(u24, r) << 16) | (@as(u24, g) << 8) | (@as(u24, b));
            canvas.buffer[j + (i * Canvas.width)] = pixel.Pixel.fromRGB(rgb);
        }
    }
    interface_kb.endFrame();
}
