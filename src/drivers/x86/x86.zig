pub inline fn inb(port: u16) u8 {
    return asm volatile ("inb %[port], %[result]"
        : [result] "={al}" (-> u8), // Output constraint
        : [port] "N{dx}" (port), // Input constraint
    );
}

pub inline fn outb(port: u16, value: u8) void {
    asm volatile ("outb %[value], %[port]"
        : // No Outputs
        : [value] "{al}" (value), // Input constraints
          [port] "N{dx}" (port),
    );
}
