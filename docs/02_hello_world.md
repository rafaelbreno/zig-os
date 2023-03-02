# Hello World
If you didn't read the [First Chapter(Introduction)](./01_introduction.md), please read it first.

## Summary
1. [Introduction](#introduction)
    - [Running as it is](#running-as-it-is)
## Introduction
In this Chapter, we'll be trying to show a simple "Hello, World" running on a `x86-freestanding` architecture.

### Running as it is
Let's try to run as it is right now:

Building:
- > $ zig build
    - This will compile our code into a binary.

This will generate:
```shell
.
├── build.zig
├── src
│   └── main.zig
├── zig-cache
│   ├── h
│   │   └── ...
│   ├── o
│   │   └── ...
│   ├── tmp
│   └── z
│       └── ...
└── zig-out
    └── bin
        └── zig-os
```
The `zig-out/bin/zig-os` is what we need.

Running `qemu`:
- > $ qemu-system-x86_64 -kernel zig-out/bin/zig-os
    - This will run a `x86_64` "machine" with our binary as a _kernel_

Output: 
```shell
qemu-system-x86_64: Error loading uncompressed kernel without PVH ELF Note
```

It didn't work :( , let's try to understand it in the next section ->

## PHV ELF Note
What does this mean: 
- _"qemu-system-x86_64: Error loading uncompressed kernel without PVH ELF Note"_ ?

### PHV
- Is a mix between HVM and PV:
    - HVM: _"HVM (known as Hardware Virtual Machine) is the type of instance that mimics bare-metal server setup which provides better hardware isolation. With this instance type, the OS can run directly on top of the Virtual Machine without additional configuration making it to look like it is running on a real physical server. For more information about this instance type and the other one that is most commonly used, [...]"_
    - PV: _"Paravirtualization (PV) is an efficient and lightweight virtualization technique introduced by the Xen Project team [...] PV does not require virtualization extensions from the host CPU and thus enables virtualization on hardware architectures that do not support Hardware-assisted virtualization. [...]"_

### ELF Note
E.L.F. = "Executable and Linkable Format"
_"[...] is a common standard file format for executable files, object code, shared libraries, and core dumps. [...]"_

### Resolution
So, basically the binary that we're trying to run as a kernel is missing the `PVH ELF Note`, to solve that:
