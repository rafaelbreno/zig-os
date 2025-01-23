const x86 = @import("../x86/x86.zig");

pub const Keyboard = struct {
    // Keyboard I/O ports
    const DATA_PORT: u16 = 0x60;
    const STATUS_PORT: u16 = 0x64;
    const COMMAND_PORT: u16 = 0x64;

    // Special keycodes
    const BACKSPACE: u8 = 0x0E;
    const ENTER: u8 = 0x1C;
    const LEFT_SHIFT: u8 = 0x2A;
    const RIGHT_SHIFT: u8 = 0x36;
    const CAPS_LOCK: u8 = 0x3A;

    // State tracking
    var shift_pressed: bool = false;
    var caps_lock: bool = false;

    // Basic US keyboard layout mapping
    const ascii_table = [_]u8{ 0, 0, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', 0, 0, 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']', 0, 0, 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', '\'', '`', 0, '\\', 'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/', 0, '*', 0, ' ' };

    // Shift key mapping for numbers and symbols
    const shift_table = [_]u8{ 0, 0, '!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '_', '+', 0, 0, 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', '{', '}', 0, 0, 'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', ':', '"', '~', 0, '|', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', '<', '>', '?', 0, '*', 0, ' ' };

    pub fn initialize() void {
        // TODO: Set up keyboard interrupt handler (IRQ 1)
        // This will be implemented when we set up the IDT
    }

    pub fn handleScancode(scancode: u8) ?u8 {
        // Key release codes start at 0x80
        const released = (scancode & 0x80) != 0;
        const code = scancode & 0x7F;

        if (released) {
            switch (code) {
                LEFT_SHIFT, RIGHT_SHIFT => shift_pressed = false,
                else => {},
            }
            return null;
        }

        // Handle key press
        switch (code) {
            LEFT_SHIFT, RIGHT_SHIFT => {
                shift_pressed = true;
                return null;
            },
            CAPS_LOCK => {
                caps_lock = !caps_lock;
                return null;
            },
            BACKSPACE => return 0x08, // ASCII backspace
            ENTER => return 0x0A, // ASCII newline
            else => {
                if (code >= ascii_table.len) return null;

                var char = ascii_table[code];
                if (char == 0) return null;

                // Apply shift and caps lock modifications
                const should_shift = shift_pressed != caps_lock;
                if (should_shift) {
                    if (code < shift_table.len) {
                        char = shift_table[code];
                    }
                }

                return char;
            },
        }
    }

    pub fn readScancode() u8 {
        // Wait for keyboard buffer to be ready
        while ((x86.inb(STATUS_PORT) & 1) == 0) {}
        return x86.inb(DATA_PORT);
    }
};
