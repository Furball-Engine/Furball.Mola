const std = @import("std");

pub fn build(b: *std.Build) void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const target = b.standardTargetOptions(.{});
    const mode = b.standardOptimizeOption(.{});

    // zig fmt: off
    const lib = b.addSharedLibrary(.{ 
        .name = "Mola", 
        .root_source_file = .{ 
            .path = "src/main.zig" 
        }, 
        .version = .{ 
            .major = 1, 
            .minor = 0, 
            .patch = 0 
        }, 
        .optimize = mode, 
        .target = target 
    });
    // zig fmt: on
    lib.install();
}
