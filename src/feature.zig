const zm = @import("zmath");
const std = @import("std");
const wa = std.heap.wasm_allocator;
const loadObj = @import("model_loader.zig").ModelLoader.loadObj;
// definitions for common entity features
pub const Material = struct {
    color: zm.F32x4,
};
pub const Mesh3D = struct {
    name: [*]u8,
    vertices: [*]zm.F32x4,
    indices: [*]@Vector(3, u32),
    pos: zm.F32x4,
    rotation: zm.Quat = zm.qidentity(),
    scale: zm.F32x4 = zm.f32x4s(1.0),
    num_vertices: u32,
    num_indices: u32,
    name_len: u8,
    mat: ?Material,
    // draw: bool = false,
    pub fn default() Mesh3D {
        const cube_obj =
            \\o Cube
            \\v -1.0 -1.0 1.0
            \\v 1.0 -1.0 1.0
            \\v 1.0 1.0 1.0
            \\v -1.0 1.0 1.0
            \\v -1.0 -1.0 -1.0
            \\v 1.0 -1.0 -1.0
            \\v 1.0 1.0 -1.0
            \\v -1.0 1.0 -1.0
            \\f 1 2 3 4
            \\f 2 6 7 3
            \\f 8 7 6 5
            \\f 5 1 4 8
            \\f 4 3 7 8
            \\f 5 6 2 1
        ;
        if (loadObj(cube_obj.ptr, cube_obj.len)) |mesh| {
            return mesh;
        }
        unreachable;
    }
};

pub const TileLayer = struct {
    tiles: [*]u16, // tile IDs; 0 = empty
    collision: bool = false,
    visible: bool = true,
    tileset_idx: u8 = 0, // index into TileMap.tilesets
    name: [32]u8 = [_]u8{0} ** 32,
    name_len: u8 = 0,
};

pub const Tileset = struct {
    data: ?[*]const u8 = null, // RGBA bytes (kept alive by JS/caller)
    pixel_width: u32 = 0,
    pixel_height: u32 = 0,
    cols: u32 = 0,
};

pub const MAX_TILESETS: u8 = 16;

pub const TileMap = struct {
    tile_width: u32,
    tile_height: u32,
    map_width: u32,
    map_height: u32,
    offset_x: f32 = 0,
    offset_y: f32 = 0,
    layers: [*]TileLayer,
    num_layers: u32,
    tilesets: [MAX_TILESETS]Tileset = [_]Tileset{.{}} ** MAX_TILESETS,
    num_tilesets: u8 = 0,

    pub fn getTile(self: *const TileMap, layer: u32, tx: u32, ty: u32) u16 {
        if (layer >= self.num_layers or tx >= self.map_width or ty >= self.map_height) return 0;
        return self.layers[layer].tiles[ty * self.map_width + tx];
    }

    pub fn setTile(self: *TileMap, layer: u32, tx: u32, ty: u32, id: u16) void {
        if (layer >= self.num_layers or tx >= self.map_width or ty >= self.map_height) return;
        self.layers[layer].tiles[ty * self.map_width + tx] = id;
    }

    // Returns true if AABB (world-space pixels) overlaps any solid tile in any collision layer.
    pub fn collidesAABB(self: *const TileMap, x: f32, y: f32, w: f32, h: f32) bool {
        if (self.tile_width == 0 or self.tile_height == 0) return false;
        const tw_f = @as(f32, @floatFromInt(self.tile_width));
        const th_f = @as(f32, @floatFromInt(self.tile_height));
        const rx = x - self.offset_x;
        const ry = y - self.offset_y;
        const tx0: i32 = @intFromFloat(@floor(rx / tw_f));
        const ty0: i32 = @intFromFloat(@floor(ry / th_f));
        const tx1: i32 = @intFromFloat(@ceil((rx + w) / tw_f));
        const ty1: i32 = @intFromFloat(@ceil((ry + h) / th_f));
        const mw = @as(i32, @intCast(self.map_width));
        const mh = @as(i32, @intCast(self.map_height));
        var tyi: i32 = @max(0, ty0);
        while (tyi < @min(mh, ty1)) : (tyi += 1) {
            var txi: i32 = @max(0, tx0);
            while (txi < @min(mw, tx1)) : (txi += 1) {
                const idx = @as(usize, @intCast(tyi)) * self.map_width + @as(usize, @intCast(txi));
                for (0..self.num_layers) |li| {
                    if (!self.layers[li].collision) continue;
                    if (self.layers[li].tiles[idx] != 0) return true;
                }
            }
        }
        return false;
    }
};

pub const Rect2D = struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,
    color: u32 = 0xFFFFFFFF, // RRGGBBAA
    layer: i32 = 0,
};

pub const Sprite = struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,
    tex_data: ?[*]const u8 = null, // RGBA bytes, 4 bytes per pixel
    tex_width: u32 = 0,
    tex_height: u32 = 0,
    layer: i32 = 0,
};
