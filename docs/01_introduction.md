# Introduction

## Summary
1. [About the Project](#about-the-project)
    - [Q&A](#q&a)
    - [Pre-requisites](#pre-requisites)
2. [Setup](#setup)
    - [Generate Build Exe](#generate-build-exe)
    - [Disabling standard library](#disabling-standard-library)


## About the Project

### Q&A
1. What's this repository based on?
    - > I bases this repository on Philipp Oppermann's posts ["Writing an OS in Rust"](https://os.phil-opp.com/), he wrote it using Rust, so, because I'm studying  Zig I thought about writing the same in Zig. :D 
2. Why?
    - > I want to learn.
3. Why zig?
    - > ... I want to learn ... zig
4. Which OS target?
    - I'll try to develop it to x86_64 architecture.

<!-- 
    TODO: 
        - Add more info
-->

### Pre-requisites
1. No std:
    - > [...] we can’t use threads, files, heap memory, the network, random numbers, standard output, or any other features requiring OS abstractions or specific hardware. [...]
2. No Dependencies
    - > [...] create an executable that can be run without an underlying operating system. [...]
3. Use what's available:
    - > TODO: What can be used?
4. Install `qemu-system-x86`
    - > We'll be able to use `qemu-system-x86_64` to run our Minimal Kernel/OS.

## Setup

### Generate Build Exe
Run: 
> $ zig init-exe

### Disabling standard library
- Remove STD code in `src/main.zig`, it will look like this:
```zig
pub fn main() !void {}
```

- In `build.zig`, append the following:
```zig
pub fn panic(_: []const u8, _: ?*builtin.StackTrace) noreturn {
    while (true) {}
}
```
