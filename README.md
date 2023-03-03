# zig-os
A simple OS written in Zig following Philipp Oppermann's posts ["Writing an OS in Rust"](https://os.phil-opp.com/)

## Summary
1. [Introduction](./docs/01_introduction.md)
2. [Hello World](./docs/02_hello_world.md)

> $ zig build-exe zig-os.zig -target x86_64-freestanding -T linker.ld
> $ qemu-system-x86_64 -kernel zig-os
> $ vinagre localhost:PORT

[std.Build.CrossTarget](https://ziglang.org/documentation/master/std/#A;std:Build.CrossTarget)
[std.Build.StandardTargetOptionsArgs](https://ziglang.org/documentation/master/std/#A;std:Build.StandardTargetOptionsArgs)
[CrossTarget](https://github.com/ziglang/zig-bootstrap/blob/a836b63c1ae8e734a0f94cc4031610adfb4bedf7/zig/lib/std/zig/CrossTarget.zig)
[CallModifier](https://github.com/ziglang/zig-bootstrap/blob/a836b63c1ae8e734a0f94cc4031610adfb4bedf7/zig/lib/std/builtin.zig)
[Zig Bare Bones](https://wiki.osdev.org/Zig_Bare_Bones)
