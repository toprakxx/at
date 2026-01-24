const Pixel = @import("pixel.zig").Pixel;

pub const width = 800;
pub const height = 600;
var bgColor: u24 = 0x44_44_ff;
pub var canvas_buffer: [width * height]Pixel = undefined;
pub extern fn updateCanvas() void;

pub export fn clearCanvasBuffer() void {
    // const pixel: u32 = @bitCast(Pixel.fromRGB(bgColor));
    const pixel = Pixel.fromRGB(bgColor);
    @memset(&canvas_buffer, pixel);
}

export fn getCanvasWidth() u32 {
    return width;
}
export fn getCanvasHeight() u32 {
    return height;
}
export fn getCanvasBuffer() [*]u32 {
    return @ptrCast(&canvas_buffer);
}
