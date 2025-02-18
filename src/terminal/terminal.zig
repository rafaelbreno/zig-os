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

    const TAB_SIZE = 4;

    pub fn initialize() void {
        buffer.flush(color);
        Keyboard.initialize();
    }

    fn putChar(c: u8, new_color: u8) void {
        switch (c) {
            '\n' => {
                cursor.newLine();
                if (cursor.checkScroll()) {
                    buffer.scroll(color);
                }
            },
            '\t' => {
                const spaces = TAB_SIZE - (cursor.column % TAB_SIZE);
                var i: usize = 0;
                while (i < spaces) : (i += 1) {
                    buffer.writeAt(' ', new_color, cursor.column, cursor.row);
                    cursor.advance();
                }
            },
            '\r' => cursor.column = 0,
            0x08 => {
                cursor.backOne();
                buffer.writeAt(' ', color, cursor.column, cursor.row);
            },
            else => {
                buffer.writeAt(c, new_color, cursor.column, cursor.row);
                cursor.advance();
            },
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
                0x09 => { // tab
                    const spaces = TAB_SIZE - (cursor.column % TAB_SIZE);
                    var i: usize = 0;
                    while (i < spaces) : (i += 1) {
                        putChar(' ', color);
                    }
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
