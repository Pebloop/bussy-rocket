const std = @import("std");
const Sdk = @import("sdl");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});
    //
    // Create a new instance of the SDL2 Sdk
    const sdk = Sdk.init(b, null);

    const exe = b.addExecutable(.{
        .name = "example",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    sdk.link(exe, .dynamic);

    exe.addModule("sdl2", sdk.getWrapperModule());
    exe.linkSystemLibrary("sdl2_image");
    exe.linkSystemLibrary("chipmunk");
    exe.linkSystemLibrary("sdl2_ttf");
    exe.linkSystemLibrary("sdl2_mixer");

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
