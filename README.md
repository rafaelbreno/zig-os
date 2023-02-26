# zig-os
A simple OS written in Zig following Philipp Oppermann's posts ["Writing an OS in Rust"](https://os.phil-opp.com/)

## Summary
1. [Introduction](./docs/01_introduction.md)

> $ zig build-exe zig-os.zig -target x86_64-freestanding -T linker.ld
> $ qemu-system-x86_64 -kernel zig-os
> $ vinagre localhost:PORT
