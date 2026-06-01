// Port I/O primitives for x86_64.
//
// This module provides the foundational toolbox for talking to hardware devices
// via the x86_64 I/O port address space. Unlike memory access (which uses mov),
// port I/O uses dedicated CPU instructions: `in` and `out`.
//
// The x86_64 calling convention places parameters in registers:
// - First parameter (port) → RDI (which we constrain to DX for port I/O)
// - Second parameter (value) → RSI (which we constrain to the appropriate register)
//
// Register sizes map to instruction sizes:
// - AL (1 byte)   for outb/inb
// - AX (2 bytes)  for outw/inw
// - EAX (4 bytes) for outl/inl

/// outb: Write a single byte to an I/O port.
///
/// The `out` instruction sends the byte in AL to the port address in DX.
/// We use inline assembly to emit the x86_64 instruction directly,
/// then constrain the parameters into the correct registers.
pub fn outb(port: u16, value: u8) void {
    asm volatile ("outb %[value], %[port]"
        :
        : [value] "{al}" (value), // value parameter constrained to AL register
          [port] "{dx}" (port), // port parameter constrained to DX register
    );
}

/// inb: Read a single byte from an I/O port.
///
/// The `in` instruction reads from the port in DX into AL.
/// We use an output constraint `"=r"` to tell the compiler
/// "this variable receives a value from the assembly; put it in any register".
pub fn inb(port: u16) u8 {
    var value: u8 = undefined;

    asm volatile ("inb %[port], %[value]"
        : [value] "=r" (value), // output constraint: write result to 'value'
        : [port] "{dx}" (port), // input constraint: port goes to DX
    );

    return value;
}

/// outw: Write a word (2 bytes) to an I/O port.
///
/// Same pattern as outb, but using AX (16-bit) instead of AL (8-bit),
/// and the `outw` instruction instead of `outb`.
pub fn outw(port: u16, value: u16) void {
    asm volatile ("outw %[value], %[port]"
        :
        : [value] "{ax}" (value), // value constrained to AX register (2 bytes)
          [port] "{dx}" (port),
    );
}

/// inw: Read a word (2 bytes) from an I/O port.
///
/// Same pattern as inb, but working with 16-bit values and the `inw` instruction.
pub fn inw(port: u16) u16 {
    var value: u16 = undefined;

    asm volatile ("inw %[port], %[value]"
        : [value] "=r" (value),
        : [port] "{dx}" (port),
    );

    return value;
}

/// outl: Write a dword (4 bytes) to an I/O port.
///
/// Same pattern as outb/outw, but using EAX (32-bit) instead of AL/AX,
/// and the `outl` instruction.
pub fn outl(port: u16, value: u32) void {
    asm volatile ("outl %[value], %[port]"
        :
        : [value] "{eax}" (value), // value constrained to EAX register (4 bytes)
          [port] "{dx}" (port),
    );
}

/// inl: Read a dword (4 bytes) from an I/O port.
///
/// Same pattern as inb/inw, but working with 32-bit values and the `inl` instruction.
pub fn inl(port: u16) u32 {
    var value: u32 = undefined;

    asm volatile ("inl %[port], %[value]"
        : [value] "=r" (value),
        : [port] "{dx}" (port),
    );

    return value;
}
