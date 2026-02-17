const std = @import("std");
const ecs = @import("ecs");
const zm = @import("zmath");
const feature = @import("feature.zig");

pub const Entity2D = struct {
    pos: @Vector(2, f32),
};

pub const Scene = struct {
    entities: ecs.Registry,
    name: []const u8,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, name: []const u8) Scene {
        return .{
            .entities = ecs.Registry.init(allocator),
            .name = name,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Scene) void {
        self.entities.deinit();
    }
};

pub const Renderer = struct {
    scenes: std.ArrayList(Scene),
    allocator: std.mem.Allocator,
    width: u32 = 800,
    height: u32 = 600,
    depth_buffer: []f32,

    pub fn new(allocator: std.mem.Allocator) Renderer {
        return .{
            .scenes = .{},
            .allocator = allocator,
            .depth_buffer = &[_]f32{},
        };
    }

    pub fn deinit(self: *Renderer) void {
        for (self.scenes.items) |*scene| {
            scene.deinit();
        }
        self.scenes.deinit(self.allocator);
        if (self.depth_buffer.len > 0) self.allocator.free(self.depth_buffer);
    }

    pub fn drawToBuf(self: *Renderer, buf: []u8, width: u32) void {
        if (width == 0) return;
        const height = @divTrunc(@as(u32, @intCast(buf.len)), width * 4); // Assuming 4 bytes per pixel (RGBA)
        self.width = width;
        self.height = height;

        // Resize depth buffer if needed
        if (self.depth_buffer.len != width * height) {
            if (self.depth_buffer.len > 0) self.allocator.free(self.depth_buffer);
            self.depth_buffer = self.allocator.alloc(f32, width * height) catch return;
        }

        // Clear depth buffer
        @memset(self.depth_buffer, std.math.floatMax(f32));

        // Basic camera setup (can be improved later)
        const cam_pos = zm.f32x4(0.0, 1.0, -5.0, 1.0);
        const cam_target = zm.f32x4(0.0, 0.0, 0.0, 1.0);
        const cam_up = zm.f32x4(0.0, 1.0, 0.0, 0.0);

        const view_mat = zm.lookAtRh(cam_pos, cam_target, cam_up);
        const aspect = @as(f32, @floatFromInt(width)) / @as(f32, @floatFromInt(height));
        const proj_mat = zm.perspectiveFovRh(std.math.degreesToRadians(45.0), aspect, 0.1, 100.0);
        const view_proj = zm.mul(view_mat, proj_mat);

        const viewport_w = @as(f32, @floatFromInt(width));
        const viewport_h = @as(f32, @floatFromInt(height));

        for (self.scenes.items) |*scene| {
            var view = scene.entities.view(.{feature.Mesh3D}, .{});
            var iter = view.entityIterator();
            while (iter.next()) |entity| {
                const mesh = view.getConst(entity);
                if (!mesh.draw) continue;

                // Model matrix
                const trans = zm.translationV(mesh.pos);
                const rot = zm.matFromQuat(mesh.rotation);
                const scale = zm.scalingV(mesh.scale);
                const model = zm.mul(zm.mul(scale, rot), trans);

                const mvp = zm.mul(model, view_proj);

                // Iterate over faces (each U32x4 is a face: 3 indices + 1 pack color)
                var i: usize = 0;
                while (i < mesh.num_indices) : (i += 1) {
                    const face = mesh.indices[i];
                    const idx0 = face[0];
                    const idx1 = face[1];
                    const idx2 = face[2];
                    const packed_color = face[3];

                    if (idx0 >= mesh.num_vertices or idx1 >= mesh.num_vertices or idx2 >= mesh.num_vertices) continue;

                    // Retrieve vertices
                    const v0_local = mesh.vertices[idx0];
                    const v1_local = mesh.vertices[idx1];
                    const v2_local = mesh.vertices[idx2];

                    // Transform vertices
                    const v0_clip = zm.mul(v0_local, mvp);
                    const v1_clip = zm.mul(v1_local, mvp);
                    const v2_clip = zm.mul(v2_local, mvp);

                    // Perspective division
                    const w0 = v0_clip[3];
                    const w1 = v1_clip[3];
                    const w2 = v2_clip[3];

                    // Simple clipping against near plane
                    if (w0 < 0.001 or w1 < 0.001 or w2 < 0.001) continue;

                    const inv_w0 = 1.0 / w0;
                    const inv_w1 = 1.0 / w1;
                    const inv_w2 = 1.0 / w2;

                    const v0_ndc = v0_clip * zm.f32x4s(inv_w0);
                    const v1_ndc = v1_clip * zm.f32x4s(inv_w1);
                    const v2_ndc = v2_clip * zm.f32x4s(inv_w2);

                    // Viewport transform
                    // Map [-1, 1] to [0, width] and [0, height]
                    const x0 = (v0_ndc[0] + 1.0) * 0.5 * viewport_w;
                    const y0 = (1.0 - v0_ndc[1]) * 0.5 * viewport_h; // Flip Y
                    const z0 = v0_ndc[2]; // depth 0..1 typically

                    const x1 = (v1_ndc[0] + 1.0) * 0.5 * viewport_w;
                    const y1 = (1.0 - v1_ndc[1]) * 0.5 * viewport_h;
                    const z1 = v1_ndc[2];

                    const x2 = (v2_ndc[0] + 1.0) * 0.5 * viewport_w;
                    const y2 = (1.0 - v2_ndc[1]) * 0.5 * viewport_h;
                    const z2 = v2_ndc[2];

                    // Unpack color (assuming ABGR packed integer, or RGBA depending on pixel format)
                    // Using provided pixel packed struct logic: R G B A
                    // packed_color is u32. Let's assume standard 0xAABBGGRR for now.
                    // Or just extract bytes.
                    const r = @as(f32, @floatFromInt((packed_color >> 0) & 0xFF)) / 255.0;
                    const g = @as(f32, @floatFromInt((packed_color >> 8) & 0xFF)) / 255.0;
                    const b = @as(f32, @floatFromInt((packed_color >> 16) & 0xFF)) / 255.0;
                    const a = @as(f32, @floatFromInt((packed_color >> 24) & 0xFF)) / 255.0;

                    const color = zm.f32x4(r, g, b, a);

                    self.rasterizeTriangle(zm.f32x4(x0, y0, z0, 1.0), zm.f32x4(x1, y1, z1, 1.0), zm.f32x4(x2, y2, z2, 1.0), color, buf, width, height);
                }
            }
        }
    }

    fn rasterizeTriangle(self: *Renderer, v0: zm.F32x4, v1: zm.F32x4, v2: zm.F32x4, color: zm.F32x4, buf: []u8, width: u32, height: u32) void {
        // Bounding box
        const min_x_f = @max(0.0, @min(@min(v0[0], v1[0]), v2[0]));
        const min_y_f = @max(0.0, @min(@min(v0[1], v1[1]), v2[1]));
        const max_x_f = @min(@as(f32, @floatFromInt(width - 1)), @max(@max(v0[0], v1[0]), v2[0]));
        const max_y_f = @min(@as(f32, @floatFromInt(height - 1)), @max(@max(v0[1], v1[1]), v2[1]));

        const min_xi = @as(u32, @intFromFloat(min_x_f));
        const min_yi = @as(u32, @intFromFloat(min_y_f));
        const max_xi = @as(u32, @intFromFloat(max_x_f));
        const max_yi = @as(u32, @intFromFloat(max_y_f));

        if (min_xi > max_xi or min_yi > max_yi) return;

        // Edge functions
        // edge 0-1
        const edge01_x = v1[0] - v0[0];
        const edge01_y = v1[1] - v0[1];
        // edge 1-2
        const edge12_x = v2[0] - v1[0];
        const edge12_y = v2[1] - v1[1];
        // edge 2-0
        const edge20_x = v0[0] - v2[0];
        const edge20_y = v0[1] - v2[1];

        const area = edge01_x * -edge20_y - edge01_y * -edge20_x;
        // if area is practically zero (degenerate or back-facing if culling enabled), skip
        // For now, no back-face culling, but check for zero area
        if (@abs(area) < 0.0001) return;
        const inv_area = 1.0 / area;

        var y: u32 = min_yi;
        while (y <= max_yi) : (y += 1) {
            var x: u32 = min_xi;
            while (x <= max_xi) : (x += 1) {
                const px = @as(f32, @floatFromInt(x)) + 0.5;
                const py = @as(f32, @floatFromInt(y)) + 0.5;

                // Barycentric coordinates
                // w0 is related to vertex 0 (opposite to edge 1-2)
                // Calculated as signed area of triangle (v1, v2, p) / total area
                // Area (v1, v2, p) = (v2.x - v1.x)*(p.y - v1.y) - (v2.y - v1.y)*(p.x - v1.x)
                // This corresponds to edge 1-2
                const w0 = (edge12_x * (py - v1[1]) - edge12_y * (px - v1[0])) * inv_area;

                // w1 is related to vertex 1 (opposite to edge 2-0)
                const w1 = (edge20_x * (py - v2[1]) - edge20_y * (px - v2[0])) * inv_area;

                // w2 is related to vertex 2 (opposite to edge 0-1)
                const w2 = 1.0 - w0 - w1;

                if (w0 >= 0 and w1 >= 0 and w2 >= 0) {
                    // Interpolate Z (depth)
                    // Note: Technically should interpolate 1/z in screen space for perspective correct texture mapping,
                    // but for depth test and flat color, linear z is acceptable for simple renderer or needs 1/w interpolation.
                    // Using simple linear interpolation here.
                    const z = w0 * v0[2] + w1 * v1[2] + w2 * v2[2];

                    const idx = y * width + x;
                    if (z < self.depth_buffer[idx]) {
                        self.depth_buffer[idx] = z;

                        // Write pixel
                        const offset = idx * 4;
                        // Assuming color is 0.0-1.0 float, map to 0-255
                        // ABGR packed u32 or R, G, B, A in byte stream
                        buf[offset + 0] = @as(u8, @intFromFloat(@max(0.0, @min(1.0, color[0])) * 255.0)); // R
                        buf[offset + 1] = @as(u8, @intFromFloat(@max(0.0, @min(1.0, color[1])) * 255.0)); // G
                        buf[offset + 2] = @as(u8, @intFromFloat(@max(0.0, @min(1.0, color[2])) * 255.0)); // B
                        buf[offset + 3] = 255; // A
                    }
                }
            }
        }
    }

    //returns the created scene, output can be discarded as renderer stores it internally
    pub fn createScene(self: *Renderer, name: []const u8) !*Scene {
        const scene = Scene.init(self.allocator, name);
        try self.scenes.append(self.allocator, scene);
        return &self.scenes.items[self.scenes.items.len - 1];
    }
};
