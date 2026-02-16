const Pixel = @import("pixel.zig").Pixel;
const std = @import("std");
pub extern fn updateCanvas() void;

pub const Canvas = struct {
    width: i32 = 800, // classic c int for compat
    height: i32 = 600,
    allocator: std.mem.Allocator,
    buffer: []Pixel = undefined,
    bgColor: u24 = 0x44_44_ff,
    pub fn new(width: i32, height: i32, alloc: std.mem.Allocator) Canvas {
        return .{
            .width = width,
            .height = height,
            .allocator = alloc,
        };
    }
    pub fn init(self: *Canvas) void {
        self.buffer = self.allocator.alloc(Pixel, self.width * self.height) orelse unreachable; // FIXME handle bad alloc
    }
    pub fn deninit(self: *Canvas) void {
        self.allocator.free(self.buffer);
    }
    pub fn getBuffer(self: *Canvas) [*]u32 {
        return @ptrCast(&self.buffer);
    }
    pub fn clearBuffer(self: *Canvas) void {
        const pixel = Pixel.fromRGB(self.bgColor);
        @memset(@as([self.width * self.height]i32, @ptrCast(self.buffer.ptr)), pixel);
    }
    // TODO
    pub inline fn drawPixel(self: *Canvas, x: i32, y: i32, pixel: *Pixel) void {
        self.buffer[y * self.width + x] = pixel.*;
    }
};
