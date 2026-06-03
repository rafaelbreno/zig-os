// x86_64-specific serial driver implementation.
// Initializes the COM1 UART for 115200 baud, 8N1 format.
const port = @import("port.zig");
const std = @import("std");

/// Initialize the serial port (COM1) for output.
/// Sets up the UART for 115200 baud, 8 data bits, no parity, 1 stop bit (8N1), and enables the FIFO.
pub fn init() void {
    // Disable all interrupts on COM1
    // 0x3F9 is the Interrupt Enable Register (IER) for COM1, and writing 0 disables all interrupts.
    port.outb(0x3F9, 0x00);

    // Set DLAB to access divisor latch
    // 0x3FB is the Line Control Register (LCR) for COM1,
    // and setting bit 7 (0x80) enables access to the divisor latch registers at 0x3F8 and 0x3F9.
    port.outb(0x3FB, 0x80);

    // Set the baud divisor
    port.outb(0x3F8, 0x01); // Divisor low byte (115200 baud)
    port.outb(0x3F9, 0x00); // Divisor high byte

    // Clear DLAB to access regular registers, set 8N1
    port.outb(0x3FB, 0x03); // 8 bits, no parity, 1 stop bit

    // Enable FIFO, clear buffers
    port.outb(0x3FA, 0xC7);

    // Set DTR(Data Terminal Ready) and RTS(Request To Send) to signal we're ready to communicate
    port.outb(0x3FC, 0x03);
}

/// Write a byte to the serial port (COM1).
pub fn writeByte(byte: u8) void {
    // Wait for the Transmitter Holding Register (THR) to be empty
    // 0x3FD is the Line Status Register (LSR) for COM1, and bit 5 (0x20) indicates THR is empty.
    while ((port.inb(0x3FD) & 0x20) == 0) {}

    // Write the byte to the Transmitter Holding Register (THR)
    // 0x3F8 is the base port for COM1, and writing to it sends data.
    port.outb(0x3F8, byte);
}

/// Write a null-terminated string to the serial port one byte at a time.
/// Each byte is sent via writeByte, which polls the UART until it's ready.
pub fn writeString(str: []const u8) void {
    // Iterate over each byte in the string.
    // The `|byte|` syntax binds each element to the `byte` variable.
    for (str) |byte| {
        // Send each byte to the UART.
        // writeByte handles polling and transmission.
        writeByte(byte);
    }
}

/// SerialWriter: a simple Writer implementation for std.fmt.
/// This struct satisfies the Writer interface that std.fmt.format() expects.
/// It has a single method: writeAll(), which std.fmt calls to output formatted text.
pub const SerialWriter = struct {
    writer: std.Io.Writer,

    pub fn init() SerialWriter {
        return .{
            .writer = .{
                .vtable = &.{
                    .drain = drain,
                },
                .buffer = &.{},
            },
        };
    }

    fn drain(w: *std.Io.Writer, data: []const []const u8, splat: usize) std.Io.Writer.Error!usize {
        const slice = data[0 .. data.len - 1];
        const pattern = data[slice.len];

        // count total
        var written: usize = pattern.len * splat;
        for (slice) |bytes| {
            written += bytes.len;

            for (bytes) |byte| {
                writeByte(byte);
            }
        }

        for (0..splat) |_| {
            for (pattern) |byte| {
                writeByte(byte);
            }
        }

        w.end = 0;

        return written;
    }
};

/// print: formatted output to the serial port.
/// Mimics std.debug.print, but routes output to COM1 instead of stderr.
/// Usage: print("hello {s}, number: {d}\n", .{ "world", 42 })
pub fn print(comptime fmt: []const u8, args: anytype) !void {
    var writer = SerialWriter.init();

    try (writer.writer).print(fmt, args);
}
