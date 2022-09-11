const std = @import("std");
const pixel_types = @import("pixel_types.zig");
const Types = @import("types.zig");
const RenderBitmap = Types.RenderBitmap;

const allocator = std.heap.c_allocator;

export fn create_render_bitmap(width: c_uint, height: c_uint, pixel_type: pixel_types.pixel_type) callconv(.C) *RenderBitmap {
    var instance: *RenderBitmap = allocator.create(RenderBitmap) catch std.os.abort();
    
    switch(pixel_type) {
        pixel_types.pixel_type.rgba32 => {
            instance.pixel_type = pixel_types.pixel_type.rgba32;
            var ptr = std.c.malloc(@sizeOf(pixel_types.rgba32) * width * height);
            instance.rgba32ptr = @ptrCast([*]pixel_types.rgba32, ptr);
        },
        pixel_types.pixel_type.argb32 => {
            instance.pixel_type = pixel_types.pixel_type.argb32;
            var ptr = std.c.malloc(@sizeOf(pixel_types.argb32) * width * height);
            instance.argb32ptr = @ptrCast([*]pixel_types.argb32, ptr);
        }
    }

    instance.width = width;
    instance.height = height;

    return instance;
}

export fn clear_render_bitmap(bitmap: *RenderBitmap) callconv(.C) void {
    var i: usize = 0;
    var pixel_count: c_uint = bitmap.width * bitmap.height;

    switch(bitmap.pixel_type) {
        pixel_types.pixel_type.rgba32 => {
            while(i < pixel_count) : (i += 1) {
                bitmap.rgba32ptr[i] = .{.r = 0, .g = 0, .b = 0, .a = 255};
            }
        },
        pixel_types.pixel_type.argb32 => {
            while(i < pixel_count) : (i += 1) {
                bitmap.argb32ptr[i] = .{.r = 0, .g = 0, .b = 0, .a = 255};
            }
        }
    }
}

export fn delete_render_bitmap(bitmap: *RenderBitmap) callconv(.C) void {
    switch(bitmap.pixel_type) {
        pixel_types.pixel_type.rgba32 => {
            std.c.free(bitmap.rgba32ptr);
        },
        pixel_types.pixel_type.argb32 => {
            std.c.free(bitmap.argb32ptr);
        }
    }
}