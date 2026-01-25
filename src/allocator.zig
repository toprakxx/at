const std = @import("std");

pub const TA_Allocator = struct {
    arena: ?std.heap.ArenaAllocator = null,
    aa: ?std.mem.Allocator = null,

    pub fn new() TA_Allocator {
        return .{};
    }
    pub fn init(self: *TA_Allocator) void {
        if (self.arena == null) {
            self.arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
            self.aa = self.arena.?.allocator();
        }
    }
    pub fn deinit(self: *TA_Allocator) void {
        if (self.arena) |a| {
            a.deinit();
            self.arena = null;
            self.aa = null;
        }
    }
    pub inline fn allocator(self: *TA_Allocator) std.mem.Allocator {
        var buf: [512]u8 = undefined;
        const slice = std.fmt.bufPrint(&buf, "dumb fuck \n go check {s}:{d}", .{
            @src().file,
            @src().line,
        }) catch unreachable; // can never fail anyways cuz who the fuck has filename of ~500 chars
        return self.aa orelse @panic(slice);
    }
    pub fn reset(self: *TA_Allocator, mode: std.heap.ArenaAllocator.ResetMode) void {
        if (self.arena) |*a| {
            _ = a.reset(mode);
        }
    }
};
