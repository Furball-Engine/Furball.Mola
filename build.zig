const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    b.use_stage1 = true;

    const lib = b.addSharedLibrary("Mola", "src/main.zig", b.version(1, 0, 0));
    lib.linkLibC();
    lib.setTarget(std.zig.CrossTarget.parse(std.zig.CrossTarget.ParseOptions{.arch_os_abi = "x86_64-linux"}) catch {std.os.abort();});
    lib.setBuildMode(mode);
    lib.install();
}
