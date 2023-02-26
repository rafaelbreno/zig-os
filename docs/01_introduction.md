# Introduction

## Summary
1. [About the Project](#about-the-project)
    - [Q&A](#q&a)
    - [Pre-requisites](#pre-requisites)
2. [Setup](#setup)
    - [Generate Build Exe](#generate-build-exe)
    - [Disabling standard library](#disabling-standard-library)
        - [Setting Freestanding Target](#setting-freestanding-target)
        - [Fixing LLD Link Error](#fixing-lld-link-error)


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

### Create Zig File
- `zig-os.zig`:
```zig
pub fn main() !void {}
```

### Disabling standard library
- In `zig-os.zig`, append the following:
```zig
pub fn panic(_: []const u8, _: ?*@import("std").builtin.StackTrace, _: ?usize) noreturn {
    while (true) {}
}
```

#### Setting Freestanding Target
To disable the standard library we need to compile our Zig code into a _"freestanding"_ / _"bare-metal"_ binary, fortunately Zig's compiler allows us to set the target as _"freestanding"_. 
You can see it if you run: 
> $ zig targets | head -n 70
```json
{
 "arch": [
  "arm",
  "armeb",
  "aarch64",
  "aarch64_be",
  "aarch64_32",
  // ...
 ],
 "os": [
  "freestanding",
  // ...
}
```

You could build it running:
> $ zig build-exe -target <arch><sub>-<os>-<abi>
For example, to build a binary for my _Arch Linux x86\_64_
> $ zig build-exe build.zig -target aarch64-freestanding
It will print the following error:
```shell
LLD Link... warning(link): unexpected LLD stderr:
ld.lld: warning: cannot find entry symbol _start; not setting start address
```

So, we'll need to fix it!

#### Fixing LLD Link Error
I don't know what LLD is, but I think it's something about we're trying to build a freestanding binary but trying to link it against some kind of libc.


[StandardTargetOptions](https://github.com/ziglang/zig-bootstrap/blob/8aa969bd1ad4704a6f351db54aac7ca11de73a9d/zig/lib/std/build.zig#L819)
```zig
pub const StandardTargetOptionsArgs = struct {
    whitelist: ?[]const CrossTarget = null,

    default_target: CrossTarget = CrossTarget{},
};
```
[CrossTarget](https://github.com/ziglang/zig-bootstrap/blob/8aa969bd1ad4704a6f351db54aac7ca11de73a9d/zig/lib/std/zig/CrossTarget.zig)
