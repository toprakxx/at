const std = @import("std");

//////////// IMPORTANT ////////////
// THIS SETS AN UNFINISHED AND SUBJECT TO CHANGE STANDARD FOR ENTITIES
// ALL ENTITY STRUCTS MUST IMPLEMENT THE FOLLOWING MEMBER FUNCTIONS
// pub fn Draw() void;
// pub fn getName() []u8;
// pub fn getLayer() u16;
// pub fn getProperty(name:[]const u8) []u8;
// tbc

pub fn isEntityType(T: type) bool {
    if (@typeInfo(T) != .@"struct") {
        return false;
    }

    // Basic existence and type checks
    inline for (.{ "Draw", "getName", "getLayer", "getProperty" }) |decl_name| {
        if (!@hasDecl(T, decl_name)) return false;
        if (@typeInfo(@TypeOf(@field(T, decl_name))) != .@"fn") return false;
    }

    // Signature checks
    const draw_info = @typeInfo(@TypeOf(@field(T, "Draw"))).@"fn";
    if (draw_info.return_type != void) return false;
    if (draw_info.params.len > 1) return false;
    if (draw_info.params.len == 1) {
        const PT = draw_info.params[0].type orelse return false;
        if (PT != T and PT != *T and PT != *const T) return false;
    }

    const getName_info = @typeInfo(@TypeOf(@field(T, "getName"))).@"fn";
    if (getName_info.return_type != []u8) return false;
    if (getName_info.params.len > 1) return false;
    if (getName_info.params.len == 1) {
        const PT = getName_info.params[0].type orelse return false;
        if (PT != T and PT != *T and PT != *const T) return false;
    }

    const getLayer_info = @typeInfo(@TypeOf(@field(T, "getLayer"))).@"fn";
    if (getLayer_info.return_type != u16) return false;
    if (getLayer_info.params.len > 1) return false;
    if (getLayer_info.params.len == 1) {
        const PT = getLayer_info.params[0].type orelse return false;
        if (PT != T and PT != *T and PT != *const T) return false;
    }

    const getProperty_info = @typeInfo(@TypeOf(@field(T, "getProperty"))).@"fn";
    if (getProperty_info.return_type != []u8) return false;
    if (getProperty_info.params.len == 1) {
        const param_type = getProperty_info.params[0].type orelse return false;
        if (param_type != []const u8) return false;
    } else if (getProperty_info.params.len == 2) {
        const self_type = getProperty_info.params[0].type orelse return false;
        if (self_type != T and self_type != *T and self_type != *const T) return false;
        const param_type = getProperty_info.params[1].type orelse return false;
        if (param_type != []const u8) return false;
    } else {
        return false;
    }

    return true;
}

test "isEntityType validation" {
    const ValidEntity = struct {
        pub fn Draw(_: *@This()) void {}
        pub fn getName(_: *@This()) []u8 {
            return undefined;
        }
        pub fn getLayer(_: *@This()) u16 {
            return 0;
        }
        pub fn getProperty(_: *@This(), _: []const u8) []u8 {
            return undefined;
        }
    };

    const InvalidEntity = struct {
        pub fn Draw() void {}
        // Missing others
    };

    const WrongSignatureEntity = struct {
        pub fn Draw() u32 {
            return 0;
        }
        pub fn getName() []u8 {
            return undefined;
        }
        pub fn getLayer() u16 {
            return 0;
        }
        pub fn getProperty(_: []const u8) []u8 {
            return undefined;
        }
    };

    try std.testing.expect(isEntityType(ValidEntity));
    try std.testing.expect(!isEntityType(InvalidEntity));
    try std.testing.expect(!isEntityType(WrongSignatureEntity));
}
