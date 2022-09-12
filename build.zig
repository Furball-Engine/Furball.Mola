const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    var mode: std.builtin.Mode = b.standardReleaseOptions();
    // mode = std.builtin.Mode.Debug;

    // b.use_stage1 = true;

    const lib = b.addSharedLibrary("Mola", "src/main.zig", b.version(1, 0, 0));
    lib.setBuildMode(mode);
    lib.install();
}
