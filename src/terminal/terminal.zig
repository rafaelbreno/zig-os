const vga = @import("../drivers/vga/color.zig");
const Color = vga.Color;
const vga_buffer = @import("../drivers/vga/buffer.zig");
const VGABuffer = vga_buffer.VGABuffer;

pub const terminal = struct {
    var row: usize = 0;
    var column: usize = 0;
    var color = vga.vgaEntryColor(Color.LightGrey, Color.Black);
    const buffer: *VGABuffer = VGABuffer.getInstance();

    pub fn initialize() void {
        var y: usize = 0;
        while (y < VGABuffer.HEIGHT) : (y += 1) {
            var x: usize = 0;
            while (x < VGABuffer.WIDTH) : (x += 1) {
                putCharAt(' ', color, x, y);
            }
        }
    }

    fn setColor(new_color: u8) void {
        color = new_color;
    }

    fn putCharAt(c: u8, new_color: u8, x: usize, y: usize) void {
        buffer.writeAt(c, new_color, x, y);
    }

    fn putChar(c: u8) void {
        putCharAt(c, color, column, row);
        column += 1;
        if (column == VGABuffer.WIDTH) {
            column = 0;
            row += 1;
            if (row == VGABuffer.HEIGHT)
                row = 0;
        }
    }

    pub fn write(data: []const u8) void {
        for (data) |c|
            putChar(c);
    }
};
