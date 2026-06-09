const std = @import("std");
const build_options = @import("build_options");
const DisplayInfo = @import("../../drivers/display/display.zig").DisplayInfo;
const psf2 = @import("../../drivers/display/fonts/psf2.zig");
const Font = psf2.Font;

const impl = switch (build_options.console) {
    .framebuffer => @import("framebuffer/console.zig"),
};

pub const Console = struct {
    const Self = @This();

    const foreground_color = 0x00FFFFFF;
    const background_color = 0x00000000;

    display: DisplayInfo,
    font: Font,
    rows: usize,
    columns: usize,
    current_row: usize,
    current_column: usize,

    pub fn putChar(self: *Self, char: u8) void {
        if (char == '\n') {
            if (self.current_row == self.rows - 1) {
                self.scroll();
            } else {
                self.current_row += 1;
            }
            self.current_column = 0;
            return;
        }
        if (char == '\t') {
            self.current_column += 4;
            if (self.current_column >= self.columns) {
                if (self.current_row == self.rows - 1) {
                    self.scroll();
                } else {
                    self.current_row += 1;
                }
                self.current_column = 0;
            }
            return;
        }

        psf2.drawChar(
            self.font,
            self.display,
            char,
            self.current_column * self.font.header.width,
            self.current_row * self.font.header.height,
            foreground_color,
            background_color,
        );
        self.current_column += 1;
        if (self.current_column == self.columns) {
            if (self.current_row == self.rows - 1) {
                self.scroll();
            } else {
                self.current_row += 1;
            }
            self.current_column = 0;
        }
    }

    pub fn putString(self: *Self, str: []const u8) void {
        for (str) |char| {
            self.putChar(char);
        }
    }

    pub fn scroll(self: *Self) void {
        const glyph_row_pixel = self.display.pixel_per_row * self.font.header.height;
        const total_pixel = self.display.pixel_per_row * self.display.height;

        for (0..total_pixel - glyph_row_pixel) |i| {
            self.display.buffer[i] = self.display.buffer[i + glyph_row_pixel];
        }

        for (total_pixel - glyph_row_pixel..total_pixel) |i| {
            self.display.buffer[i] = background_color;
        }
    }

    /// print: formatted output to the serial port.
    /// Mimics std.debug.print, but routes output to COM1 instead of stderr.
    /// Usage: print("hello {s}, number: {d}\n", .{ "world", 42 })
    pub fn print(self: *Console, comptime fmt: []const u8, args: anytype) !void {
        var cw = ConsoleWriter{
            .buf = undefined,
            .writer = undefined,
            .console = self,
        };

        cw.writer = .{
            .vtable = &.{ .drain = ConsoleWriter.drain },
            .buffer = &cw.buf,
        };

        try cw.writer.print(fmt, args);

        // Flush remaining bytes
        for (cw.buf[0..cw.writer.end]) |byte| {
            self.putChar(byte);
        }
    }

    /// println: formatted output to the serial port plus newline.
    pub fn println(self: *Console, comptime fmt: []const u8, args: anytype) !void {
        return self.print(fmt ++ "\n", args);
    }
};

pub fn init(display: DisplayInfo, font: Font) Console {
    return impl.init(display, font);
}

pub const ConsoleWriter = struct {
    // 256 bytes is enough for a typical formatted log line.
    // If a single formatted value exceeds this, drain() will be called mid-format
    // to flush the buffer and free up space.
    buf: [256]u8 = undefined,
    writer: std.Io.Writer,
    console: *Console,

    /// drain: called by std.Io.Writer when the buffer is full or needs flushing.
    /// Receives slices of formatted data and sends each byte to the serial port.
    /// The last element of `data` is repeated `splat` times (for fill/padding).
    fn drain(w: *std.Io.Writer, data: []const []const u8, splat: usize) std.Io.Writer.Error!usize {
        const cw: *ConsoleWriter = @fieldParentPtr("writer", w);
        // All elements except the last are plain slices to write once.
        const slice = data[0 .. data.len - 1];

        // The last element is the "pattern" — repeated `splat` times for padding.
        const pattern = data[slice.len];

        var written: usize = 0;

        // Write each plain slice byte by byte.
        for (slice) |bytes| {
            for (bytes) |byte| {
                cw.console.putChar(byte);
            }
            written += bytes.len;
        }

        // Write the pattern `splat` times (used for alignment padding).
        for (0..splat) |_| {
            for (pattern) |byte| {
                cw.console.putChar(byte);
            }
            written += pattern.len;
        }

        // Reset the Writer's buffer position so it can be reused.
        w.end = 0;

        return written;
    }
};
