const Pixel = @import("pixel.zig").Pixel;

pub extern fn updateCanvas() void;

pub const Canvas = struct {
    pub const width = 800;
    pub const height = 600;
    buffer: [width * height]Pixel = undefined,
    bgColor: u24 = 0x44_44_ff,
    pub fn new() Canvas {
        return .{};
    }
    pub fn getBuffer(self: *Canvas) [*]u32 {
        return @ptrCast(&self.buffer);
    }

    pub fn clearBuffer(self: *Canvas) void {
        const pixel = Pixel.fromRGB(self.bgColor);
        @memset(&self.buffer, pixel);
    }

    // pub fn getHeight(self: *const Canvas) u32 {
    //     return self.height;
    // }
    // pub fn getWidth(self: *const Canvas) u32 {
    //     return self.width;
    // }
};
