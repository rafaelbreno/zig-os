pub const VGABuffer = struct {
    const Self = @This();

    pub const HEIGHT = 25;
    pub const WIDTH = 80;
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

    pub fn flush(self: *Self, color: u8) void {
        var y: usize = 0;
        while (y < HEIGHT) : (y += 1) {
            var x: usize = 0;
            while (x < WIDTH) : (x += 1) {
                self.writeAt(' ', color, x, y);
            }
        }
    }

    pub fn writeAt(self: *Self, char: u8, color: u8, x: usize, y: usize) void {
        const index = y * WIDTH + x;
        self.buffer[index] = createEntry(char, color);
    }

    pub fn scroll(self: *Self, color: u8) void {
        var y: usize = 1;
        while (y < HEIGHT) : (y += 1) {
            var x: usize = 0;

            while (x < WIDTH) : (x += 1) {
                const from_index = y * WIDTH + x;
                const to_index = (y - 1) * WIDTH + x;
                self.buffer[to_index] = self.buffer[from_index];
            }
        }

        var x: usize = 0;
        while (x < WIDTH) : (x += 1) {
            self.writeAt(' ', color, x, HEIGHT - 1);
        }
    }

    fn createEntry(char: u8, color: u8) u16 {
        const c: u16 = color;
        return char | (c << 8);
    }
};
