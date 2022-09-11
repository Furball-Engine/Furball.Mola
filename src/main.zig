const std = @import("std");
const pixel_types = @import("pixel_types.zig");
const Types = @import("types.zig");
const RenderBitmap = Types.RenderBitmap;

const Vector2 = @import("types.zig").Vector2;
const Vector3 = @import("types.zig").Vector3;
const Vector2i = @import("types.zig").Vector2i;
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
    var j: usize = 0;
    var pixel_count: c_uint = bitmap.width * bitmap.height;

    switch (bitmap.pixel_type) {
        pixel_types.pixel_type.rgba32 => {
            while (j < pixel_count) : (j += 1) {
                bitmap.rgba32ptr[j] = .{ .r = 0, .g = 0, .b = 0, .a = 255 };
            }
        },
        pixel_types.pixel_type.argb32 => {
            while (j < pixel_count) : (j += 1) {
                bitmap.argb32ptr[j] = .{ .r = 0, .g = 0, .b = 0, .a = 255 };
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

    var j: usize = 0;
    //Iterate through all indices
    while (j < index_count) : (j += 3) {
        //Rasterize each triangle
        rasterize_triangle(bitmap, vertices[indices[j]], vertices[indices[j + 1]], vertices[indices[j + 2]]);
    }
}

fn f(int: i32) f32 {
    return @intToFloat(f32, int);
}

fn i(float: f32) i32 {
    return @floatToInt(i32, float);
}

fn lerp(p0: f32, p1: f32, t: f32) f32 {
    return p0 + (p1 - p0) * t;
}

//https://ncalculators.com/geometry/triangle-area-by-3-points.htm
fn triangle_area(a: Vector2, b: Vector2, c: Vector2) f32 {
    return (a.x * (b.y - c.y) + b.x * (c.y - a.y) + c.x * (a.y - b.y)) / 2;
}

fn get_barycentric_coordinates(total_area: f32, a: Vector2, b: Vector2, c: Vector2, p: Vector2) Vector3 {
    var bary: Vector3 = .{.x = 0, .y = 0, .z = 0};

    // A \
    // |\   \
    // | \     \ 
    // |   \      \ 
    // |     p-------C
    // |   /      /
    // | /     /
    // |/   /     
    // B /

    //Get area of split triangles
    var abp_area: f32 = triangle_area(a, b, p); //OPPOSITE OF C
    var cap_area: f32 = triangle_area(c, a, p); //OPPOSITE OF B
    var bcp_area: f32 = triangle_area(b, c, p); //OPPOSITE OF A

    bary.x = bcp_area / total_area; //A
    bary.y = cap_area / total_area; //B
    bary.z = abp_area / total_area; //C

    if(bary.x < 0) bary.x = -bary.x;
    if(bary.y < 0) bary.y = -bary.y;
    if(bary.z < 0) bary.z = -bary.z;

    return bary;
}

fn get_triangle_interpolated_color(total_area: f32, a: Vertex, b: Vertex, c: Vertex, p: Vector2) Color {
    @setFloatMode(std.builtin.FloatMode.Optimized);
    var bary: Vector3 = get_barycentric_coordinates(total_area, a.position, b.position, c.position, p);

    return .{
        .r = (a.color.r * bary.x) + (b.color.r * bary.y) + (c.color.r * bary.z),
        .g = (a.color.g * bary.x) + (b.color.g * bary.y) + (c.color.g * bary.z),
        .b = (a.color.b * bary.x) + (b.color.b * bary.y) + (c.color.b * bary.z),
        .a = (a.color.a * bary.x) + (b.color.a * bary.y) + (c.color.a * bary.z),
    };
}

export fn rasterize_triangle(bitmap: *RenderBitmap, vtx1: Vertex, vtx2: Vertex, vtx3: Vertex) callconv(.C) void {
    //Since we are doing interop stuff here, we want to specify strict mode
    @setFloatMode(std.builtin.FloatMode.Strict);

    var total_area: f32 = triangle_area(vtx1.position, vtx2.position, vtx3.position);

    //Makes sure we dont do anything silly with a 0 area triangle
    if(total_area == 0)
        return;

    var t0: Vector2i = .{ .x = @floatToInt(i32, vtx1.position.x), .y = @floatToInt(i32, vtx1.position.y) };
    var t1: Vector2i = .{ .x = @floatToInt(i32, vtx2.position.x), .y = @floatToInt(i32, vtx2.position.y) };
    var t2: Vector2i = .{ .x = @floatToInt(i32, vtx3.position.x), .y = @floatToInt(i32, vtx3.position.y) };

    if (t0.y > t1.y) std.mem.swap(Vector2i, &t0, &t1);
    if (t0.y > t2.y) std.mem.swap(Vector2i, &t0, &t2);
    if (t1.y > t2.y) std.mem.swap(Vector2i, &t1, &t2);

    var total_height: i32 = t2.y - t0.y;
    var y: i32 = t0.y;
    while (y <= t1.y) : (y += 1) {
        var segment_height: i32 = t1.y - t0.y + 1;
        var alpha: f32 = f(y - t0.y) / f(total_height);
        var beta: f32 = f(y - t0.y) / f(segment_height); // be careful with divisions by zero
        var a: Vector2i = .{ .x = i(f(t0.x) + f(t2.x - t0.x) * alpha), .y = i(f(t0.y) + f(t2.y - t0.y) * alpha) };
        var b: Vector2i = .{ .x = i(f(t0.x) + f(t1.x - t0.x) * beta), .y = i(f(t0.y) + f(t1.y - t0.y) * beta) };
        if (a.x > b.x) std.mem.swap(Vector2i, &a, &b);
        var j: i32 = a.x;
        while (j <= b.x) : (j += 1) {
            var col: Color = get_triangle_interpolated_color(total_area, vtx1, vtx2, vtx3, .{.x = f(j), .y = f(y)});
            set_bitmap_pixel(bitmap, j, y, col.to_rgba32());
        }
    }
    y = t1.y;
    while (y <= t2.y) : (y += 1) {
        var segment_height: i32 = t2.y - t1.y + 1;
        var alpha: f32 = f(y - t0.y) / f(total_height);
        var beta: f32 = f(y - t1.y) / f(segment_height); // be careful with divisions by zero
        var a: Vector2i = .{ .x = i(f(t0.x) + f(t2.x - t0.x) * alpha), .y = i(f(t0.y) + f(t2.y - t0.y) * alpha) };
        var b: Vector2i = .{ .x = i(f(t1.x) + f(t2.x - t1.x) * beta), .y = i(f(t1.y) + f(t2.y - t1.y) * beta) };
        if (a.x > b.x) std.mem.swap(Vector2i, &a, &b);
        var j: i32 = a.x;
        while (j <= b.x) : (j += 1) {
            var col: Color = get_triangle_interpolated_color(total_area, vtx1, vtx2, vtx3, .{.x = f(j), .y = f(y)});
            set_bitmap_pixel(bitmap, j, y, col.to_rgba32()); // attention, due to int casts t0.y+i != A.y
        }
    }

    // rasterize_line(bitmap, .{.x = @intToFloat(f32, ax0), .y = @intToFloat(f32, ay0)}, .{.x = @intToFloat(f32, ax1), .y = @intToFloat(f32, ay1)}, .{.r = 0, .g = 255, .b = 0, .a = 255});
    // rasterize_line(bitmap, .{.x = @intToFloat(f32, ax1), .y = @intToFloat(f32, ay1)}, .{.x = @intToFloat(f32, ax2), .y = @intToFloat(f32, ay2)}, .{.r = 0, .g = 255, .b = 0, .a = 255});
    // rasterize_line(bitmap, .{.x = @intToFloat(f32, ax2), .y = @intToFloat(f32, ay2)}, .{.x = @intToFloat(f32, ax0), .y = @intToFloat(f32, ay0)}, .{.r = 255, .g = 0, .b = 0, .a = 255});
}

export fn set_bitmap_pixel(bitmap: *RenderBitmap, x: i32, y: i32, col: pixel_types.rgba32) callconv(.C) void {
    if (x >= bitmap.width or y >= bitmap.height)
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

// export fn rasterize_line(bitmap: *RenderBitmap, p0: Vector2, p1: Vector2, col: pixel_types.rgba32) callconv(.C) void {
//     var ax0: i32 = @floatToInt(i32, p0.x);
//     var ay0: i32 = @floatToInt(i32, p0.y);
//     var ax1: i32 = @floatToInt(i32, p1.x);
//     var ay1: i32 = @floatToInt(i32, p1.y);

//     std.debug.print("Drawing line with points {d}x{d},{d}x{d}\n", .{ ax0, ay0, ax1, ay1 });

//     var steep: bool = false;
//     //Check whether the the difference in X is less than the difference in Y (aka is slope greater than 0.5)
//     if ((std.math.absInt(ax0 - ax1) catch @panic("Unable to ABS x0 and x1")) < (std.math.absInt(ay0 - ay1) catch @panic("Unable to ABS y0 and y1"))) {
//         swap_ints(&ax0, &ay0);
//         swap_ints(&ax1, &ay1);
//         steep = true;
//     }
//     //If the first point is to the right of the second point, swap the points
//     if (ax0 > ax1) {
//         swap_ints(&ax0, &ax1);
//         swap_ints(&ay0, &ay1);
//     }
//     //Get the difference in X
//     var dx: i32 = ax1 - ax0;
//     //Get the difference in Y
//     var dy: i32 = ay1 - ay0;
//     //The error in difference
//     var derror2: i32 = (std.math.absInt(dy) catch @panic("Unable to ABS dy")) * 2;
//     //The distance to the best straight line from our current position
//     var error2: i32 = 0;
//     var y: i32 = ay0;
//     var x: i32 = ax0;
//     while (x <= ax1) : (x += 1) {
//         if (steep) {
//             set_bitmap_pixel(bitmap, y, x, col);
//         } else {
//             set_bitmap_pixel(bitmap, x, y, col);
//         }
//         error2 += derror2;
//         if (error2 > dx) {
//             y += (if (ay1 > ay0) 1 else -1);
//             error2 -= dx * 2;
//         }
//     }
// }
