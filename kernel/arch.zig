// Architecture abstraction layer for port I/O.
//
// This module provides a clean interface to architecture-specific code.
// By abstracting behind this layer, the rest of the kernel doesn't need to know
// whether it's running on x86_64, RISC-V, or any other architecture.
//
// This design makes porting to new architectures much easier:
// when you port to RISC-V, you just add another case to the switch below
// and implement the same interface in arch/riscv64/port.zig.
// Everything that uses `arch.outb()` will automatically work.

const builtin = @import("builtin");

// Comptime switch: at compile time, pick the right architecture module.
// `builtin.target.cpu.arch` is known at compile time, so the Zig compiler
// evaluates this switch during compilation and discards the unused branches.
// Only the code path for your target architecture ends up in the final binary.
const port_module = switch (builtin.target.cpu.arch) {
    .x86_64 => @import("arch/x86_64/port.zig"),
    else => @compileError("Unsupported architecture"),
};

// Re-export the port I/O functions from the architecture-specific module.
// This way, callers use `arch.outb()` instead of `arch.x86_64.port.outb()`,
// keeping the API clean and hiding implementation details.
pub const outb = port_module.outb;
pub const inb = port_module.inb;
pub const outw = port_module.outw;
pub const inw = port_module.inw;
pub const outl = port_module.outl;
pub const inl = port_module.inl;

// architecture-specific serial driver module.
// Like the port I/O abstraction, this comptime switch picks the right implementation
// based on the target architecture. For x86_64, we get the x86_64-specific UART init.
// When porting to RISC-V, just add another case that imports the RISC-V serial module.
const serial_module = switch (builtin.target.cpu.arch) {
    .x86_64 => @import("arch/x86_64/serial.zig"),
    else => @compileError("Unsupported architecture"),
};

// Re-export the serial module so callers use `arch.serial.init()` instead of
// `arch.x86_64.serial.init()`. This keeps the API clean and architecture-agnostic.
pub const serial = serial_module;
