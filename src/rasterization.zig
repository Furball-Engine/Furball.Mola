const RenderBitmap = @import("types.zig").RenderBitmap;
const Vector2 = @import("types.zig").Vector2;
const Color = @import("pixel_types.zig").rgba128;
const Vertex = @import("types.zig").Vertex;

export fn draw_onto_bitmap(bitmap: *RenderBitmap, vertices: [*]Vertex, indices: [*]c_ushort, index_count: c_uint) callconv(.C) void {
    if(index_count % 3 != 0) 
        @panic("Index count is not a multiple of 3");

    var i: usize = 0;
    //Iterate through all indices
    while(i < index_count) : (i += 3) {
        //Rasterize each triangle
        rasterize_triangle(bitmap, vertices[indices[i]], vertices[indices[i + 1]], vertices[indices[i + 2]]);
    }
}

fn rasterize_triangle(bitmap: *RenderBitmap, vtx1: *Vertex, vtx2: *Vertex, vtx3: *Vertex) void {
    //Draw an outline of the triangle
    draw_line(bitmap, vtx1.position, vtx2.position);
    draw_line(bitmap, vtx2.position, vtx3.position);
    draw_line(bitmap, vtx1.position, vtx3.position);
}

fn draw_line(bitmap: *RenderBitmap, p1: Vector2, p2: Vector2) void {
    _ = bitmap;
    _ = p1;
    _ = p2;
}