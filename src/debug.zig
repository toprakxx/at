extern fn js_print(str_ptr: [*]const u8, str_len: u32) void;

pub fn debugPrint(str: []const u8) void {
    js_print(str.ptr, str.len);
}
