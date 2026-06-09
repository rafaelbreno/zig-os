const DisplayInfo = @import("../../../drivers/display/display.zig").DisplayInfo;
const Font = @import("../../../drivers/display/fonts/psf2.zig").Font;
const Console = @import("../console.zig").Console;

pub fn init(display: DisplayInfo, font: Font) Console {
    return Console{
        .display = display,
        .font = font,
        .rows = display.height / font.header.height,
        .columns = display.width / font.header.width,
        .current_column = 0,
        .current_row = 0,
    };
}
