const vga = @import("../drivers/vga/color.zig");
const Color = vga.Color;
const vga_buffer = @import("../drivers/vga/buffer.zig");
const VGABuffer = vga_buffer.VGABuffer;
const Cursor = @import("cursor.zig").Cursor;
const Keyboard = @import("../drivers/keyboard/keyboard.zig").Keyboard;

pub const terminal = struct {
    var color = vga.vgaEntryColor(Color.LightGrey, Color.Black);
    var cursor = Cursor.init(VGABuffer.WIDTH, VGABuffer.HEIGHT);
    const buffer: *VGABuffer = VGABuffer.getInstance();

    // Input buffer configuration
    const INPUT_BUFFER_SIZE = 256;
    var input_buffer: [INPUT_BUFFER_SIZE]u8 = undefined;
    var buffer_pos: usize = 0;

    pub fn initialize() void {
        buffer.flush(color);
        Keyboard.initialize();
    }

    fn putChar(c: u8, new_color: u8) void {
        if (c == '\n') {
            cursor.newLine();
            if (cursor.checkScroll()) {
                buffer.scroll(color);
            }
            return;
        }
        buffer.writeAt(c, new_color, cursor.column, cursor.row);
        cursor.advance();
        if (cursor.checkScroll()) {
            buffer.scroll(color);
        }
    }

    pub fn write(data: []const u8) void {
        for (data) |c|
            putChar(c, color);
    }

    pub fn handleInput() void {
        const scancode = Keyboard.readScancode();
        if (Keyboard.handleScancode(scancode)) |char| {
            switch (char) {
                0x08 => { // backspace
                    cursor.backOne();
                    buffer.writeAt(' ', color, cursor.column, cursor.row);
                },
                0x0A => { // enter
                    cursor.newLine();
                    if (cursor.checkScroll()) {
                        buffer.scroll(color);
                    }
                },
                else => {
                    putChar(char, color);
                },
            }
        }
    }
};
