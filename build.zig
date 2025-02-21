const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const t = target.result;

    const libusb = b.dependency("libusb", .{
        .target = target,
        .optimize = optimize,
    });

    const lib = b.addStaticLibrary(.{
        .name = "hdlc",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    lib.addCSourceFiles(.{
        .files = &.{
            "src/hdlc/crc-ccitt.c",
            "src/hdlc/diagchar_hdlc.c",
        },
        .flags = &.{},
    });
    lib.addIncludePath(b.path("src"));
    lib.installHeadersDirectory(b.path("src/hdlc"), "", .{
        .include_extensions = &.{".h"},
    });

    const translate_c = b.addTranslateC(.{
        .root_source_file = b.path("src/c.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    translate_c.addIncludePath(b.path("src/hdlc"));
    translate_c.addIncludePath(libusb.path("libusb"));

    const exe = b.addExecutable(.{
        .name = "diag",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    exe.root_module.addImport("c", translate_c.addModule("c"));
    exe.linkLibrary(libusb.artifact("usb"));
    if (t.os.tag == .linux) {
        exe.linkSystemLibrary("libudev");
    }
    exe.linkLibrary(lib);
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe_unit_tests.root_module.addImport("c", translate_c.addModule("c"));
    exe_unit_tests.linkLibrary(libusb.artifact("usb"));
    if (t.os.tag == .linux) {
        exe_unit_tests.linkSystemLibrary("libudev");
    }
    exe_unit_tests.linkLibrary(lib);

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
