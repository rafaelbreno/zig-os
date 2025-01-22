// src/drivers/vga/buffer.zig

pub const VGABuffer = struct {
    const Self = @This();

    pub const WIDTH = 80;
    pub const HEIGHT = 45;
    const BUFFER_ADDRESS = 0xB8000;

    buffer: [*]volatile u16,

    var instance = init();

    fn init() Self {
        return Self{
            .buffer = @ptrFromInt(BUFFER_ADDRESS),
        };
    }

    pub fn getInstance() *Self {
        return &instance;
    }

    pub fn writeAt(self: *Self, char: u8, color: u8, x: usize, y: usize) void {
        const index = y * WIDTH + x;
        self.buffer[index] = createEntry(char, color);
    }

    fn createEntry(char: u8, color: u8) u16 {
        const c: u16 = color;
        return char | (c << 8);
    }
};
