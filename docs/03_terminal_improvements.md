# Terminal Improvements

If you didn't read the [Second Chapter(Hello World)](./02_hello_world.md), please read it first.

## Summary
1. [Current State](#current-state)

## Current State 

Looking at the `src/terminal/terminal.zig` implementation, it combines several distinct responsibilities:
1. VGA color management
2. Terminal buffer management
3. Character output handling
4. Screen positioning logic

### VGA Color Management

First, let's create a new file at `src/drivers/vga/color.zig`:
```zig
// Hardware text mode color constants
const VgaColor = u8;
pub const Color = enum(VgaColor) {
    Black = 0,
    Blue = 1,
    Green = 2,
    Cyan = 3,
    Red = 4,
    Magenta = 5,
    Brown = 6,
    LightGrey = 7,
    DarkGrey = 8,
    LightBlue = 9,
    LightGreen = 10,
    LightCyan = 11,
    LightRed = 12,
    LightMagenta = 13,
    LightBrown = 14,
    White = 15,
};

// foreground | background color.
pub fn vgaEntryColor(fg: Color, bg: Color) u8 {
    // will build the byte representing the color.
    return @intFromEnum(fg) | (@intFromEnum(bg) << 4);
}

pub fn vgaEntry(uc: u8, color: u8) u16 {
    const c: u16 = color;

    // build the 2 bytes representing the printable caracter w/ EntryColor.
    return uc | (c << 8);
}
```

Main difference here is the use of Enums just for strictly typing.

Your `src/terminal/terminal.zig` should look like this:
```zig
// we can import our driver here
const vga = @import("../drivers/vga/color.zig");
const Color = vga.Color; // setting Color as const.

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
```

Looks cleaner, but, what about the `buffer`? In this case it makes more sense to live in the vga package, so, in the next we'll be implementing that.

### Terminal Buffer Management

First, let's create a new file at `src/drivers/vga/buffer.zig`:
```zig
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
```

Now implementing it back in `src/terminal/terminal.zig` should look like this:
```zig
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
```

This code still has a thing that it doesn't make too much sense having it inside `Terminal` struct, and that's the position logic.

### Cursor positioning logic

First, let's create a new file at `src/terminal/cursor.zig`:
```zig
pub const Cursor = struct {
    row: usize,
    column: usize,
    max_width: usize,
    max_height: usize,

    const Self = @This();

    pub fn init(width: usize, height: usize) Self {
        return Self{
            .row = 0,
            .column = 0,
            .max_width = width,
            .max_height = height,
        };
    }

    pub fn getPosition(self: *const Self) struct { usize, usize } {
        return .{ self.row, self.column };
    }

    pub fn moveTo(self: *Self, r: usize, col: usize) void {
        if (r >= self.max_height or col >= self.max_width) return;
        self.row = r;
        self.column = col;
    }

    pub fn advance(self: *Self) void {
        self.column += 1;
        if (self.column >= self.max_width) {
            self.column = 0;
            self.row += 1;
            if (self.row >= self.max_height) {
                self.row = 0;
            }
        }
    }

    pub fn newLine(self: *Self) void {
        self.column = 0;
        self.row += 1;
        if (self.row >= self.max_height) {
            self.row = 0;
        }
    }

    pub fn reset(self: *Self) void {
        self.column = 0;
        self.row = 0;
    }
};
```

Also added some helper functions that we may use in the future!

Your `src/terminal/terminal.zig` code should look like this:
```zig
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
```
