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
