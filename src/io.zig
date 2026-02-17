const std = @import("std");
const TA_ERR = @import("error.zig").TA_ERR;
extern fn js_print(str_ptr: [*]const u8, str_len: u32) void;

pub fn print(comptime fmt: []const u8, args: anytype) void {
    var buf: [256]u8 = undefined;
    const str = std.fmt.bufPrint(&buf, fmt, args) catch {
        const allocated_str = std.fmt.allocPrint(std.heap.wasm_allocator, fmt, args) catch return;
        defer std.heap.wasm_allocator.free(allocated_str);
        js_print(allocated_str.ptr, @intCast(allocated_str.len));
        return; // Early return to avoid printing the stack buffer
    };
    js_print(str.ptr, @intCast(str.len));
}

pub const KeyCode = enum(u8) {
    none = 0,
    backspace = 8,
    tab = 9,
    enter = 13,
    shift = 16,
    ctrl = 17,
    alt = 18,
    pause = 19,
    caps_lock = 20,
    escape = 27,
    space = 32,

    // ASCII Digits
    key_0 = 48,
    key_1 = 49,
    key_2 = 50,
    key_3 = 51,
    key_4 = 52,
    key_5 = 53,
    key_6 = 54,
    key_7 = 55,
    key_8 = 56,
    key_9 = 57,

    // ASCII Symbols
    quote = 39,
    comma = 44,
    minus = 45,
    period = 46,
    slash = 47,
    semicolon = 59,
    equal = 61,
    bracket_left = 91,
    backslash = 92,
    bracket_right = 93,
    backtick = 96,

    // ASCII Letters
    a = 65,
    b = 66,
    c = 67,
    d = 68,
    e = 69,
    f = 70,
    g = 71,
    h = 72,
    i = 73,
    j = 74,
    k = 75,
    l = 76,
    m = 77,
    n = 78,
    o = 79,
    p = 80,
    q = 81,
    r = 82,
    s = 83,
    t = 84,
    u = 85,
    v = 86,
    w = 87,
    x = 88,
    y = 89,
    z = 90,

    // Function Keys
    f1 = 112,
    f2 = 113,
    f3 = 114,
    f4 = 115,
    f5 = 116,
    f6 = 117,
    f7 = 118,
    f8 = 119,
    f9 = 120,
    f10 = 121,
    f11 = 122,
    f12 = 123,

    // Non-ASCII Special Keys
    delete = 127, // ASCII DEL
    page_up = 138,
    page_down = 139,
    end = 140,
    home = 141,
    arrow_left = 142,
    arrow_up = 143,
    arrow_right = 144,
    arrow_down = 145,
    insert = 146,

    // Misc
    print_screen = 154,
    scroll_lock = 155,
    num_lock = 156,
    super = 157, // Windows/Command key

    _,
};

pub const MouseButton = enum(u8) {
    none = 0,
    left = 1,
    middle = 2,
    right = 3,
    back = 4,
    forward = 5,
};

pub const Keyboard = struct {
    keys_down: []bool,
    keys_pressed: []bool,
    keys_released: []bool,

    pub fn new() Keyboard {
        const allocator = std.heap.page_allocator;
        // keyboard lifetime matches the programs lifetime so FUCK IT NO FREEING FUCK JS FUCK WEB APPS THIS WONT BE A PROBLEM
        // ik there is a ram crysis and all but everyone has enough memory for 3x256 bytes like cmon
        // TODO catch return instead
        const keys_down = allocator.alloc(bool, 256) catch unreachable; //TA_ERR.BAD_ALLOC;
        const keys_pressed = allocator.alloc(bool, 256) catch unreachable; //TA_ERR.BAD_ALLOC;
        const keys_released = allocator.alloc(bool, 256) catch unreachable; //TA_ERR.BAD_ALLOC;

        @memset(keys_down, false);
        @memset(keys_pressed, false);
        @memset(keys_released, false);

        return .{
            .keys_down = keys_down,
            .keys_pressed = keys_pressed,
            .keys_released = keys_released,
        };
    }

    pub fn keyDown(self: *Keyboard, key: KeyCode) void {
        const key_code = @intFromEnum(key);
        if (!self.keys_down[key_code]) {
            self.keys_pressed[key_code] = true;
        }
        self.keys_down[key_code] = true;
    }
    pub fn keyUp(self: *Keyboard, key: KeyCode) void {
        const key_code = @intFromEnum(key);
        self.keys_down[key_code] = false;
        self.keys_released[key_code] = true;
    }

    pub fn iskeyDown(self: *const Keyboard, key: KeyCode) bool {
        return self.keys_down[@intFromEnum(key)];
    }
    pub fn isKeyPressed(self: *const Keyboard, key: KeyCode) bool {
        return self.keys_pressed[@intFromEnum(key)];
    }

    pub fn isKeyReleased(self: *const Keyboard, key: KeyCode) bool {
        return self.keys_released[@intFromEnum(key)];
    }

    pub fn endFrame(self: *Keyboard) void {
        @memset(self.keys_pressed, false);
        @memset(self.keys_released, false);
    }
};

const Mouse = struct {
    // logitechin 50 tuslu faresi ve mobile icin touch uygun olmali hallederiz heralde
};
