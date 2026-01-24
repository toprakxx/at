pub const Pixel = packed struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,

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
