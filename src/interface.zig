// DO NOT EXPORT ANY FUNCTIONS OUTSIDE OF THIS FILE

// keep code c style for js compatibility

const std = @import("std");
pub const Canvas = @import("canvas.zig").Canvas;
pub const pixel = @import("pixel.zig");
pub const io = @import("io.zig");
pub const TA_Allocator = @import("allocator.zig").TA_Allocator;
const TA_ERR = @import("error.zig").TA_ERR;
//
const zm = @import("zmath");
const renderer_pkg = @import("renderer.zig");
const Renderer = renderer_pkg.Renderer;
const Scene = renderer_pkg.Scene;
const feature = @import("feature.zig");
const ecs = @import("ecs");

const Keyboard = io.Keyboard;
const KeyCode = io.KeyCode;

var allocator: TA_Allocator = undefined;
var interface_kb: Keyboard = undefined;
var canvas: Canvas = undefined;
//
var renderer: Renderer = undefined;

//TODO add model loading functions and load them via js to then render
var scene: *Scene = undefined;
var cube_entity: ecs.Entity = undefined;
var cube_rot: f32 = 0.0;

// Storage for mesh data
var vertices: [8]zm.F32x4 = undefined;
var indices: [12]@Vector(4, u32) = undefined;

var initialized: bool = false;

fn initCube() !void {
    vertices = .{
        zm.f32x4(-1.0, -1.0, 1.0, 1.0), // 0
        zm.f32x4(1.0, -1.0, 1.0, 1.0), // 1
        zm.f32x4(1.0, 1.0, 1.0, 1.0), // 2
        zm.f32x4(-1.0, 1.0, 1.0, 1.0), // 3
        zm.f32x4(-1.0, -1.0, -1.0, 1.0), // 4
        zm.f32x4(1.0, -1.0, -1.0, 1.0), // 5
        zm.f32x4(1.0, 1.0, -1.0, 1.0), // 6
        zm.f32x4(-1.0, 1.0, -1.0, 1.0), // 7
    };

    //  abgr color u32
    const red = 0xFF0000FF;
    const green = 0xFF00FF00;
    const blue = 0xFFFF0000;
    const yellow = 0xFF00FFFF;
    const cyan = 0xFFFFFF00;
    const magenta = 0xFFFF00FF;

    //  indices with colors
    indices = .{
        @Vector(4, u32){ 0, 1, 2, red }, @Vector(4, u32){ 2, 3, 0, red }, // Front
        @Vector(4, u32){ 1, 5, 6, green }, @Vector(4, u32){ 6, 2, 1, green }, // Right
        @Vector(4, u32){ 7, 6, 5, blue }, @Vector(4, u32){ 5, 4, 7, blue }, // Back
        @Vector(4, u32){ 4, 0, 3, yellow }, @Vector(4, u32){ 3, 7, 4, yellow }, // Left
        @Vector(4, u32){ 3, 2, 6, cyan }, @Vector(4, u32){ 6, 7, 3, cyan }, // Top
        @Vector(4, u32){ 4, 5, 1, magenta }, @Vector(4, u32){ 1, 0, 4, magenta }, // Bottom
    };

    cube_entity = scene.entities.create();
    scene.entities.add(cube_entity, feature.Mesh3D{
        .pos = zm.f32x4(0.0, 0.0, 0.0, 1.0),
        .rotation = zm.qidentity(),
        .scale = zm.f32x4s(1.0),
        .num_vertices = vertices.len,
        .num_indices = indices.len,
        .vertices = @ptrCast(&vertices),
        .indices = @ptrCast(&indices),
        .mat = null,
        .draw = true,
    });
}

export fn interface_init() TA_ERR {
    if (!initialized) {
        allocator = TA_Allocator.new();
        allocator.init(3); // create allocator with 3 arena and 1 gpa
        interface_kb = Keyboard.new();
        //catch {
        //   io.print("Failed to initialize keyboard interface\n");
        //   return TA_ERR.BAD_INIT; // TODO
        //};

        initialized = true;
        canvas = Canvas.new(
            800,
            600,
            allocator.allocator(),
        );
        canvas.init();
        // TODO remove
        renderer = Renderer.new(allocator.allocator());
        scene = renderer.createScene("Main") catch return TA_ERR.OOM;

        initCube() catch return TA_ERR.BAD_ALLOC;
        //TODO remove
    }
    return TA_ERR.SUCCESS;
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
// program entry

pub export fn update() void {
    if (interface_kb.iskeyDown(.w)) {
        io.print("New val for b: {d}", .{b});
        cube_rot += 0.05;
    }
    if (interface_kb.iskeyDown(.s)) {
        io.print("New val for b: {d}", .{b});
        cube_rot -= 0.05;
    }

    // Spin the cube
    cube_rot += 0.02;
    // Get component
    if (scene.entities.tryGet(feature.Mesh3D, cube_entity)) |mesh| {
        mesh.rotation = zm.quatFromAxisAngle(zm.f32x4(0.0, 1.0, 0.0, 0.0), cube_rot);
        mesh.rotation = zm.qmul(mesh.rotation, zm.quatFromAxisAngle(zm.f32x4(1.0, 0.0, 0.0, 0.0), cube_rot * 0.5));
    }

    // Clear buffer
    canvas.clearBuffer();

    // Draw scene
    const buffer_bytes = std.mem.sliceAsBytes(canvas.buffer);
    renderer.drawToBuf(buffer_bytes, @intCast(canvas.width));

    interface_kb.endFrame();
}
