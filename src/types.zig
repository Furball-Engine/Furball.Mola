const PixelType = @import("pixel_types.zig");

pub const RenderBitmap = extern struct { pixel_type: PixelType.pixel_type, width: c_uint, height: c_uint, rgba32ptr: [*]PixelType.rgba32, argb32ptr: [*]PixelType.argb32 };

pub const Vector2 = extern struct { x: f32, y: f32 };

pub const Vertex = extern struct { position: Vector2, texture_coordinate: Vector2, color: PixelType.rgba128, tex_id: c_long };
