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

export var multiboot align(4) linksection(".multiboot") = MultiBoot{
    .magic = MAGIC,
    .flags = FLAGS,
    .checksum = -(MAGIC + FLAGS),
};

export fn _start() callconv(.Naked) noreturn {
    term.initialize();
    term.write("Hello, World!");
    while (true) {}
}
