const build_options = @import("build_options");
const DisplayInfo = @import("../../drivers/display/display.zig").DisplayInfo;
const psf2 = @import("../../drivers/display/fonts/psf2.zig");
const Font = psf2.Font;

const impl = switch (build_options.console) {
    .framebuffer => @import("framebuffer/console.zig"),
};

pub const Console = struct {
    const Self = @This();

    const foreground_color = 0x00FFFFFF;
    const background_color = 0x00000000;

    display: DisplayInfo,
    font: Font,
    rows: usize,
    columns: usize,
    current_row: usize,
    current_column: usize,

    pub fn putChar(self: *Self, char: u8) void {
        if (char == '\n') {
            self.current_row += 1;
            self.current_column = 0;
            return;
        }
        if (char == '\t') {
            self.current_column += 4;
            if (self.current_column >= self.columns) {
                self.current_row += 1;
                self.current_column = 0;
            }
            return;
        }

        psf2.drawChar(
            self.font,
            self.display,
            char,
            self.current_column * self.font.header.width,
            self.current_row * self.font.header.height,
            foreground_color,
            background_color,
        );
        self.current_column += 1;
        if (self.current_column == self.columns) {
            self.current_row += 1;
            self.current_column = 0;
        }
    }

    pub fn putString(self: *Self, str: []const u8) void {
        for (str) |char| {
            self.putChar(char);
        }
    }
};

pub fn init(display: DisplayInfo, font: Font) Console {
    return impl.init(display, font);
}
