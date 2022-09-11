pub const rgba32 = extern struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8
};

pub const argb32 = extern struct {
    a: u8,
    r: u8,
    g: u8,
    b: u8
};

pub const pixel_type = enum(u8) {  
    rgba32, 
    argb32 
};