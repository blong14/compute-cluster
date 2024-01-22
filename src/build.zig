const std = @import("std");

pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});
    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});
    // Add custom modules so they can be referenced from our cmd directory
    const queue = b.addModule("msgqueue", .{ .source_file = .{ .path = "internal/ipc/msgqueue.zig" } });
    const mmap = b.addModule("mmap", .{ .source_file = .{ .path = "internal/ipc/mmap.zig" } });
    {
        const exe = b.addExecutable(.{
            .name = "zagent",
            .root_source_file = .{ .path = "cmd/agent/main.zig" },
            .target = target,
            .optimize = optimize,
        });
        // This declares intent for the executable to be installed into the
        // standard location when the user invokes the "install" step (the default
        // step when running `zig build`).
        b.installArtifact(exe);
        const run_cmd = b.addRunArtifact(exe);
        // By making the run step depend on the install step, it will be run from the
        // installation directory rather than directly from within the cache directory.
        // This is not necessary, however, if the application depends on other installed
        // files, this ensures they will be present and in the expected location.
        run_cmd.step.dependOn(b.getInstallStep());
        // This allows the user to pass arguments to the application in the build
        // command itself, like this: `zig build run -- arg1 arg2 etc`
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }
        // This creates a build step. It will be visible in the `zig build --help` menu,
        // and can be selected like this: `zig build run`
        // This will evaluate the `run` step rather than the default, which is "install".
        const run_step = b.step("run-zagent", "Run the app");
        run_step.dependOn(&run_cmd.step);
        // Creates a step for unit testing. This only builds the test executable
        // but does not run it.
        const unit_tests = b.addTest(.{
            .root_source_file = .{ .path = "cmd/agent/main.zig" },
            .target = target,
            .optimize = optimize,
        });
        const run_unit_tests = b.addRunArtifact(unit_tests);
        // Similar to creating the run step earlier, this exposes a `test` step to
        // the `zig build --help` menu, providing a way for the user to request
        // running the unit tests.
        const test_step = b.step("test-zagent", "Run unit tests");
        test_step.dependOn(&run_unit_tests.step);
    }
    {
        const exe = b.addExecutable(.{
            .name = "zpool",
            .root_source_file = .{ .path = "cmd/pool/main.zig" },
            .target = target,
            .optimize = optimize,
        });
        exe.addModule("msgqueue", queue);
        exe.addModule("mmap", mmap);
        exe.linkLibC();
        b.installArtifact(exe);
        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }
        const run_step = b.step("run-pool", "Run the app");
        run_step.dependOn(&run_cmd.step);
        const unit_tests = b.addTest(.{
            .root_source_file = .{ .path = "cmd/agent/main.zig" },
            .target = target,
            .optimize = optimize,
        });
        const run_unit_tests = b.addRunArtifact(unit_tests);
        const test_step = b.step("test-pool", "Run unit tests");
        test_step.dependOn(&run_unit_tests.step);
    }
}
