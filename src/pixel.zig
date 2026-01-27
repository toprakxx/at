pub const Pixel = packed struct {
    r: u8 = 0xff,
    g: u8 = 0xff,
    b: u8 = 0xff,
    a: u8 = 0xff,

    pub fn fromRGB(rgb: u24) Pixel {
        return .{
            .r = @intCast((rgb >> 16) & 0xFF),
            .g = @intCast((rgb >> 8) & 0xFF),
            .b = @intCast(rgb & 0xFF),
            .a = 0xff,
        };
    }
    pub fn fromRGBA(rgba: u32) Pixel {
        return @bitCast(@byteSwap(rgba));
    }
};
pub inline fn pixel(p: Pixel) Pixel {
    return p;
}
