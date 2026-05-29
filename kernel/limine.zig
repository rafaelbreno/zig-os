// ----------------------------------------------------
// Limine Common Magic
// ----------------------------------------------------

const limine_common_magic = [2]u64{ 0xc7b1dd30df4c8b88, 0x0a82e883a194f07b };

// ----------------------------------------------------
// HHDM (Higher Half Direct Map) Feature
// ----------------------------------------------------

pub const HHDMRequest = extern struct {
    id: [4]u64 = [4]u64{ limine_common_magic[0], limine_common_magic[1], 0x48dcf1cb8ad2b852, 0x63984e959a98244b },
    revision: u64,
    response: ?*HHDMResponse,
};

pub const HHDMResponse = extern struct {
    revision: u64,
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
    framebuffers: ?[*]*FrameBuffer,
};

pub const FrameBuffer = extern struct {
    address: *void,
    width: u64,
    height: u64,
    pitch: u64,
    bpp: u16, // bits per pixel
    memory_model: u8,
    red_mask_size: u8,
    red_mask_shift: u8,
    green_mask_size: u8,
    green_mask_shift: u8,
    blue_mask_size: u8,
    blue_mask_shift: u8,
    unused: [7]u8,
    edid_size: u64,
    edid: *void,

    // Response Revision
    mode_count: u64,
    video_mode: ?[*]*VideoMode,
};

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

pub const MemmapEntryType = enum(u64) {
    usable = 0,
    reserved = 1,
    acpi_reclaimable = 2,
    acpi_nvs = 3,
    bad_memory = 4,
    bootloader_reclaimable = 5,
    executable_and_modules = 6,
    framebuffer = 7,
    reserved_mapped = 8,
    _,
};

pub const MemmapEntry = extern struct {
    base: u64,
    length: u64,
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
    entries: ?[*]*MemmapEntry,
};
