const PixelType = @import("pixel_types.zig");

// zig fmt: off
pub const RenderBitmap = extern struct { 
    pixel_type: PixelType.pixel_type, 
    width: c_uint, 
    height: c_uint, 
    rgba32ptr: [*]PixelType.rgba32, 
    argb32ptr: [*]PixelType.argb32, 
    scissor_x: c_uint, 
    scissor_y: c_uint, 
    scissor_w: c_uint, 
    scissor_h: c_uint 
};
// zig fmt: on

pub const Vector2 = extern struct {
    x: f32,
    y: f32,
    pub fn eq(self: Vector2, v2: Vector2) bool {
        return self.x == v2.x and self.y == v2.y;
    }
};
pub const Vector3 = extern struct { x: f32, y: f32, z: f32 };
pub const Vector2i = extern struct { x: i32, y: i32 };

// zig fmt: off
pub const Vertex = extern struct { 
    position: Vector2, 
    texture_coordinate: Vector2, 
    color: PixelType.rgba128, 
    tex_id: c_long 
};
// zig fmt: on
