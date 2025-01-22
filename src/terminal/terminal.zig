const vga = @import("../drivers/vga/color.zig");
const Color = vga.Color;
const vga_buffer = @import("../drivers/vga/buffer.zig");
const VGABuffer = vga_buffer.VGABuffer;
const Cursor = @import("cursor.zig").Cursor;

pub const terminal = struct {
    var color = vga.vgaEntryColor(Color.LightGrey, Color.Black);
    var cursor = Cursor.init(VGABuffer.HEIGHT, VGABuffer.WIDTH);
    const buffer: *VGABuffer = VGABuffer.getInstance();

    pub fn initialize() void {
        buffer.flush(color);
    }

    fn putChar(c: u8, new_color: u8) void {
        buffer.writeAt(c, new_color, cursor.column, cursor.row);
        cursor.advance();
    }

    pub fn write(data: []const u8) void {
        for (data) |c|
            putChar(c, color);
    }
};
