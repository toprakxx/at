const std = @import("std");
const feature = @import("feature.zig");
const io = @import("io.zig");
const wa = std.heap.wasm_allocator;
const zm = @import("zmath");

pub const ModelLoader = struct {
    pub fn loadObj(data_ptr: [*]const u8, len: usize) ?feature.Mesh3D {
        const data = data_ptr[0..len];
        var name: ?[]u8 = null;
        var lines = std.mem.splitScalar(u8, data, '\n');
        var vertices = std.ArrayListUnmanaged(zm.F32x4){};
        var tcoords = std.ArrayListUnmanaged(@Vector(2, f32)){};
        var faces = std.ArrayListUnmanaged(@Vector(3, u32)){};

        while (lines.next()) |line| {
            const trimmed = std.mem.trim(u8, line, " \r\t");
            if (trimmed.len == 0) continue;
            // vertices
            if (std.mem.startsWith(u8, trimmed, "v ")) {
                var vertex = @Vector(4, f32){ 0, 0, 0, 1.0 };
                var iter = std.mem.splitScalar(u8, trimmed[2..], ' ');
                var i: usize = 0;
                while (iter.next()) |str| {
                    if (str.len == 0) continue;
                    if (i >= 4) break;
                    vertex[i] = std.fmt.parseFloat(f32, str) catch {
                        io.print("Failed to parse float for vertex\n", .{});
                        return null;
                    };
                    i += 1;
                }
                if (i < 3) {
                    io.print("Unsupported vertex dimension: {}\n", .{i});
                    return null;
                }
                vertices.append(wa, vertex) catch return null;
            }
            // texture coordinates
            else if (std.mem.startsWith(u8, trimmed, "vt")) {
                var texture_coord = @Vector(2, f32){ 0, 0 };
                var iter = std.mem.splitScalar(u8, trimmed[2..], ' ');
                var i: usize = 0;
                while (iter.next()) |str| {
                    if (str.len == 0) continue;
                    if (i >= 2) break;
                    texture_coord[i] = std.fmt.parseFloat(f32, str) catch {
                        io.print("Failed to parse float for texture coord\n", .{});
                        return null;
                    };
                    i += 1;
                }
                if (i < 2) {
                    io.print("Unknown texture coord dimension\n", .{});
                    return null;
                }
                tcoords.append(wa, texture_coord) catch return null;
            }
            // faces
            else if (std.mem.startsWith(u8, trimmed, "f ")) {
                var verts: [4]u32 = undefined;
                var iter = std.mem.splitScalar(u8, trimmed[2..], ' ');
                var i: usize = 0;
                while (iter.next()) |str| {
                    if (str.len == 0) continue;
                    if (i >= 4) break;
                    // Handle "v/vt/vn" format, we only care about v (the first one)
                    var slash_iter = std.mem.splitScalar(u8, str, '/');
                    if (slash_iter.next()) |v_idx_str| {
                        const idx = std.fmt.parseInt(u32, v_idx_str, 10) catch {
                            io.print("Failed to parse int for face index\n", .{});
                            return null;
                        };
                        // OBJ indices are 1-based
                        verts[i] = idx - 1;
                        i += 1;
                    }
                }
                if (i == 3) {
                    faces.append(wa, .{ verts[0], verts[1], verts[2] }) catch return null;
                } else if (i == 4) {
                    // Triangulate quad
                    faces.append(wa, .{ verts[0], verts[1], verts[2] }) catch return null;
                    faces.append(wa, .{ verts[0], verts[2], verts[3] }) catch return null;
                } else {
                    io.print("Can not load mesh with non triangle/quad faces\n", .{});
                    return null;
                }
            } else if (std.mem.startsWith(u8, trimmed, "o ")) {
                name = wa.dupe(u8, trimmed[2..]) catch return null;
            }
        }

        const v_slice = vertices.toOwnedSlice(wa) catch return null;
        const f_slice = faces.toOwnedSlice(wa) catch return null;
        const defaultName = "Unnamed";
        const mesh = feature.Mesh3D{
            .pos = zm.f32x4(0.0, 0.0, 0.0, 1.0),
            .rotation = zm.qidentity(),
            .scale = zm.f32x4s(1.0),
            .name_len = if (name) |n| @intCast(n.len) else defaultName.len,
            .num_vertices = @intCast(v_slice.len),
            .num_indices = @intCast(f_slice.len),
            .name = if (name) |n| n.ptr else (wa.dupe(u8, defaultName) catch return null).ptr,
            .vertices = v_slice.ptr,
            .indices = f_slice.ptr,
            .mat = null,
            // .draw = true,
        };
        return mesh;
    }
};
