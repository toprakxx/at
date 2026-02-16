const std = @import("std");

pub const TA_Allocator = struct {
    arena: []std.heap.ArenaAllocator = undefined,
    initialized: bool = false,

    pub fn new() TA_Allocator {
        return .{};
    }

    pub fn allocator(_: *TA_Allocator) std.mem.Allocator {
        return std.heap.wasm_allocator;
    }

    pub fn init(self: *TA_Allocator, aa_num: u32) void {
        if (!self.initialized) {
            self.arena = std.heap.wasm_allocator.alloc(std.heap.ArenaAllocator, aa_num) catch unreachable;
            for (self.arena) |*a| {
                a.* = std.heap.ArenaAllocator.init(std.heap.wasm_allocator);
            }
            self.initialized = true;
        }
    }

    pub fn deinit(self: *TA_Allocator) void {
        for (self.arena) |*a| {
            a.deinit();
        }
    }
};
