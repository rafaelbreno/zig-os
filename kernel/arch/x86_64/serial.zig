// x86_64-specific serial driver implementation.
// Initializes the COM1 UART for 115200 baud, 8N1 format.
const port = @import("port.zig");
const std = @import("std");

/// Initialize the serial port (COM1) for output.
/// Sets up the UART for 115200 baud, 8 data bits, no parity, 1 stop bit (8N1), and enables the FIFO.
pub fn init() void {
    // Disable all interrupts on COM1.
    // 0x3F9 is the Interrupt Enable Register (IER) for COM1, and writing 0 disables all interrupts.
    port.outb(0x3F9, 0x00);

    // Set DLAB to access divisor latch.
    // 0x3FB is the Line Control Register (LCR) for COM1,
    // and setting bit 7 (0x80) enables access to the divisor latch registers at 0x3F8 and 0x3F9.
    port.outb(0x3FB, 0x80);

    // Set the baud divisor.
    port.outb(0x3F8, 0x01); // Divisor low byte (115200 baud)
    port.outb(0x3F9, 0x00); // Divisor high byte

    // Clear DLAB to access regular registers, set 8N1.
    port.outb(0x3FB, 0x03); // 8 bits, no parity, 1 stop bit

    // Enable FIFO, clear buffers.
    port.outb(0x3FA, 0xC7);

    // Set DTR (Data Terminal Ready) and RTS (Request To Send) to signal we're ready to communicate.
    port.outb(0x3FC, 0x03);
}

/// Write a byte to the serial port (COM1).
pub fn writeByte(byte: u8) void {
    var timeout: u32 = 100_000;

    // Poll the Line Status Register (LSR) until the Transmitter Holding Register (THR) is empty.
    // 0x3FD is the LSR for COM1, and bit 5 (0x20) indicates the THR is empty and ready to accept a byte.
    // A timeout prevents an infinite loop if the UART becomes unresponsive.
    while ((port.inb(0x3FD) & 0x20) == 0 and timeout > 0) {
        timeout -= 1;
    }

    // Write the byte to the Transmitter Holding Register (THR).
    // 0x3F8 is the base port for COM1; writing here transmits the byte.
    port.outb(0x3F8, byte);
}

/// Write a string to the serial port one byte at a time.
/// Each byte is sent via writeByte, which polls the UART until it's ready.
pub fn writeString(str: []const u8) void {
    for (str) |byte| {
        writeByte(byte);
    }
}

/// SerialWriter: bridges std.Io.Writer and the serial port.
///
/// The root issue with an empty buffer (buffer: &.{}):
/// When std.Io.Writer.print() formats values like {d}, it needs working space
/// in the buffer. With zero capacity, it calls rebase() → drain() in a loop
/// forever, never getting space. The fix is a real 256-byte buffer:
/// - The formatter writes into the buffer freely
/// - When the buffer fills up, drain() flushes it to the serial port
/// - After print() returns, any remaining bytes in the buffer are flushed manually
pub const SerialWriter = struct {
    // 256 bytes is enough for a typical formatted log line.
    // If a single formatted value exceeds this, drain() will be called mid-format
    // to flush the buffer and free up space.
    buf: [256]u8 = undefined,
    writer: std.Io.Writer,

    /// drain: called by std.Io.Writer when the buffer is full or needs flushing.
    /// Receives slices of formatted data and sends each byte to the serial port.
    /// The last element of `data` is repeated `splat` times (for fill/padding).
    fn drain(w: *std.Io.Writer, data: []const []const u8, splat: usize) std.Io.Writer.Error!usize {
        // All elements except the last are plain slices to write once.
        const slice = data[0 .. data.len - 1];

        // The last element is the "pattern" — repeated `splat` times for padding.
        const pattern = data[slice.len];

        var written: usize = 0;

        // Write each plain slice byte by byte.
        for (slice) |bytes| {
            for (bytes) |byte| {
                writeByte(byte);
            }
            written += bytes.len;
        }

        // Write the pattern `splat` times (used for alignment padding).
        for (0..splat) |_| {
            for (pattern) |byte| {
                writeByte(byte);
            }
            written += pattern.len;
        }

        // Reset the Writer's buffer position so it can be reused.
        w.end = 0;

        return written;
    }
};

/// print: formatted output to the serial port.
/// Mimics std.debug.print, but routes output to COM1 instead of stderr.
/// Usage: print("hello {s}, number: {d}\n", .{ "world", 42 })
pub fn print(comptime fmt: []const u8, args: anytype) !void {
    var sw = SerialWriter{
        .buf = undefined,
        .writer = undefined,
    };

    sw.writer = .{
        .vtable = &.{ .drain = SerialWriter.drain },
        .buffer = &sw.buf,
    };

    try sw.writer.print(fmt, args);

    // Flush remaining bytes
    for (sw.buf[0..sw.writer.end]) |byte| {
        writeByte(byte);
    }
}

/// println: formatted output to the serial port plus newline.
pub fn println(comptime fmt: []const u8, args: anytype) !void {
    return print(fmt ++ "\n", args);
}
