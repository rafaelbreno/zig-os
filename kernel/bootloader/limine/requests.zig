// Limine feature request instances.
// This file is the kernel's "order form" to the bootloader: it declares which
// features are needed and provides the variables Limine writes responses into.
//
// Relationship to protocol.zig:
//   protocol.zig — type definitions (what Limine can provide)
//   requests.zig — instances (what this kernel actually asks for)
//
// When a new phase needs a new Limine feature (RSDP in Phase 4, modules in Phase 10,
// SMP in Phase 13), add the request variable here and the translation to BootInfo
// in init.zig. Nothing outside bootloader/limine/ should import this file.

const protocol = @import("protocol.zig");

// Base revision: tells Limine which protocol version this kernel implements.
// Limine reads this at boot and verifies compatibility.
// If this doesn't match, Limine won't boot the kernel.
//
// Unlike feature requests, base_revision does not belong to the `.requests` section.
// Limine scans the entire kernel binary for the base revision magic values; feature
// requests are found specifically by scanning `.requests`.
//
// Must be `export var`, not `export const`:
// Limine writes back into this variable at boot to signal whether it accepted the
// revision. If the kernel-requested revision is too new for the running Limine version,
// Limine zeros the third field as a rejection signal.
pub export var base_revision: [3]u64 align(8) = .{
    0xf9562b2d5c95a6c8,
    0x6a7b384944536bdc,
    6, // Base Revision 6 — the Limine protocol version we support
};

// Limine requests: structures that ask the bootloader for information.
// The bootloader scans for these in the `.requests` section and fills in
// the `response` pointers with the information we requested.
//
// All request variables share the same constraints:
//
//   export var     — `export` makes the symbol visible to the linker so the ELF
//                    section placement works; `var` (not `const`) is required because
//                    Limine writes the response pointer into the struct at runtime.
//                    A `const` would place the struct in read-only memory, and Limine's
//                    write would fault or be silently ignored.
//
//   align(8)       — The Limine protocol requires 8-byte alignment for request structs
//                    so it can scan memory efficiently without unaligned access faults.
//
//   linksection    — Places the variable in the `.requests` ELF section, which the
//   (".requests")    linker script maps to a dedicated region. Limine scans specifically
//                    this section for feature requests; a request outside it is invisible
//                    to the bootloader.
//
//   .revision = 0  — Requests the baseline (revision 0) response fields. Higher revision
//                    values unlock additional response fields defined in later protocol
//                    versions. We start at 0 and raise as needed.
//
//   .response = null — Limine fills this pointer at boot. The null initial value is the
//                      "not yet answered" sentinel; init.zig null-checks every response
//                      before reading it.

// HHDM Request: Ask Limine for the "Higher Half Direct Map" offset.
// This tells us how to convert physical addresses to virtual addresses
// for the direct-map region of memory.
pub export var hhdm_request: protocol.HHDMRequest align(8) linksection(".requests") = .{
    .revision = 0,
    .response = null,
};

// Framebuffer Request: Ask Limine to provide a graphical framebuffer.
// The response will contain the pixel buffer address, width, height, and pitch.
// We'll use this for console output (Phase 2).
pub export var framebuffer_request: protocol.FrameBufferRequest align(8) linksection(".requests") = .{
    .revision = 0,
    .response = null,
};

// Memory Map Request: Ask Limine for a map of usable and reserved memory regions.
// This tells us where RAM is, where firmware reserves memory, etc.
// We'll use this for allocator setup (Phase 5).
pub export var memmap_request: protocol.MemMapRequest align(8) linksection(".requests") = .{
    .revision = 0,
    .response = null,
};
