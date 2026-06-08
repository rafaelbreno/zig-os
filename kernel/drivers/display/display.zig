const build_options = @import("build_options");
const bootloader = @import("../../bootloader/bootloader.zig");

const impl = switch (build_options.display) {
    .framebuffer => @import("framebuffer/framebuffer.zig"),
    //else => @compileError("Unsupported display"),
};

pub const DisplayInfo = struct {
    const Self = @This();
    height: u64,
    width: u64,
    bytes_per_pixel: u64,
    pixel_per_row: u64,
    buffer: [*]volatile u32,

    pub fn fillScreen(self: Self, color: u32) void {
        for (0..self.height) |y| {
            for (0..self.width) |x| {
                self.buffer[y * self.pixel_per_row + x] = color;
            }
        }
    }

    pub fn drawPixel(self: Self, x: u64, y: u64, color: u32) void {
        if (x >= self.width or y >= self.height) {
            return;
        }
        self.buffer[y * self.pixel_per_row + x] = color;
    }
};

pub fn init(framebuffer: bootloader.FramebufferInfo) DisplayInfo {
    return impl.init(framebuffer);
}
