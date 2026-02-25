// DO NOT EXPORT ANY FUNCTIONS OUTSIDE OF THIS FILE

// keep code c style for wabi compatibility

const std = @import("std");
pub const Canvas = @import("canvas.zig").Canvas;
pub const pixel = @import("pixel.zig");
pub const io = @import("io.zig");
pub const TA_Allocator = @import("allocator.zig").TA_Allocator;
const wa = std.heap.wasm_allocator;
//
const zm = @import("zmath");
const Renderer = @import("renderer.zig").Renderer;

const Scene = @import("renderer.zig").Scene;
const feature = @import("feature.zig");
const ecs = @import("ecs");

const ModelLoader = @import("model_loader.zig").ModelLoader;

const Keyboard = io.Keyboard;
const KeyCode = io.KeyCode;
var allocator: TA_Allocator = undefined;
var interface_kb: Keyboard = undefined;
var canvas: Canvas = undefined;
//
var renderer: Renderer = undefined;

//TODO add model loading functions and load them via js to then render
var scene: *Scene = undefined;

var initialized: bool = false;

export fn interface_init() u32 {
    if (!initialized) {
        allocator = TA_Allocator.new();
        allocator.init(3); // create allocator with 3 arena and 1 gpa
        interface_kb = Keyboard.new();

        initialized = true;
        canvas = Canvas.new(
            800,
            600,
            allocator.allocator(),
        );
        canvas.init();
        // TODO remove
        renderer = Renderer.new(allocator.allocator());
        //TODO remove
    }
    return 1;
}
// no need to call since js sucks ass and you cant really call it also browser cleans up aftfer the program so
// export fn interface_deinit() void {
//     if (initialized) {
//         aAllocator.deinit();
//         initialized = false;
//     }
// }
export fn keyboard_keyDown(key: u8) void {
    interface_kb.keyDown(@enumFromInt(key));
}
export fn keyboard_keyUp(key: u8) void {
    interface_kb.keyUp(@enumFromInt(key));
}
export fn canvas_getWidth() usize {
    return canvas.width;
}
export fn canvas_getHeight() usize {
    return canvas.height;
}
export fn canvas_getBuffer() [*]u32 {
    return canvas.getBuffer();
}
export fn canvas_clearBuffer() void {
    canvas.clearBuffer();
}

export fn alloc(len: usize) ?[*]u8 {
    const buf = wa.alignedAlloc(u8, .fromByteUnits(16), len) catch return null;
    return buf.ptr;
}

export fn free(ptr: [*]u8, len: usize) void {
    wa.free(ptr[0..len]);
}

export fn renderer_add_scene(name_ptr: [*]const u8, name_len: u32) ?*Scene {
    const name = name_ptr[0..name_len];
    const sc = wa.create(Scene) catch return null;
    sc.* = Scene.init(wa);
    renderer.scenes.put(name, sc) catch return null;
    return sc;
}
export fn renderer_get_scene(name_ptr: [*]const u8, name_len: u32) ?*Scene {
    const name = name_ptr[0..name_len];
    return renderer.scenes.get(name);
}

export fn load_obj(scene_name_ptr: [*]const u8, scene_name_len: u32, data_ptr: [*]const u8, len: usize) u32 {
    // 0 is usually null entity in entt but let's just return a placeholder or 0
    const scene_name = scene_name_ptr[0..scene_name_len];
    var sc = renderer.scenes.get(scene_name) orelse return std.math.maxInt(u32);
    const ent = sc.entities.create();
    sc.entities.add(ent, ModelLoader.loadObj(data_ptr, len) orelse feature.Mesh3D.default());
    return @bitCast(ent);
}

export fn get_scene_entity(scene_name_ptr: [*]const u8, scene_name_len: u32, entity_name_ptr: [*]const u8, entity_name_len: u32) u32 {
    const scene_name = scene_name_ptr[0..scene_name_len];
    const entity_name = entity_name_ptr[0..entity_name_len];
    if (renderer.scenes.get(scene_name)) |sc| {
        var view = sc.entities.view(.{feature.Mesh3D}, .{});
        var iterator = view.entityIterator();
        while (iterator.next()) |entity| {
            if (sc.entities.tryGet(feature.Mesh3D, entity)) |mesh| {
                const mesh_name = mesh.name[0..mesh.name_len];
                if (std.mem.eql(u8, mesh_name, entity_name)) {
                    return @bitCast(entity);
                }
            }
        }
    }
    return std.math.maxInt(u32);
}

export fn modify_entity_feature(scene_name_ptr: [*]const u8, scene_name_len: u32, entity_id: u32, feature_id: u32, data_ptr: [*]const f32) void {
    const scene_name = scene_name_ptr[0..scene_name_len];
    const entity: ecs.Entity = @bitCast(entity_id);
    if (renderer.scenes.get(scene_name)) |sc| {
        if (sc.entities.tryGet(feature.Mesh3D, entity)) |mesh| {
             switch (feature_id) {
                0 => { // position
                    mesh.pos[0] = data_ptr[0];
                    mesh.pos[1] = data_ptr[1];
                    mesh.pos[2] = data_ptr[2];
                },
                1 => { // rotation
                    // Assuming quaternion input x,y,z,w
                    mesh.rotation[0] = data_ptr[0];
                    mesh.rotation[1] = data_ptr[1];
                    mesh.rotation[2] = data_ptr[2];
                    mesh.rotation[3] = data_ptr[3];
                },
                2 => { // scale
                    mesh.scale[0] = data_ptr[0];
                    mesh.scale[1] = data_ptr[1];
                    mesh.scale[2] = data_ptr[2];
                },
                else => {},
             }
        }
    }
}

export fn rect2d_create(scene_name_ptr: [*]const u8, scene_name_len: u32, x: f32, y: f32, w: f32, h: f32, color: u32) u32 {
    const scene_name = scene_name_ptr[0..scene_name_len];
    const sc = renderer.scenes.get(scene_name) orelse return std.math.maxInt(u32);
    const ent = sc.entities.create();
    sc.entities.add(ent, feature.Rect2D{ .x = x, .y = y, .width = w, .height = h, .color = color });
    return @bitCast(ent);
}

export fn sprite_create(scene_name_ptr: [*]const u8, scene_name_len: u32, x: f32, y: f32, w: f32, h: f32, tex_ptr: [*]const u8, tex_w: u32, tex_h: u32) u32 {
    const scene_name = scene_name_ptr[0..scene_name_len];
    const sc = renderer.scenes.get(scene_name) orelse return std.math.maxInt(u32);
    const ent = sc.entities.create();
    sc.entities.add(ent, feature.Sprite{ .x = x, .y = y, .width = w, .height = h, .tex_data = tex_ptr, .tex_width = tex_w, .tex_height = tex_h });
    return @bitCast(ent);
}

export fn entity2d_set_pos(scene_name_ptr: [*]const u8, scene_name_len: u32, entity_id: u32, x: f32, y: f32) void {
    const scene_name = scene_name_ptr[0..scene_name_len];
    const entity: ecs.Entity = @bitCast(entity_id);
    if (renderer.scenes.get(scene_name)) |sc| {
        if (sc.entities.tryGet(feature.Rect2D, entity)) |rect| {
            rect.x = x;
            rect.y = y;
        } else if (sc.entities.tryGet(feature.Sprite, entity)) |sprite| {
            sprite.x = x;
            sprite.y = y;
        }
    }
}

export fn rect2d_set_color(scene_name_ptr: [*]const u8, scene_name_len: u32, entity_id: u32, color: u32) void {
    const scene_name = scene_name_ptr[0..scene_name_len];
    const entity: ecs.Entity = @bitCast(entity_id);
    if (renderer.scenes.get(scene_name)) |sc| {
        if (sc.entities.tryGet(feature.Rect2D, entity)) |rect| {
            rect.color = color;
        }
    }
}

export fn sprite_set_texture(scene_name_ptr: [*]const u8, scene_name_len: u32, entity_id: u32, tex_ptr: [*]const u8, tex_w: u32, tex_h: u32) void {
    const scene_name = scene_name_ptr[0..scene_name_len];
    const entity: ecs.Entity = @bitCast(entity_id);
    if (renderer.scenes.get(scene_name)) |sc| {
        if (sc.entities.tryGet(feature.Sprite, entity)) |sprite| {
            sprite.tex_data = tex_ptr;
            sprite.tex_width = tex_w;
            sprite.tex_height = tex_h;
        }
    }
}

// ─── Tilemap ─────────────────────────────────────────────────────────────────

export fn tilemap_load(scene_name_ptr: [*]const u8, scene_name_len: u32, data_ptr: [*]const u8, data_len: usize) u32 {
    const scene_name = scene_name_ptr[0..scene_name_len];
    const sc = renderer.scenes.get(scene_name) orelse return std.math.maxInt(u32);
    const tm = @import("tilemap.zig").parse(data_ptr[0..data_len]) orelse return std.math.maxInt(u32);
    const ent = sc.entities.create();
    sc.entities.add(ent, tm);
    return @bitCast(ent);
}

export fn tilemap_create(scene_name_ptr: [*]const u8, scene_name_len: u32, tile_w: u32, tile_h: u32, map_w: u32, map_h: u32, num_layers: u32) u32 {
    const scene_name = scene_name_ptr[0..scene_name_len];
    const sc = renderer.scenes.get(scene_name) orelse return std.math.maxInt(u32);
    if (num_layers == 0 or map_w == 0 or map_h == 0 or tile_w == 0 or tile_h == 0) return std.math.maxInt(u32);
    const layers = wa.alloc(feature.TileLayer, num_layers) catch return std.math.maxInt(u32);
    for (layers) |*layer| {
        const tiles = wa.alloc(u16, map_w * map_h) catch return std.math.maxInt(u32);
        @memset(tiles, 0);
        layer.* = .{ .tiles = tiles.ptr };
    }
    const ent = sc.entities.create();
    sc.entities.add(ent, feature.TileMap{
        .tile_width = tile_w, .tile_height = tile_h,
        .map_width = map_w,   .map_height = map_h,
        .layers = layers.ptr, .num_layers = num_layers,
    });
    return @bitCast(ent);
}

// Set data on a specific tileset slot (slot must be < MAX_TILESETS).
export fn tilemap_set_tileset(scene_name_ptr: [*]const u8, scene_name_len: u32, entity_id: u32, slot: u32, tileset_ptr: [*]const u8, ts_w: u32, ts_h: u32, ts_cols: u32) void {
    if (slot >= feature.MAX_TILESETS) return;
    const scene_name = scene_name_ptr[0..scene_name_len];
    const entity: ecs.Entity = @bitCast(entity_id);
    if (renderer.scenes.get(scene_name)) |sc| {
        if (sc.entities.tryGet(feature.TileMap, entity)) |tm| {
            tm.tilesets[slot] = .{ .data = tileset_ptr, .pixel_width = ts_w, .pixel_height = ts_h, .cols = ts_cols };
            if (@as(u8, @intCast(slot)) >= tm.num_tilesets) tm.num_tilesets = @intCast(slot + 1);
        }
    }
}

// Append a new tileset slot and return its index. Returns maxInt(u32) if full.
export fn tilemap_add_tileset(scene_name_ptr: [*]const u8, scene_name_len: u32, entity_id: u32, tileset_ptr: [*]const u8, ts_w: u32, ts_h: u32, ts_cols: u32) u32 {
    const scene_name = scene_name_ptr[0..scene_name_len];
    const entity: ecs.Entity = @bitCast(entity_id);
    if (renderer.scenes.get(scene_name)) |sc| {
        if (sc.entities.tryGet(feature.TileMap, entity)) |tm| {
            if (tm.num_tilesets >= feature.MAX_TILESETS) return std.math.maxInt(u32);
            const idx = tm.num_tilesets;
            tm.tilesets[idx] = .{ .data = tileset_ptr, .pixel_width = ts_w, .pixel_height = ts_h, .cols = ts_cols };
            tm.num_tilesets += 1;
            return idx;
        }
    }
    return std.math.maxInt(u32);
}

// Assign a tileset slot to a layer.
export fn tilemap_set_layer_tileset(scene_name_ptr: [*]const u8, scene_name_len: u32, entity_id: u32, layer: u32, tileset_idx: u32) void {
    const scene_name = scene_name_ptr[0..scene_name_len];
    const entity: ecs.Entity = @bitCast(entity_id);
    if (renderer.scenes.get(scene_name)) |sc| {
        if (sc.entities.tryGet(feature.TileMap, entity)) |tm| {
            if (layer < tm.num_layers and tileset_idx < feature.MAX_TILESETS)
                tm.layers[layer].tileset_idx = @intCast(tileset_idx);
        }
    }
}

export fn tilemap_set_tile(scene_name_ptr: [*]const u8, scene_name_len: u32, entity_id: u32, layer: u32, tx: u32, ty: u32, tile_id: u32) void {
    const scene_name = scene_name_ptr[0..scene_name_len];
    const entity: ecs.Entity = @bitCast(entity_id);
    if (renderer.scenes.get(scene_name)) |sc| {
        if (sc.entities.tryGet(feature.TileMap, entity)) |tm| {
            tm.setTile(layer, tx, ty, @intCast(@min(tile_id, std.math.maxInt(u16))));
        }
    }
}

export fn tilemap_get_tile(scene_name_ptr: [*]const u8, scene_name_len: u32, entity_id: u32, layer: u32, tx: u32, ty: u32) u32 {
    const scene_name = scene_name_ptr[0..scene_name_len];
    const entity: ecs.Entity = @bitCast(entity_id);
    if (renderer.scenes.get(scene_name)) |sc| {
        if (sc.entities.tryGet(feature.TileMap, entity)) |tm| {
            return tm.getTile(layer, tx, ty);
        }
    }
    return 0;
}

export fn tilemap_set_offset(scene_name_ptr: [*]const u8, scene_name_len: u32, entity_id: u32, ox: f32, oy: f32) void {
    const scene_name = scene_name_ptr[0..scene_name_len];
    const entity: ecs.Entity = @bitCast(entity_id);
    if (renderer.scenes.get(scene_name)) |sc| {
        if (sc.entities.tryGet(feature.TileMap, entity)) |tm| {
            tm.offset_x = ox;
            tm.offset_y = oy;
        }
    }
}

// Returns 1 if AABB collides with any solid tile, 0 otherwise.
export fn tilemap_collides(scene_name_ptr: [*]const u8, scene_name_len: u32, entity_id: u32, x: f32, y: f32, w: f32, h: f32) u32 {
    const scene_name = scene_name_ptr[0..scene_name_len];
    const entity: ecs.Entity = @bitCast(entity_id);
    if (renderer.scenes.get(scene_name)) |sc| {
        if (sc.entities.tryGet(feature.TileMap, entity)) |tm| {
            return if (tm.collidesAABB(x, y, w, h)) 1 else 0;
        }
    }
    return 0;
}

export fn tilemap_set_layer_collision(scene_name_ptr: [*]const u8, scene_name_len: u32, entity_id: u32, layer: u32, enabled: u32) void {
    const scene_name = scene_name_ptr[0..scene_name_len];
    const entity: ecs.Entity = @bitCast(entity_id);
    if (renderer.scenes.get(scene_name)) |sc| {
        if (sc.entities.tryGet(feature.TileMap, entity)) |tm| {
            if (layer < tm.num_layers) tm.layers[layer].collision = enabled != 0;
        }
    }
}

// program entry

pub export fn update() void {
    // Clear buffer
    canvas.clearBuffer();

    // Draw scene
    const buffer_bytes = std.mem.sliceAsBytes(canvas.buffer);
    renderer.drawToBuf(buffer_bytes, @intCast(canvas.width));

    interface_kb.endFrame();
}
