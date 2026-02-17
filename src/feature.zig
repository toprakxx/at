const zm = @import("zmath");
// definitions for common entity features
pub const Material = struct {
    color: zm.F32x4,
};
pub const Mesh3D = struct {
    pos: zm.F32x4,
    rotation: zm.Quat = zm.qidentity(),
    scale: zm.F32x4 = zm.f32x4s(1.0),
    num_vertices: u32,
    num_indices: u32,
    vertices: [*]zm.F32x4,
    indices: [*]zm.U32x4, // first 3 numbers are indices and last is bitcast rgba color
    mat: ?Material,
    draw: bool = false,
};
