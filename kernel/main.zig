const limine = @import("limine.zig");
const arch = @import("arch.zig");

export var base_revision: [3]u64 align(8) = .{
    0xf9562b2d5c95a6c8,
    0x6a7b384944536bdc,
    6, // Base Revision 6
};

// Requests
export var hhdm_request: limine.HHDMRequest align(8) linksection(".requests") = .{
    .revision = 0,
    .response = null,
};

export var framebuffer_request: limine.FrameBufferRequest align(8) linksection(".requests") = .{
    .revision = 0,
    .response = null,
};

export var memmap_request: limine.MemMapRequest align(8) linksection(".requests") = .{
    .revision = 0,
    .response = null,
};

// _start is the entry point of the OS
// `noreturn` is used because a infinite loop doesn't return anything.
// callconv(.naked)
//  The callconv specifier changes the calling convention of the function.
//  .naked makes it no have a prologue/epilogue
export fn _start() callconv(.naked) noreturn {
    asm volatile ("cli");
    while (true) {
        asm volatile ("hlt");
    }
}
