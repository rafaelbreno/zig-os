// Orchestrates the kernel build pipeline.
// Standard build default is to assume a host OS; this script
// configures the compiler for a bare-metal environment.
//
// Step dependency chain (what zig build actually executes):
//   zig build         → default_step → iso_step → iso_script → kernel_artifact → exe
//   zig build run     → run_step     → iso_step → (same as above) → qemu
//   zig build debug   → debug_step   → iso_step → (same as above) → qemu -s -S

const std = @import("std");
const Feature = std.Target.x86.Feature;

pub fn build(b: *std.Build) void {
    var disabled_features = std.Target.Cpu.Feature.Set.empty;
    var enabled_features = std.Target.Cpu.Feature.Set.empty;

    // The kernel hasn't enabled SSE in CR0/CR4, so any SSE instruction the
    // compiler emits (e.g. for memcpy inside std.Io.Writer) would fault.
    // Disable SIMD codegen entirely for now.
    disabled_features.addFeature(@intFromEnum(Feature.mmx));
    disabled_features.addFeature(@intFromEnum(Feature.sse));
    disabled_features.addFeature(@intFromEnum(Feature.sse2));
    disabled_features.addFeature(@intFromEnum(Feature.avx));
    disabled_features.addFeature(@intFromEnum(Feature.avx2));

    // Route floating-point through software so the compiler never needs SSE for floats.
    enabled_features.addFeature(@intFromEnum(Feature.soft_float));

    // Target bare-metal x86_64 hardware.
    // The 'freestanding' tag and 'none' ABI are required, so the
    // compiler doesn't attempt to link libc or assume underlying host OS capabilities.
    const target = b.resolveTargetQuery(std.Target.Query{
        .cpu_arch = .x86_64,
        .os_tag = .freestanding,
        .abi = .none,
        .cpu_features_add = enabled_features,
        .cpu_features_sub = disabled_features,
    });

    // Allows the developer to pass CLI flags (e.g -Doptimize=ReleaseSafe)
    // to strip debug assertions or optimize for speed/size.
    const optimize = b.standardOptimizeOption(.{});

    // Bootloader selection. Defaults to Limine.
    // To target a different bootloader: zig build -Dbootloader=grub
    //
    // The enum is the authoritative list of supported bootloaders.
    // Adding a new bootloader means: add a variant here, add a case in
    // bootloader/bootloader.zig's comptime switch, and create bootloader/<name>/init.zig.
    // The compiler will reject any mismatch between these three sites.
    const Bootloader = enum { limine };
    const bootloader_choice = b.option(
        Bootloader,
        "bootloader",
        "Bootloader to target (default: limine)",
    ) orelse .limine;

    const Display = enum { framebuffer };
    const display_choice = b.option(
        Display,
        "display",
        "Display to target (default: framebuffer)",
    ) orelse .framebuffer;

    // Build options: a Zig-generated module that embeds comptime constants into the kernel.
    // Three steps:
    //   1. b.addOptions()          — creates the Options build step (generates a .zig file)
    //   2. build_options.addOption — registers a value to be written into that file
    //   3. build_options.createModule() — turns the generated file into an importable module
    // The kernel imports it as `@import("build_options")`, where it reads `bootloader`
    // as a comptime constant to drive the bootloader dispatch switch.
    const build_options = b.addOptions();
    build_options.addOption(
        Bootloader,
        "bootloader",
        bootloader_choice,
    );

    build_options.addOption(
        Display,
        "display",
        display_choice,
    );

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

    // Wire the generated build_options module into the kernel's root module.
    // This makes `@import("build_options")` resolve inside any kernel source file.
    // Without this, the comptime bootloader switch in bootloader.zig would fail to compile.
    exe.root_module.addImport("build_options", build_options.createModule());

    // PIE (Position Independent Executable) must be disabled for a kernel.
    // PIE requires the linker to emit relocations so the binary can be loaded at any
    // address, which conflicts with code_model = .kernel: the kernel code model assumes
    // fixed high-half addresses and uses 32-bit-sign-extended addressing throughout.
    exe.pie = false;

    // Zig 0.16.0 self-hosted backend bug (ziglang/zig#24717): the self-hosted x86_64
    // backend miscompiles certain kernel patterns. Force LLVM as the codegen backend
    // until the self-hosted backend is reliable for freestanding targets.
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

    // ISO packaging depends on the kernel ELF being present in build/.
    // build-iso.sh copies the ELF into the ISO staging tree before calling xorriso.
    iso_script.step.dependOn(&kernel_artifact.step);

    iso_step.dependOn(&iso_script.step);

    // Make the ISO the default build output.
    // `zig build` with no step name produces a bootable ISO, not just the ELF.
    b.default_step.dependOn(iso_step);

    const run_step = b.step("run", "Run kernel in QEMU");

    const qemu_cmd = b.addSystemCommand(&.{
        "qemu-system-x86_64",
        "-cdrom",
        "build/os.iso",
        "-serial",
        "stdio", // forward COM1 output to the host terminal
        "-no-reboot", // keep QEMU alive on triple fault (makes crashes visible)
        "-no-shutdown", // keep QEMU alive on guest shutdown
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
