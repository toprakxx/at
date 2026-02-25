// .atmap file format parser
//
// File layout:
//   ATMAP1
//   tilesize <w> <h>
//   mapsize  <cols> <rows>
//   tilesets <count>
//   TILESETCOLS <slot> <cols>   (one per tileset; slot cols known at load time)
//   tilesetcols <n>             (legacy single-tileset, maps to slot 0)
//   layers <count>
//   LAYER <index> <name> <collide|nocollide> [<tileset_idx>]
//   <tile_id> ...  (map_width values per row, map_height rows)
//   LAYER ...
//
// Tile IDs: 0 = empty, 1+ = 1-based index into the layer's assigned tileset.

const std = @import("std");
const wa = std.heap.wasm_allocator;
const io = @import("io.zig");
const feature = @import("feature.zig");

pub fn parse(data: []const u8) ?feature.TileMap {
    var lines = std.mem.splitScalar(u8, data, '\n');

    const first = std.mem.trim(u8, lines.next() orelse return null, " \r\t");
    if (!std.mem.eql(u8, first, "ATMAP1")) {
        io.print("tilemap: invalid magic\n", .{});
        return null;
    }

    var tile_width: u32 = 0;
    var tile_height: u32 = 0;
    var map_width: u32 = 0;
    var map_height: u32 = 0;
    var num_layers: u32 = 0;
    var layers_buf: ?[]feature.TileLayer = null;
    var current_layer: i32 = -1;
    var tile_count: usize = 0;
    var tilesets = [_]feature.Tileset{.{}} ** feature.MAX_TILESETS;
    var num_tilesets: u8 = 0;

    while (lines.next()) |raw| {
        const line = std.mem.trim(u8, raw, " \r\t");
        if (line.len == 0 or line[0] == '#') continue;

        if (std.mem.startsWith(u8, line, "tilesize ")) {
            var it = std.mem.splitScalar(u8, line[9..], ' ');
            tile_width = std.fmt.parseInt(u32, it.next() orelse return null, 10) catch return null;
            tile_height = std.fmt.parseInt(u32, it.next() orelse return null, 10) catch return null;
        } else if (std.mem.startsWith(u8, line, "mapsize ")) {
            var it = std.mem.splitScalar(u8, line[8..], ' ');
            map_width = std.fmt.parseInt(u32, it.next() orelse return null, 10) catch return null;
            map_height = std.fmt.parseInt(u32, it.next() orelse return null, 10) catch return null;
        } else if (std.mem.startsWith(u8, line, "tilesets ")) {
            // number of tilesets declared; data loaded at runtime
            num_tilesets = std.fmt.parseInt(u8, std.mem.trim(u8, line[9..], " \r\t"), 10) catch 0;
        } else if (std.mem.startsWith(u8, line, "TILESETCOLS ")) {
            var it = std.mem.splitScalar(u8, line[12..], ' ');
            const slot = std.fmt.parseInt(u8, it.next() orelse "0", 10) catch continue;
            const cols = std.fmt.parseInt(u32, it.next() orelse "0", 10) catch continue;
            if (slot < feature.MAX_TILESETS) tilesets[slot].cols = cols;
        } else if (std.mem.startsWith(u8, line, "tilesetcols ")) {
            // legacy single-tileset format: treat as slot 0
            tilesets[0].cols = std.fmt.parseInt(u32, std.mem.trim(u8, line[12..], " \r\t"), 10) catch 0;
            if (num_tilesets == 0) num_tilesets = 1;
        } else if (std.mem.startsWith(u8, line, "layers ")) {
            num_layers = std.fmt.parseInt(u32, line[7..], 10) catch return null;
            if (num_layers == 0 or map_width == 0 or map_height == 0) return null;
            const tiles_per_layer = map_width * map_height;
            layers_buf = wa.alloc(feature.TileLayer, num_layers) catch return null;
            for (layers_buf.?) |*layer| {
                const tiles = wa.alloc(u16, tiles_per_layer) catch return null;
                @memset(tiles, 0);
                layer.* = .{ .tiles = tiles.ptr };
            }
        } else if (std.mem.startsWith(u8, line, "LAYER ")) {
            const rest = line[6..];
            var it = std.mem.splitScalar(u8, rest, ' ');
            const idx = std.fmt.parseInt(u32, it.next() orelse return null, 10) catch return null;
            const layers = layers_buf orelse return null;
            if (idx >= num_layers) return null;
            current_layer = @intCast(idx);
            tile_count = 0;
            const name = it.next() orelse "Layer";
            const col_str = it.next() orelse "nocollide";
            const ts_str = it.next() orelse "0";
            const name_len: u8 = @intCast(@min(name.len, 32));
            @memcpy(layers[idx].name[0..name_len], name[0..name_len]);
            layers[idx].name_len = name_len;
            layers[idx].collision = std.mem.eql(u8, col_str, "collide");
            layers[idx].tileset_idx = std.fmt.parseInt(u8, ts_str, 10) catch 0;
        } else if (current_layer >= 0) {
            const layers = layers_buf orelse continue;
            const li: usize = @intCast(current_layer);
            const max = map_width * map_height;
            var it = std.mem.splitScalar(u8, line, ' ');
            while (it.next()) |tok| {
                const t = std.mem.trim(u8, tok, " \t\r");
                if (t.len == 0) continue;
                if (tile_count >= max) break;
                layers[li].tiles[tile_count] = std.fmt.parseInt(u16, t, 10) catch 0;
                tile_count += 1;
            }
        }
    }

    const layers = layers_buf orelse return null;
    if (tile_width == 0 or tile_height == 0 or map_width == 0 or map_height == 0) return null;

    return feature.TileMap{
        .tile_width = tile_width,
        .tile_height = tile_height,
        .map_width = map_width,
        .map_height = map_height,
        .layers = layers.ptr,
        .num_layers = num_layers,
        .tilesets = tilesets,
        .num_tilesets = num_tilesets,
    };
}
