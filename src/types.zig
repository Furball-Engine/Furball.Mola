const PixelType = @import("pixel_types.zig");

pub const RenderBitmap = extern struct {
    pixel_type: PixelType.pixel_type,
    width: c_uint,
    height: c_uint,
    rgba32ptr: [*]PixelType.rgba32,
    argb32ptr: [*]PixelType.argb32
};