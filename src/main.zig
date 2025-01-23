const std = @import("std");
const builtin = @import("builtin");
const term = @import("terminal/terminal.zig").terminal;

const MultiBoot = extern struct {
    magic: i32,
    flags: i32,
    checksum: i32,
};

// 32 bits / 4 bytes integers
const ALIGN = 1 << 0; // 0000 0000 0000 0000 0000 0000 0000 0001
const MEMINFO = 1 << 1; // 0000 0000 0000 0000 0000 0000 0000 0010
const FLAGS = ALIGN | MEMINFO; // 0000 0000 0000 0000 0000 0000 0000 0000 0011
const MAGIC = 0x1BADB002; // 0001 1011 1010 1101 1011 0000 0000 0010

// Define our stack size
const STACK_SIZE = 16 * 1024; // 16 KB

export var stack_bytes: [STACK_SIZE]u8 align(16) linksection(".bss") = undefined;

export var multiboot align(4) linksection(".multiboot") = MultiBoot{
    .magic = MAGIC,
    .flags = FLAGS,
    .checksum = -(MAGIC + FLAGS),
};

export fn kernel_main() noreturn {
    term.initialize();
    term.write("Hello, World!");
    while (true) {
        term.handleInput();
    }
}

export fn _start() callconv(.Naked) noreturn {
    // Set up the stack pointer
    asm volatile (
        \\  mov $stack_bytes, %%esp
        \\  add %[stack_size], %%esp
        \\  call kernel_main
        :
        : [stack_size] "n" (STACK_SIZE),
    );
}
