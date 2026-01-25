const std = @import("std");
var arena: ?std.heap.ArenaAllocator = null;
var aa: ?std.mem.Allocator = null;

pub const TA_Allocator = struct {
    pub fn init() void {
        if (arena == null) {
            arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
            aa = arena.?.allocator();
        }
    }
    pub fn deinit() void {
        if (arena) |a| {
            a.deinit();
            arena = null;
            aa = null;
        }
    }
    pub inline fn allocator() std.mem.Allocator {
        const buf: [512]u8 = undefined;
        const slice = std.fmt.bufPrint(buf, "dumb fuck \n go check {s}:{d}", .{
            @src().file,
            @src().line,
        }) catch unreachable; // can never fail anyways cuz who the fuck has filename of ~500 chars
        return if (aa) aa.? else @panic(slice);
    }
    pub fn reset(mode: std.heap.ArenaAllocator.ResetMode) void {
        aa.?.reset(mode);
    }
};
