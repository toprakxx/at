const std = @import("std");
pub const utils = @import("io.zig");
pub const canvas = @import("canvas.zig");
pub const pixel = @import("pixel.zig");
pub const db = @import("debug.zig");

comptime {
    _ = canvas;
    _ = utils;
    _ = pixel;
    _ = db;
}

var color: u24 = 0;

pub export fn draw() void {
    for (0..600) |i| { // y
        for (0..800) |j| { // x
            const r: u8 = @intCast((j * 255) / 800);
            const g: u8 = @intCast((i * 255) / 600);
            const b: u8 = 128;
            const rgb = (@as(u24, r) << 16) | (@as(u24, g) << 8) | b;
            canvas.canvas_buffer[j + (i * canvas.width)] = pixel.Pixel.fromRGB(rgb);
        }
    }
}
