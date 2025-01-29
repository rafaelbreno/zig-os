const std = @import("std");
const Target = std.Target;
const CrossTarget = std.zig.CrossTarget;

fn addTests(
    b: *std.Build,
    test_step: *std.Build.Step,
    dir_path: []const u8,
) !void {
    // Get absolute path
    const abs_path = try std.fs.cwd().realpathAlloc(b.allocator, dir_path);
    defer b.allocator.free(abs_path);

    var dir = try std.fs.openDirAbsolute(abs_path, .{ .iterate = true });
    defer dir.close();

    var walker = try dir.walk(b.allocator);
    defer walker.deinit();

    // Iterate through all files in directory and subdirectories
    while (try walker.next()) |entry| {
        if (entry.kind != .file) continue;

        // Check if file ends with _test.zig
        if (std.mem.endsWith(u8, entry.path, "_test.zig")) {
            const test_path = try std.fs.path.join(b.allocator, &.{ dir_path, entry.path });
            defer b.allocator.free(test_path);

            const tests = b.addTest(.{
                .root_source_file = b.path(test_path),
                .target = b.host,
                .optimize = .Debug,
            });
            const run_tests = b.addRunArtifact(tests);
            test_step.dependOn(&run_tests.step);
        }
    }
}

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {

    // Currently the target is hardcoded to be
    // on x86, but with time this will be compiled for
    // various architectures.
    const targetQuery = CrossTarget{
        .cpu_arch = Target.Cpu.Arch.x86,
        .os_tag = Target.Os.Tag.freestanding,
    };

    const target = b.resolveTargetQuery(targetQuery);

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    // Setting our kernel:
    const kernel = b.addExecutable(.{
        .name = "zig-os",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    kernel.setLinkerScriptPath(b.path("src/linker.ld"));

    // Disable PIE - Position Independent Executable
    // Position Independent Executable (PIE) is disabled because
    //   PIE requires the code to be relocatable at runtime. In a
    //   normal userspace program, this is a security feature that
    //   allows the operating system to load the program at
    //   random addresses.
    // However, in kernel development:
    //   1. You are the operating system - there's no higher-level OS to handle the relocation
    //   2. You need to know exactly where your code and data are in memory
    //   3. You'll be setting up your own virtual memory system
    //
    // When pie = false, the kernel code will be linked to run at
    //   the exact addresses specified in your linker script.
    //
    // This is crucial because during early boot:
    //   1. You don't have virtual memory set up yet
    //   2. You need to know the precise physical addresses of your kernel's code and data
    //   3. Your boot code needs to jump to known addresses
    kernel.pie = false;

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(kernel);

    // This *creates* a RunStep in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    //const run_cmd = b.addRunArtifact(kernel);
    const run_cmd = b.addSystemCommand(&.{
        "qemu-system-x86_64",
        "-kernel",
        "zig-out/bin/zig-os",
        "-serial",
        "null",
    });

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
    const run_step = b.step("run", "Run the OS in QEMU");
    run_step.dependOn(&run_cmd.step);

    const test_step = b.step("test", "Run all tests");

    addTests(b, test_step, "src/") catch |err| {
        std.debug.print("Error adding tests: {}\n", .{err});
        return;
    };
}
