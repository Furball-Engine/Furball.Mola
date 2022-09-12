const std = @import("std");
const math = std.math;

fn f(int: i32) f32 {
    return @intToFloat(f32, int);
}

fn i(float: f32) i32 {
    return @floatToInt(i32, float);
}

fn tu8(float: f32) u8 {
    return @floatToInt(u8, float);
}

pub const rgba32 = extern struct { 
    r: u8, 
    g: u8, 
    b: u8, 
    a: u8,
    pub fn mul(self: rgba32, col: rgba32) rgba32 {
        return .{
            .r = tu8(f(self.r) * (f(col.r) / 255)),
            .g = tu8(f(self.g) * (f(col.g) / 255)),
            .b = tu8(f(self.b) * (f(col.b) / 255)),
            .a = tu8(f(self.a) * (f(col.a) / 255)),
        };
    }
};

pub const argb32 = extern struct { a: u8, r: u8, g: u8, b: u8 };

fn lerp(p0: f32, p1: f32, t: f32) f32 {
    return p0 + (p1 - p0) * t;
}

pub const rgba128 = extern struct {
    r: f32,
    g: f32,
    b: f32,
    a: f32,
    pub fn lerp_color(self: *rgba128, c1: rgba128, t: f32) rgba128 {
        return .{ .r = lerp(self.r, c1.r, t), .g = lerp(self.g, c1.g, t), .b = lerp(self.b, c1.b, t), .a = lerp(self.a, c1.a, t) };
    }
    pub fn to_rgba32(self: *rgba128) rgba32 {
        return .{ .r = @floatToInt(u8, math.clamp(self.r, 0, 1) * 255), .g = @floatToInt(u8, math.clamp(self.g, 0, 1) * 255), .b = @floatToInt(u8, math.clamp(self.b, 0, 1) * 255), .a = @floatToInt(u8, math.clamp(self.a, 0, 1) * 255) };
    }
};

pub const pixel_type = enum(u8) { rgba32, argb32 };
