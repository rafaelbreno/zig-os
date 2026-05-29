const std = @import("std");

// Orchestrates the kernel build pipeline.
// Standard build default is to assume a host OS; this script
// configures the compiler for a bare-metal environment.
pub fn build(b: *std.Build) void {
    // Target bare-metal x86_64 hardware
    // The 'freestanding' tag and 'none' ABI are required, so the
    // compiler doesn't attempt to link libc or assume underlying host OS capabilities.
    const target = b.resolveTargetQuery(std.Target.Query{
        .cpu_arch = .x86_64,
        .os_tag = .freestanding,
        .abi = .none,
    });

    // Allows the developer to pass CLI flags (e.g -Doptimize=ReleaseSafe)
    // to strip debug assertions or optimize for speed/size.
    const optimize = b.standardOptimizeOption(.{});

    // Kernel specific compilation constraints.
    const root_module_opts = std.Build.Module.CreateOptions{
        .root_source_file = b.path("kernel/main.zig"),

        .target = target,
        .optimize = optimize,

        .code_model = .kernel,
        .red_zone = false,
    };

    // We output an ELF binary because our bootloader expects
    // to parse the ELF headers to map the kernel correctly.
    const exe = b.addExecutable(.{
        .name = "kernel.elf",
        .root_module = b.createModule(root_module_opts),
    });

    exe.pie = false;
    exe.use_llvm = true;

    // Wiring the Linker Script to our executable.
    exe.setLinkerScript(b.path("kernel/linker.ld"));

    // Force the output to a `build/` directory, so we have a predictable path
    // to the binary.
    const kernel_artifact = b.addInstallArtifact(exe, std.Build.Step.InstallArtifact.Options{
        .dest_dir = .{ .override = .{ .custom = "../build/" } },
    });

    // Bind the kernel artifact step to the default `zig build` command,
    // ensuring that our Kernel's build rules are executed by default.
    b.getInstallStep().dependOn(&kernel_artifact.step);

    const iso_step = b.step("iso", "Build bootable ISO");

    const iso_script = b.addSystemCommand(&.{
        "bash",
        "scripts/build-iso.sh",
    });

    iso_script.step.dependOn(&kernel_artifact.step);

    iso_step.dependOn(&iso_script.step);
    b.default_step.dependOn(iso_step);

    const run_step = b.step("run", "Run kernel in QEMU");

    const qemu_cmd = b.addSystemCommand(&.{
        "qemu-system-x86_64",
        "-cdrom",
        "build/os.iso",
        "-serial",
        "stdio",
        "-no-reboot",
        "-no-shutdown",
    });

    qemu_cmd.step.dependOn(iso_step);
    run_step.dependOn(&qemu_cmd.step);

    const debug_step = b.step("debug", "Run kernel in QEMU with GDB server");

    const qemu_debug = b.addSystemCommand(&.{
        "qemu-system-x86_64",
        "-cdrom",
        "build/os.iso",
        "-serial",
        "stdio",
        "-no-reboot",
        "-no-shutdown",
        "-s", // open gdbserver on port 1234
        "-S", // pause CPU at startup, wait for GDB
    });
    qemu_debug.step.dependOn(iso_step);

    debug_step.dependOn(&qemu_debug.step);
}
