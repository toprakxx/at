const Pixel = @import("pixel.zig").Pixel;
const std = @import("std");
pub extern fn updateCanvas() void;

pub const Canvas = struct {
    width: usize = 800, // classic c int for compat
    height: usize = 600,
    allocator: std.mem.Allocator,
    buffer: []Pixel = undefined,
    bgColor: u24 = 0x44_44_ff,
    pub fn new(width: usize, height: usize, alloc: std.mem.Allocator) Canvas {
        return .{
            .width = width,
            .height = height,
            .allocator = alloc,
        };
    }
    pub fn init(self: *Canvas) void {
        self.buffer = self.allocator.alloc(Pixel, @bitCast(self.width * self.height)) catch unreachable; // FIXME handle bad alloc
    }
    pub fn deninit(self: *Canvas) void {
        self.allocator.free(self.buffer);
    }
    pub fn getBuffer(self: *Canvas) [*]u32 {
        return @ptrCast(self.buffer.ptr);
    }
    pub fn clearBuffer(self: *Canvas) void {
        const pixel = Pixel.fromRGB(self.bgColor);
        @memset(self.buffer, pixel);
    }
    // TODO
    pub inline fn drawPixel(self: *Canvas, x: usize, y: usize, pixel: *Pixel) void {
        self.buffer[y * self.width + x] = pixel.*;
    }
};
