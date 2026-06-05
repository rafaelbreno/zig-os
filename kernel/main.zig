// Kernel entry point.
// _start receives control from the bootloader after it has loaded the kernel ELF,
// set up the higher-half mapping, and filled in every requested response structure.
// From here, we initialize subsystems in dependency order and enter the idle loop.

// bootloader.zig is the abstraction gate: _start sees only BootInfo, never Limine types.
// The concrete bootloader implementation is selected at compile time via -Dbootloader=.
const bootloader = @import("bootloader/bootloader.zig");

// arch.zig is the architecture gate: _start sees only arch.serial, never port.zig directly.
// The concrete architecture implementation is selected at compile time via the target triple.
const arch = @import("arch/arch.zig");

/// _start: The kernel's entry point.
///
/// The bootloader jumps here once it has completed its setup.
/// From here, we initialize the kernel's core systems and hand off to the main kernel loop.
///
/// Notes on the function signature:
/// - `export` makes this symbol visible to the linker (the bootloader needs to find it)
/// - `noreturn` tells Zig this function never returns (it loops forever or panics)
/// - Removed `callconv(.naked)`: we now call regular Zig functions from here,
///   so we need the compiler-generated prologue/epilogue for proper function calling.
///
/// Currently, we:
/// 1. Initialize serial output (COM1)
/// 2. Translate bootloader responses into BootInfo
/// 3. Disable interrupts and enter the halt loop
export fn _start() noreturn {
    // Serial must come first: it's our only output channel at this point.
    // If anything below panics or misbehaves, the serial log is all we have to debug it.
    arch.serial.init();
    arch.serial.print("Hello from {s}, here's a number {d}\n", .{ "kernel", 42 }) catch {};

    // Translate all bootloader responses into kernel-owned, bootloader-agnostic types.
    // After this call, nothing in the kernel needs to touch a Limine struct directly.
    // boot_info holds the HHDM offset, framebuffer geometry, and physical memory map —
    // the three things every phase from 2 onward depends on.
    const boot_info = bootloader.init();
    _ = boot_info; // Phase 2.2: framebuffer address; Phase 5: memory map for frame allocator.

    // Disable interrupts. Critical at boot before we've set up the IDT.
    asm volatile ("cli");

    // Halt the CPU until the next interrupt.
    // This is a safe idle state: low power consumption, and we're ready for
    // timer or I/O interrupts once the interrupt system is set up.
    while (true) {
        asm volatile ("hlt");
    }
}
