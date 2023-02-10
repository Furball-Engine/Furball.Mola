const std = @import("std");

pub fn build(b: *std.Build) void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const target = b.standardTargetOptions(.{});
    const mode = b.standardOptimizeOption(.{});

    const lib = b.addSharedLibrary("Mola", "src/main.zig", b.version(1, 0, 0));
    lib.setBuildMode(mode);
    lib.setTarget(target);
    lib.install();
}
