// x86_64-specific serial driver implementation.
// Initializes the COM1 UART for 115200 baud, 8N1 format.
const port = @import("port.zig");

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
