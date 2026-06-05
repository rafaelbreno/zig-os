// kernel/bootloader/limine/init.zig
//
// Limine-specific implementation of the bootloader init interface.
// This is the only file in the kernel that knows what a Limine response looks like.
// It reads from the Limine request globals, translates each response into the
// bootloader-agnostic BootInfo type, and returns it to _start.
//
// If you swap Limine for another bootloader, this file (and requests.zig /
// protocol.zig) is all that changes. Nothing above bootloader.zig sees Limine types.

const requests = @import("requests.zig");
const bootloader = @import("../bootloader.zig");

/// Reads all Limine responses and translates them into a bootloader-agnostic BootInfo.
/// Called once from _start, before any kernel subsystem is initialized.
/// Responses Limine didn't fill (e.g. no framebuffer in headless mode) stay at their
/// zero/null defaults rather than being left undefined.
pub fn init() bootloader.BootInfo {
    var info = bootloader.BootInfo{
        .hhdm_offset = 0,
        .framebuffer = null,
        .memory_regions = undefined,
        .memory_region_count = 0,
    };

    // HHDM (Higher Half Direct Map) offset.
    // Limine maps all of physical memory into the higher half of the virtual address
    // space. hhdm_offset is the base of that mapping: physical address P is reachable
    // at virtual address (P + hhdm_offset). The physical frame allocator (Phase 5)
    // uses this to read and write physical frames without needing identity mappings.
    if (requests.hhdm_request.response) |r| {
        info.hhdm_offset = r.offset;
    }

    // Framebuffer.
    // Limine may expose multiple framebuffers; we take only the first.
    // @intFromPtr converts the `*void` address Limine gives us into a plain u64
    // so FramebufferInfo stays free of any Limine-specific types.
    if (requests.framebuffer_request.response) |r| {
        if (r.framebuffer_count > 0) {
            if (r.framebuffers) |fbs| {
                const fb = fbs[0];
                info.framebuffer = .{
                    .address = @intFromPtr(fb.address),
                    .width = fb.width,
                    .height = fb.height,
                    .pitch = fb.pitch,
                    .bpp = fb.bpp,
                };
            }
        }
    }

    // Memory map.
    // Limine provides a flat list of physical memory regions, each tagged with a type
    // (usable, reserved, firmware-owned, etc.). We translate each Limine-specific tag
    // into our generic MemoryRegionKind and copy the entries into the fixed-size array.
    // Phase 5's physical frame allocator will walk this to find safe frames to hand out.
    if (requests.memmap_request.response) |r| {
        if (r.entries) |entries| {
            // Cap at max_memory_regions to prevent overflowing the fixed-size array.
            // Real Limine memory maps rarely exceed ~30 entries, so 256 is a safe ceiling.
            const count = @min(r.entry_count, bootloader.max_memory_regions);
            for (0..count) |i| {
                const e = entries[i];
                info.memory_regions[i] = .{
                    .base = e.base,
                    .length = e.length,
                    // Limine's MemmapEntryType is a non-exhaustive enum (declared with `_,`),
                    // meaning future Limine versions may add new tags we don't know about.
                    // Every recognized type maps to its generic counterpart.
                    // Anything unrecognized — reserved_mapped, future additions — falls
                    // through to .reserved, which the allocator will treat as off-limits.
                    .kind = switch (e.type) {
                        .usable => .usable,
                        .acpi_reclaimable => .acpi_reclaimable,
                        .acpi_nvs => .acpi_nvs,
                        .bad_memory => .bad_memory,
                        .bootloader_reclaimable => .bootloader_reclaimable,
                        .executable_and_modules => .executable_and_modules,
                        .framebuffer => .framebuffer,
                        // reserved, reserved_mapped, and any future Limine types
                        // all map to the generic .reserved
                        else => .reserved,
                    },
                };
            }
            info.memory_region_count = count;
        }
    }

    return info;
}
