const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.resolveTargetQuery(std.Target.Query{
        .cpu_arch = .x86_64,
        .os_tag = .freestanding,
        .abi = .none,
    });

    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "zig_os",
        .root_module = b.createModule(.{
            .root_source_file = b.path("kernel/main.zig"),

            .target = target,
            .optimize = optimize,

            .code_model = .kernel,
            .red_zone = false,
        }),
    });

    b.installArtifact(exe);
}
