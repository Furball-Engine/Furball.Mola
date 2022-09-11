const RenderBitmap = @import("types.zig").RenderBitmap;
const Vector2 = @import("types.zig").Vector2;
const Color = @import("pixel_types.zig").rgba128;
const Vertex = @import("types.zig").Vertex;
const std = @import("std");

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

fn area_of_triangle(p1: Vector2, p2: Vector2, p3: Vector2) f32 { //find area of triangle formed by p1, p2 and p3
    var f: f32 = (p1.x * (p2.y - p3.y) + p2.x * (p3.y - p1.y) + p3.x * (p1.yp2.y)) / 2.0;

    if (f < 0)
        f = -f;

    return f;
}

fn point_in_triangle(p1: Vector2, p2: Vector2, p3: Vector2, p: Vector2) bool {
    var area = area_of_triangle(p1, p2, p3); //area of triangle ABC
    var area1 = area_of_triangle(p, p2, p3); //area of PBC
    var area2 = area_of_triangle(p1, p, p3); //area of APC
    var area3 = area_of_triangle(p1, p2, p); //area of ABP

    return (area == area1 + area2 + area3); //when three triangles are forming the whole triangle
}

export fn rasterize_triangle(bitmap: *RenderBitmap, vtx1: *Vertex, vtx2: *Vertex, vtx3: *Vertex) void {
    //Get bounding box
    var bounding_left: f32 = std.math.min3(vtx1.position.x, vtx2.position.x, vtx3.position.x);
    var bounding_right = std.math.max3(vtx1.position.x, vtx2.position.x, vtx3.position.x);
    var bounding_top = std.math.min3(vtx1.position.y, vtx2.position.y, vtx3.position.y);
    var bounding_bottom = std.math.max3(vtx1.position.y, vtx2.position.y, vtx3.position.y);

    //Iterate over all pixels in bounding box
    var x: i32 = @floatToInt(i32, bounding_left);
    var y: i32 = @floatToInt(i32, bounding_top);

    _ = bitmap;
    while (x < bounding_right) : (x += 1) {
        while (y < bounding_bottom) : (y += 1) {
            if (point_in_triangle(vtx1.position, vtx2.position, vtx3.position, Vector2{ .x = @intToFloat(f32, x), .y = @intToFloat(f32, y) })) {}
        }
    }
}
