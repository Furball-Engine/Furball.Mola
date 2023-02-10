const std = @import("std");
const math = std.math;

fn f(int: i32) f32 {
    return @intToFloat(f32, int);
}

fn fu8(int: u8) f32 {
    return @intToFloat(f32, int);
}

fn i(float: f32) i32 {
    return @floatToInt(i32, float);
}

fn tu8(float: f32) u8 {
    return @floatToInt(u8, float);
}

fn tu16(int: u8) u16 {
    return @intCast(u16, int);
}

pub const rgba32 = extern struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,
    pub fn mul(self: rgba32, col: rgba32) rgba32 {
        var r: u16 = self.r * col.r;
        var g: u16 = self.g * col.g;
        var b: u16 = self.b * col.b;
        var a: u16 = self.a * col.a;

        return .{
            .r = @truncate(u8, (r + 255) / 256),
            .g = @truncate(u8, (g + 255) / 256),
            .b = @truncate(u8, (b + 255) / 256),
            .a = @truncate(u8, (a + 255) / 256),
        };
    }
    pub fn alpha_blend(self: rgba32, col: rgba32) rgba32 {
        return .{ 
            .r = alpha_blend_single(self.r, col.r, self.a), 
            .g = alpha_blend_single(self.g, col.g, self.a), 
            .b = alpha_blend_single(self.b, col.b, self.a), 
            .a = 255 
        };
    }
    pub fn to_rgba128(self: rgba32) rgba128 {
        @setFloatMode(std.builtin.FloatMode.Optimized);
        return .{
            .r = fu8(self.r) / 255,
            .g = fu8(self.g) / 255,
            .b = fu8(self.b) / 255,
            .a = fu8(self.a) / 255,
        };
    }
    pub fn eq(self: rgba32, col: rgba32) bool {
        return self.r == col.r and self.g == col.g and self.b == col.b and self.a == col.a;
    }
    pub fn to_argb32(self: rgba32) argb32 {
        return .{ .r = self.r, .g = self.g, .b = self.b, .a = self.a };
    }
};

fn alpha_blend_single(s: u16, d: u16, a: u16) u8 {
    return @truncate(u8, ((s * a) + (d * (255 - a))) >> 8);
}

pub const argb32 = extern struct { a: u8, r: u8, g: u8, b: u8 };

fn lerp(p0: f32, p1: f32, t: f32) f32 {
    return p0 + (p1 - p0) * t;
}

pub const rgba128 = extern struct {
    r: f32,
    g: f32,
    b: f32,
    a: f32,
    pub fn lerp_color(self: rgba128, c1: rgba128, t: f32) rgba128 {
        return .{ .r = lerp(self.r, c1.r, t), .g = lerp(self.g, c1.g, t), .b = lerp(self.b, c1.b, t), .a = lerp(self.a, c1.a, t) };
    }
    pub fn to_rgba32(self: rgba128) rgba32 {
        return .{ .r = @floatToInt(u8, math.clamp(self.r, 0, 1) * 255), .g = @floatToInt(u8, math.clamp(self.g, 0, 1) * 255), .b = @floatToInt(u8, math.clamp(self.b, 0, 1) * 255), .a = @floatToInt(u8, math.clamp(self.a, 0, 1) * 255) };
    }
    pub fn eq(self: rgba128, col: rgba128) bool {
        return self.r == col.r and self.g == col.g and self.b == col.b and self.a == col.a;
    }
};

pub const pixel_type = enum(u8) { rgba32, argb32 };
