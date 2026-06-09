const display = @import("../display.zig");
const bootloader = @import("../../../bootloader/bootloader.zig");

pub fn init(framebuffer: bootloader.FramebufferInfo) display.DisplayInfo {
    return display.DisplayInfo{
        .buffer = @ptrFromInt(framebuffer.address),
        .height = framebuffer.height,
        .width = framebuffer.width,
        .bytes_per_pixel = framebuffer.bpp / 8,
        .pixel_per_row = framebuffer.pitch / (framebuffer.bpp / 8),
    };
}
