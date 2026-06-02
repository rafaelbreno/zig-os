// Kernel entry point and Limine boot protocol setup.
//
// This module sets up the structures that Limine (the bootloader) uses to:
// 1. Verify this is a Limine-compatible kernel (base_revision)
// 2. Request information the kernel needs (memory map, framebuffer, HHDM offset)
// 3. Hand control to _start once setup is complete

const limine = @import("limine.zig");
const arch = @import("arch.zig");

// Base revision: tells Limine which protocol version this kernel implements.
// Limine reads this at boot and verifies compatibility.
// If this doesn't match, Limine won't boot the kernel.
export var base_revision: [3]u64 align(8) = .{
    0xf9562b2d5c95a6c8,
    0x6a7b384944536bdc,
    6, // Base Revision 6 — the Limine protocol version we support
};

// Limine requests: structures that ask the bootloader for information.
// The bootloader scans for these in the `.requests` section and fills in
// the `response` pointers with the information we requested.

// HHDM Request: Ask Limine for the "Higher Half Direct Map" offset.
// This tells us how to convert physical addresses to virtual addresses
// for the direct-map region of memory.
export var hhdm_request: limine.HHDMRequest align(8) linksection(".requests") = .{
    .revision = 0,
    .response = null,
};

// Framebuffer Request: Ask Limine to provide a graphical framebuffer.
// The response will contain the pixel buffer address, width, height, and pitch.
// We'll use this for console output (Phase 2).
export var framebuffer_request: limine.FrameBufferRequest align(8) linksection(".requests") = .{
    .revision = 0,
    .response = null,
};

// Memory Map Request: Ask Limine for a map of usable and reserved memory regions.
// This tells us where RAM is, where firmware reserves memory, etc.
// We'll use this for allocator setup (Phase 5).
export var memmap_request: limine.MemMapRequest align(8) linksection(".requests") = .{
    .revision = 0,
    .response = null,
};

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
/// 1. Test the port I/O toolbox by reading from COM1 (0x3F8)
/// 2. Disable interrupts with `cli`
/// 3. Loop with `hlt` (halt until next interrupt)
export fn _start() noreturn {
    // Test: verify port I/O functions exist and compile to real instructions.
    // This call is kept alive (not optimized away) to ensure our `inb` function
    // makes it into the final binary with actual `in` instructions.
    _ = arch.inb(0x3F8);

    // Disable interrupts. Critical at boot before we've set up the IDT.
    asm volatile ("cli");

    // Halt the CPU until the next interrupt.
    // This is a safe idle state: low power consumption, and we're ready for
    // timer or I/O interrupts once the interrupt system is set up.
    while (true) {
        asm volatile ("hlt");
    }
}
