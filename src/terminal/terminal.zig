const vga = @import("../drivers/vga/color.zig");
const Color = vga.Color;
const vga_buffer = @import("../drivers/vga/buffer.zig");
const VGABuffer = vga_buffer.VGABuffer;
const Cursor = @import("cursor.zig").Cursor;
const Keyboard = @import("../drivers/keyboard/keyboard.zig").Keyboard;

pub const terminal = struct {
    var color = vga.vgaEntryColor(Color.LightGrey, Color.Black);
    var cursor = Cursor.init(VGABuffer.HEIGHT, VGABuffer.WIDTH);
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
        buffer.writeAt(c, new_color, cursor.column, cursor.row);
        cursor.advance();
    }

    pub fn write(data: []const u8) void {
        for (data) |c|
            putChar(c, color);
    }

    pub fn handleInput() void {
        const scancode = Keyboard.readScancode();
        if (Keyboard.handleScancode(scancode)) |char| {
            switch (char) {
                0x08 => { // enter
                    if (buffer_pos > 0) {
                        buffer_pos -= 1;
                        if (cursor.column > 0) {
                            cursor.column -= 1;
                        } else if (cursor.row > 0) {
                            cursor.row -= 1;
                            cursor.column = VGABuffer.WIDTH - 1;
                        }
                        buffer.writeAt(' ', color, cursor.column, cursor.row);
                    }
                },
                0x0A => { // backspace
                    processCommand();
                    cursor.newLine();
                    buffer_pos = 0;
                },
                else => {
                    if (buffer_pos < INPUT_BUFFER_SIZE - 1) {
                        input_buffer[buffer_pos] = char;
                        buffer_pos += 1;
                        putChar(char, color);
                    }
                },
            }
        }
    }

    fn processCommand() void {
        // For now, just echo the command
        write("\nYou typed: ");
        write(input_buffer[0..buffer_pos]);
        write("\n");

        // Clear input buffer
        @memset(input_buffer[0..], 0);
    }
};
