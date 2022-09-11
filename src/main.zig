const std = @import("std");
const pixel_types = @import("pixel_types.zig");
const Types = @import("types.zig");
const RenderBitmap = Types.RenderBitmap;

const Vector2 = @import("types.zig").Vector2;
const Color = @import("pixel_types.zig").rgba128;
const Vertex = @import("types.zig").Vertex;

const allocator = std.heap.page_allocator;

export fn create_render_bitmap(width: c_uint, height: c_uint, pixel_type: pixel_types.pixel_type) callconv(.C) *RenderBitmap {
    var instance: *RenderBitmap = allocator.create(RenderBitmap) catch std.os.abort();

    switch (pixel_type) {
        pixel_types.pixel_type.rgba32 => {
            instance.pixel_type = pixel_types.pixel_type.rgba32;
            var arr: []pixel_types.rgba32 = allocator.alloc(pixel_types.rgba32, width * height) catch @panic("Out of memory!");
            instance.rgba32ptr = arr.ptr;
        },
        pixel_types.pixel_type.argb32 => {
            instance.pixel_type = pixel_types.pixel_type.argb32;
            var arr: []pixel_types.argb32 = allocator.alloc(pixel_types.argb32, width * height) catch @panic("Out of memory!");
            instance.argb32ptr = arr.ptr;
        },
    }

    instance.width = width;
    instance.height = height;

    return instance;
}

export fn clear_render_bitmap(bitmap: *RenderBitmap) callconv(.C) void {
    var i: usize = 0;
    var pixel_count: c_uint = bitmap.width * bitmap.height;

    switch (bitmap.pixel_type) {
        pixel_types.pixel_type.rgba32 => {
            while (i < pixel_count) : (i += 1) {
                bitmap.rgba32ptr[i] = .{ .r = 0, .g = 0, .b = 0, .a = 255 };
            }
        },
        pixel_types.pixel_type.argb32 => {
            while (i < pixel_count) : (i += 1) {
                bitmap.argb32ptr[i] = .{ .r = 0, .g = 0, .b = 0, .a = 255 };
            }
        },
    }
}

export fn delete_render_bitmap(bitmap: *RenderBitmap) callconv(.C) void {
    switch (bitmap.pixel_type) {
        pixel_types.pixel_type.rgba32 => {
            allocator.free(bitmap.rgba32ptr[0..(bitmap.width * bitmap.height)]);
        },
        pixel_types.pixel_type.argb32 => {
            allocator.free(bitmap.argb32ptr[0..(bitmap.width * bitmap.height)]);
        },
    }
}

export fn draw_onto_bitmap(bitmap: *RenderBitmap, vertices: [*]Vertex, indices: [*]c_ushort, index_count: c_uint) callconv(.C) void {
    if (index_count % 3 != 0)
        @panic("Index count is not a multiple of 3");

    var i: usize = 0;
    //Iterate through all indices
    while (i < index_count) : (i += 3) {
        //Rasterize each triangle
        rasterize_triangle(bitmap, vertices[indices[i]], vertices[indices[i + 1]], vertices[indices[i + 2]]);
    }
}

export fn rasterize_triangle(bitmap: *RenderBitmap, vtx1: Vertex, vtx2: Vertex, vtx3: Vertex) callconv(.C) void {
    var ax0: i32 = @floatToInt(i32, vtx1.position.x);
    var ay0: i32 = @floatToInt(i32, vtx1.position.y);
    var ax1: i32 = @floatToInt(i32, vtx2.position.x);
    var ay1: i32 = @floatToInt(i32, vtx2.position.y);
    var ax2: i32 = @floatToInt(i32, vtx3.position.x);
    var ay2: i32 = @floatToInt(i32, vtx3.position.y); 
    
    if (ay0>ay1) {
        swap_ints(&ax0, &ax1);
        swap_ints(&ay0, &ay1);
    }
    if (ay0>ay2) {
        swap_ints(&ax0, &ax2);
        swap_ints(&ay0, &ay2);
    }
    if (ay1>ay2) {
        swap_ints(&ax1, &ax2);
        swap_ints(&ay1, &ay2);
    }

    rasterize_line(bitmap, .{.x = @intToFloat(f32, ax0), .y = @intToFloat(f32, ay0)}, .{.x = @intToFloat(f32, ax1), .y = @intToFloat(f32, ay1)}, .{.r = 0, .g = 255, .b = 0, .a = 0});
    rasterize_line(bitmap, .{.x = @intToFloat(f32, ax1), .y = @intToFloat(f32, ay1)}, .{.x = @intToFloat(f32, ax2), .y = @intToFloat(f32, ay2)}, .{.r = 0, .g = 255, .b = 0, .a = 0});
    rasterize_line(bitmap, .{.x = @intToFloat(f32, ax2), .y = @intToFloat(f32, ay2)}, .{.x = @intToFloat(f32, ax0), .y = @intToFloat(f32, ay0)}, .{.r = 255, .g = 0, .b = 0, .a = 0});
}

fn swap_ints(x: *i32, y: *i32) void {
    //Set X to the sum of the 2
    x.* = x.* + y.*;
    //Get the original X value out and place it in Y
    y.* = x.* - y.*;
    //Get the original Y value out using the original X and place it in X
    x.* = x.* - y.*;
}

export fn set_bitmap_pixel(bitmap: *RenderBitmap, x: i32, y: i32, col: pixel_types.rgba32) callconv(.C) void {
    if(x >= bitmap.width or y >= bitmap.height)
        return;

    var pos = (@intCast(usize, y) * @intCast(usize, bitmap.width)) + @intCast(usize, x);

    switch (bitmap.pixel_type) {
        pixel_types.pixel_type.rgba32 => {
            bitmap.rgba32ptr[pos] = col;
        },
        pixel_types.pixel_type.argb32 => {
            bitmap.argb32ptr[pos].r = col.r;
            bitmap.argb32ptr[pos].g = col.g;
            bitmap.argb32ptr[pos].b = col.b;
            bitmap.argb32ptr[pos].a = col.a;
        },
    }
}

export fn rasterize_line(bitmap: *RenderBitmap, p0: Vector2, p1: Vector2, col: pixel_types.rgba32) callconv(.C) void {
    var ax0: i32 = @floatToInt(i32, p0.x);
    var ay0: i32 = @floatToInt(i32, p0.y);
    var ax1: i32 = @floatToInt(i32, p1.x);
    var ay1: i32 = @floatToInt(i32, p1.y);

    std.debug.print("Drawing line with points {d}x{d},{d}x{d}\n", .{ax0, ay0, ax1, ay1});

    var steep: bool = false;
    //Check whether the the difference in X is less than the difference in Y (aka is slope greater than 0.5)
    if ((std.math.absInt(ax0 - ax1) catch @panic("Unable to ABS x0 and x1")) < (std.math.absInt(ay0 - ay1) catch @panic("Unable to ABS y0 and y1"))) {
        swap_ints(&ax0, &ay0);
        swap_ints(&ax1, &ay1);
        steep = true;
    }
    //If the first point is to the right of the second point, swap the points
    if (ax0 > ax1) {
        swap_ints(&ax0, &ax1);
        swap_ints(&ay0, &ay1);
    }
    //Get the difference in X
    var dx: i32 = ax1 - ax0;
    //Get the difference in Y
    var dy: i32 = ay1 - ay0;
    //The error in difference
    var derror2: i32 = (std.math.absInt(dy) catch @panic("Unable to ABS dy")) * 2;
    //The distance to the best straight line from our current position
    var error2: i32 = 0;
    var y: i32 = ay0;
    var x: i32 = ax0;
    while (x <= ax1) : (x += 1) {
        if (steep) {
            set_bitmap_pixel(bitmap, y, x, col);
        } else {
            set_bitmap_pixel(bitmap, x, y, col);
        }
        error2 += derror2;
        if (error2 > dx) {
            y += (if (ay1 > ay0) 1 else -1);
            error2 -= dx * 2;
        }
    }
}
