const vga = @import("../drivers/vga/color.zig");
const Color = vga.Color;

const VGA_WIDTH = 80;
const VGA_HEIGHT = 45;
const VGA_BUFFER_ADDRESS = 0xB8000;

pub const terminal = struct {
    var row: usize = 0;
    var column: usize = 0;

    var color = vga.vgaEntryColor(Color.LightGrey, Color.Black);

    const buffer: [*]volatile u16 = @ptrFromInt(VGA_BUFFER_ADDRESS);

    pub fn initialize() void {
        var y: usize = 0;
        while (y < VGA_HEIGHT) : (y += 1) {
            var x: usize = 0;
            while (x < VGA_WIDTH) : (x += 1) {
                putCharAt(' ', color, x, y);
            }
        }
    }

    fn setColor(new_color: u8) void {
        color = new_color;
    }

    fn putCharAt(c: u8, new_color: u8, x: usize, y: usize) void {
        const index = y * VGA_WIDTH + x;
        buffer[index] = vga.vgaEntry(c, new_color);
    }

    fn putChar(c: u8) void {
        putCharAt(c, color, column, row);
        column += 1;
        if (column == VGA_WIDTH) {
            column = 0;
            row += 1;
            if (row == VGA_HEIGHT)
                row = 0;
        }
    }

    pub fn write(data: []const u8) void {
        for (data) |c|
            putChar(c);
    }
};
