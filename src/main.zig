const std = @import("std");
const pixel_types = @import("pixel_types.zig");
const Types = @import("types.zig");
const RenderBitmap = Types.RenderBitmap;
const rasterization = @import("rasterization.zig");

const allocator = std.heap.page_allocator;

export fn create_render_bitmap(width: c_uint, height: c_uint, pixel_type: pixel_types.pixel_type) callconv(.C) *RenderBitmap {
    var instance: *RenderBitmap = allocator.create(RenderBitmap) catch std.os.abort();
    
    switch(pixel_type) {
        pixel_types.pixel_type.rgba32 => {
            instance.pixel_type = pixel_types.pixel_type.rgba32;
            var arr: []pixel_types.rgba32 = allocator.alloc(pixel_types.rgba32, width * height) catch @panic("Out of memory!");
            instance.rgba32ptr = arr.ptr;
        },
        pixel_types.pixel_type.argb32 => {
            instance.pixel_type = pixel_types.pixel_type.argb32;
            var arr: []pixel_types.argb32 = allocator.alloc(pixel_types.argb32, width * height) catch @panic("Out of memory!");
            instance.argb32ptr = arr.ptr;
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
            allocator.free(bitmap.rgba32ptr[0..(bitmap.width * bitmap.height)]);
        },
        pixel_types.pixel_type.argb32 => {
            allocator.free(bitmap.argb32ptr[0..(bitmap.width * bitmap.height)]);
        }
    }
}