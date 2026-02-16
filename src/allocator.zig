const std = @import("std");

pub const TA_Allocator = struct {
    arena: []std.heap.ArenaAllocator = undefined,
    gpa: std.heap.DebugAllocator = undefined, // FIXME
    initialized: bool = false,
    pub fn new() TA_Allocator {
        return .{};
    }
    pub fn init(self: *TA_Allocator, aa_num: u32) void {
        if (!self.initialized) {
            self.gpa = std.heap.GeneralPurposeAllocator(.{ .thread_safe = false }).init;
            self.arena = self.gpa.allocator().alloc(std.heap.ArenaAllocator, aa_num) catch unreachable;
            for (self.arena) |*a| {
                a.* = std.heap.ArenaAllocator.init(std.heap.page_allocator);
            }
        }
    }
    pub fn deinit(self: *TA_Allocator) void {
        for (self.arena) |*a| {
            a.deinit();
        }
    }
};
