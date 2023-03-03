# Introduction

## Summary
1. [About the Project](#about-the-project)
    - [Q&A](#q&a)
    - [Pre-requisites](#pre-requisites)
2. [Setup](#setup)
    - [Tools](#tools)
    - [Create Zig Build](#create-zig-build)

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
This section will show you how to setup your environment to start working on the step-by-step guide.

### Tools
- [Zig _(0.11)_](https://ziglang.org/)
- [qemu-system](https://www.qemu.org/)
    - I'll be using the `qemu-system-x86`
- [vinagre](https://gitlab.gnome.org/Archive/vinagre)

### Create Zig Build
- > $ zig init-exe
This will generate the following structure:
```shell
.
├── build.zig
└── src
    └── main.zig
```

- `build.zig`
    - This file is responsible for defining how to build your program
    - You can define things like:
        - Target: Architecture, Operational System, etc.
        - Optimization: Release, Debug, etc.
- `src/main.zig`
    - This is the program itself that will be compiled 

### Final
So, yeah, now we should have everything to start working on our minimal kernel!

[Chapter 2 - Hello World](./02_hello_world.md)
