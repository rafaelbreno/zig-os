// Limine boot protocol type definitions.
// These structs mirror Limine's C headers exactly: field order, field sizes,
// and struct layout must match what the bootloader expects to write into memory.
//
// None of these types should be visible outside kernel/bootloader/limine/.
// init.zig translates them into the kernel's own BootInfo types before
// returning to _start. Everything above that layer is bootloader-agnostic.
//
// Reference: https://github.com/limine-bootloader/limine/blob/trunk/PROTOCOL.md

// ----------------------------------------------------
// Limine Common Magic
// ----------------------------------------------------

// The first two u64s in every request's `id` field.
// Limine scans the kernel binary looking for this magic sequence to locate requests.
// Having two 64-bit values makes accidental collisions with normal data astronomically unlikely.
const limine_common_magic = [2]u64{ 0xc7b1dd30df4c8b88, 0x0a82e883a194f07b };

// ----------------------------------------------------
// HHDM (Higher Half Direct Map) Feature
// ----------------------------------------------------

// All Limine request structs follow the same pattern:
//
//   id        — [common_magic[0], common_magic[1], feature_magic_0, feature_magic_1]
//               The last two u64s are unique to each feature and tell Limine which
//               response to fill in.
//
//   revision  — which version of the request/response the kernel understands.
//               Set to 0 to get the baseline fields; higher revisions add more fields.
//
//   response  — nullable pointer Limine fills at boot with a pointer to its response.
//               Always null-check before use: Limine leaves it null if the feature
//               is unavailable or the request was not understood.
//
// `extern struct` is mandatory: Limine is a C bootloader and writes into these structs
// by raw address. extern guarantees C-compatible layout (no Zig reordering or padding),
// which is why we used `extern struct` and not `packed struct` or a plain Zig struct.

pub const HHDMRequest = extern struct {
    id: [4]u64 = [4]u64{ limine_common_magic[0], limine_common_magic[1], 0x48dcf1cb8ad2b852, 0x63984e959a98244b },
    revision: u64,
    response: ?*HHDMResponse,
};

pub const HHDMResponse = extern struct {
    revision: u64,
    // Virtual address of the start of the higher-half direct map.
    // physical_address + offset = virtual address of that physical address in HHDM.
    // Used by the physical frame allocator to read/write physical memory safely.
    offset: u64,
};

// ----------------------------------------------------
// FrameBuffer Feature
// ----------------------------------------------------

pub const FrameBufferRequest = extern struct {
    id: [4]u64 = [4]u64{ limine_common_magic[0], limine_common_magic[1], 0x9d5827dcd881dd75, 0xa3148604f6fab11b },
    revision: u64,
    response: ?*FrameBufferResponse,
};

pub const FrameBufferResponse = extern struct {
    revision: u64,
    framebuffer_count: u64,
    // Multi-pointer: `[*]*FrameBuffer` is a pointer to an array of pointers.
    // Each entry is independently allocated by Limine; the count is framebuffer_count.
    // Most systems expose exactly one framebuffer; we always use index [0].
    framebuffers: ?[*]*FrameBuffer,
};

pub const FrameBuffer = extern struct {
    // Virtual address of pixel (0, 0) — the top-left corner of the display.
    // Pixel (x, y) is at: address + y * pitch + x * (bpp / 8).
    address: *void,
    width: u64,
    height: u64,
    // Bytes per row. Not always width * (bpp / 8): the firmware may pad each row
    // to an alignment boundary. Always use pitch for row stride, never width * bpp/8.
    pitch: u64,
    bpp: u16, // bits per pixel — common value is 32 (one byte per channel + padding)
    // Pixel encoding format. Value 1 = direct RGB color (overwhelmingly common on x86_64).
    memory_model: u8,
    // Color channel layout within a pixel word.
    // shift = position of the channel's LSB within the pixel.
    // size  = number of bits the channel occupies.
    // Example: red_shift=16, red_size=8 → red occupies bits [16:23] of a 32-bit pixel.
    // Use these when the pixel format is not a known constant (e.g. when memory_model != 1).
    red_mask_size: u8,
    red_mask_shift: u8,
    green_mask_size: u8,
    green_mask_shift: u8,
    blue_mask_size: u8,
    blue_mask_shift: u8,
    unused: [7]u8,
    // Raw EDID blob from the display hardware describing monitor capabilities.
    // We don't use this until a display manager needs it (Phase 14+).
    edid_size: u64,
    edid: *void,

    // Response Revision 1+: available video modes that can be switched to.
    // Only valid when the response revision field is >= 1.
    mode_count: u64,
    video_mode: ?[*]*VideoMode,
};

// Describes an alternate video mode the framebuffer hardware supports.
// Used if you want to switch resolution after boot — not needed in early phases.
pub const VideoMode = extern struct {
    pitch: u64,
    width: u64,
    height: u64,
    bpp: u16, // bits per pixel
    memory_model: u8,
    red_mask_size: u8,
    red_mask_shift: u8,
    green_mask_size: u8,
    green_mask_shift: u8,
    blue_mask_size: u8,
    blue_mask_shift: u8,
};

// ----------------------------------------------------
// Memory Map Feature
// ----------------------------------------------------

// Non-exhaustive enum (`_,`): Limine may add new region types in future protocol versions.
// The trailing `_` forces any switch on this enum to have an `else` branch,
// making kernel code forward-compatible with unknown future types by default.
pub const MemmapEntryType = enum(u64) {
    usable = 0, // general-purpose RAM — safe to hand to the frame allocator
    reserved = 1, // firmware/hardware reserved — never touch
    acpi_reclaimable = 2, // ACPI tables — safe to free after parsing ACPI (Phase 4)
    acpi_nvs = 3, // ACPI Non-Volatile Storage — must never be reclaimed
    bad_memory = 4, // hardware-reported defective RAM — never use
    bootloader_reclaimable = 5, // Limine's own structures — safe to reclaim after frame allocator is up (Phase 5)
    executable_and_modules = 6, // kernel ELF and loaded modules — treat as permanently used
    framebuffer = 7, // memory backing the linear framebuffer
    reserved_mapped = 8, // reserved with an active virtual mapping
    _, // catch-all for future Limine-defined types
};

pub const MemmapEntry = extern struct {
    base: u64, // physical address of the region's first byte
    length: u64, // size in bytes
    type: MemmapEntryType,
};

pub const MemMapRequest = extern struct {
    id: [4]u64 = [4]u64{ limine_common_magic[0], limine_common_magic[1], 0x67cf3d9d378a806f, 0xe304acdfc50c3c62 },
    revision: u64,
    response: ?*MemMapResponse,
};

pub const MemMapResponse = extern struct {
    revision: u64,
    entry_count: u64,
    // Multi-pointer: pointer to an array of entry_count independently-allocated pointers.
    // Limine guarantees the entries are sorted by base address in ascending order.
    entries: ?[*]*MemmapEntry,
};
