# Hello World
If you didn't read the [First Chapter(Introduction)](./01_introduction.md), please read it first.

## Summary
1. [Introduction](#introduction)
    - [Running as it is](#running-as-it-is)
2. [PHV ELF Note](#phv-elf-note)
    - [PHV](#phv)
    - [ELF Note](#elf-note)
3. [Target](#target)
    - [Setting x86-freestanding Target](#setting-x86-freestanding-target)
    - [Building with Custom Target](#building-with-custom-target)
4. [Linker](#linker)
    - [Linker File](#linker-file)
    - [Using LD File](#using-ld-file)
    - [Building with Linker](#building-with-linker)
5. [Main File](#main-file)
    - [Multiboot](#multiboot)
        - [Consts](#consts)
        - [Linking Multiboot](#Linking Multiboot)
    - [Entry Function](#entry-function)
        - [Defining Start](#defining-start)
6. [Printing Hello](#printing-hello)
    - [Colors](#colors)
    - [Dimensions](#dimensions)
    - [Terminal Struct](#terminal-struct)
        - [Attributes](#attributes)
        - [Functions](#functions)
        - [Implementing Terminal](#implementing-terminal)
        - [Printing](#printing)
    - [Next Steps](#next-steps)

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

## Target
Basically what is happening when running `zig build` is building a binary matching your machine architecture, let's change this:

In `build.zig`, we currently have:
```zig
const std = @import("std");

// ...
pub fn build(b: *std.Build) void {
    // ...
    const target = b.standardTargetOptions(.{});

    /// ...
}
```

#### Setting x86-freestanding Target
Let's add the following imports after `const std = ...`: 
```zig
const std = @import("std");
const Target = std.Target;
const CrossTarget = std.zig.CrossTarget;
```
- `Target`
    - It stores the `enum` for different CPU architectures and OS tags
- `CrossTarget`
    - This struct will set our `const target` value/type.


Then, let's declare our target as:
```zig
pub fn build(b: *std.Build) void {
    const target = CrossTarget{
        .cpu_arch = Target.Cpu.Arch.x86,
        .os_tag = Target.Os.Tag.freestanding,
    };
    // ...
}
```
Our CPU architecture will be `x86` and the OS tag `freestanding`, meaning: We want to build a binary for `CPU x86` without and underlying OS.

Let's try to build and run it again:

#### Building with Custom Target
- > $ zig build
- > $ qemu-system-x86_64 -kernel zig-out/bin/zig-os
Output: 
```shell
qemu-system-x86_64: Error loading uncompressed kernel without PVH ELF Note
```
Hmmm, we got the same error, again. Maybe it's a linker issue?

## Linker
_"[...] An LD file is a script written in the GNU "linker command language." It contains one or more commands that are used to configure how input files storing static object code are to be compiled into a single executable program or library for the GNU operating system. [...]"_


Let's add a `src/linker.ld` file:
```ld
ENTRY(_start)
 
SECTIONS {
	. = 1M;
 
	.text : ALIGN(4K) {
		KEEP(*(.multiboot))
		*(.text)
	}
 
	.rodata : ALIGN(4K) {
		*(.rodata)
	}
 
	.data : ALIGN(4K) {
		*(.data)
	}
 
	.bss : ALIGN(4K) {
		*(COMMON)
		*(.bss)
	}
}
```
Well, that's a lot of things that I've never seen before, let's try to understand what is happening.

### Linker File
- `01: ENTRY(_start)`
    - [ENTRY](https://ftp.gnu.org/old-gnu/Manuals/ld-2.9.1/html_chapter/ld_3.html#SEC24)
    - _"[...] command specifically for defining the first executable instruction in an output file [...]"_
    - So this, mean that we'll be specifying which section of our code will be the entrypoint when running our binary.
    - In this case, we defined as `_start`
- `03: SECTIONS {`
    - [SECTIONS](https://ftp.gnu.org/old-gnu/Manuals/ld-2.9.1/html_chapter/ld_3.html#SEC17)
    - _"[...] `SECTIONS` command controls exactly where input sections are placed into output sections, their order in the output file, and to which output sections they are allocated. [...]"_
    - So basically with `SECTIONS` you can do one of:
        - define the entry point
        - assign a value to a symbol
        - describe the placement of a named output section, and which input sections go into it.
- `04: . = 1M;`
    - [Location Counter](https://ftp.gnu.org/old-gnu/Manuals/ld-2.9.1/html_chapter/ld_3.html#SEC10)
    - _"The special linker variable dot `.` always contains the current output location counter. [...]"_
    - This will reserve a 1M storage section in our _kernel_
        - TODO: CHECK THIS - I'm not sure about it.
- `06: .text : ALIGN(4K) {`
    - `.text` is the name of the _section_
    - `: ALIGN(4K) {` 
        - [Arithmetic Functions](https://ftp.gnu.org/old-gnu/Manuals/ld-2.9.1/html_chapter/ld_3.html#SEC14)
        - _"`ALIGN(exp)` - Return the result of the current location counter `(.)` aligned to the next `exp` boundary. [...]"_
- `07: KEEP(*(.multiboot))`
    - [KEEP](https://www.microchip.com/forums/m384725.aspx)
    - This marks a section that SHOULDN'T be eliminated
    - `*(.multiboot)`
        - `*(exp)` - _"You can name one or more sections from your input files, for insertion in the current output section. [...]"_
TODO: FINISH THIS SECTION

### Using LD File
To use our `src/linker.ld` file we should modify our `build.zig`, loading the `src/linker.ld` using:
- `exe.setLinkerScriptPath(.{ .path = "src/linker.ld" });`

```zig
const exe = b.addExecutable(.{
    .name = "zig-os",
    // In this case the main source file is merely a path, however, in more
    // complicated build scripts, this could be a generated file.
    .root_source_file = .{ .path = "src/main.zig" },
    .target = target,
    .optimize = optimize,
});

exe.setLinkerScriptPath(.{ .path = "src/linker.ld" });
```

### Building with Linker
Let's try again building it.
1. > $ zig build
2. > $ qemu-system-x86_64 -kernel zig-out/bin/zig-os
```shell
qemu-system-x86_64: Error loading uncompressed kernel without PVH ELF Note
```

Still, the same error, if we look at the first line of our `linker.ld` file, you can see that the entrypoint of our program should be `_start`, but we don't have it, so, in the next section we'll be modifying our `src/main.zig` and finally be able to "boot" our kernel.

## Main File
First of all, clean the `src/main.zig` and let's add something there.

### Multiboot
We need to define a `MultiBoot` struct following the pattern from [Header Magic Fields](https://www.gnu.org/software/grub/manual/multiboot/multiboot.html#Header-magic-fields) config, we need 3 fields
- `magic: i32` 
    - _"The field `magic` is the magic number identifying the header, which **must** be the hexadecimal value `0x1BADB002`."_
- `flags: i32`
    - _"specifies features that the OS image requests or requires of an boot loader."_
- `checksum: i32`
    - _"is a 32-bit unsigned value which, when added to the other magic fields (i.e. `magic` and `flags`), must have a 32-bit unsigned sum of zero."_
[Multiboot Manual](https://www.gnu.org/software/grub/manual/multiboot/multiboot.html)

#### Struct
With that in mind we should implement our struct:
```zig
const MultiBoot = extern struct {
    magic: i32,
    flags: i32,
    checksum: i32,
};
```

#### Consts:
Following the information from [Header Magic Fields](https://www.gnu.org/software/grub/manual/multiboot/multiboot.html#Header-magic-fields):
```const
const ALIGN = 1 << 0; // 0000 0000 0000 0000 0000 0000 0000 0001
const MEMINFO = 1 << 1; // 0000 0000 0000 0000 0000 0000 0000 0010
const FLAGS = ALIGN | MEMINFO; // 0000 0000 0000 0000 0000 0000 0000 0000 0011
const MAGIC = 0x1BADB002; // 0001 1011 1010 1101 1011 0000 0000 0010
```

Being:
- `ALIGN`:
    - TODO:
- `MEMINFO`:
    - TODO:
- `FLAGS`:
    - TODO:
- `MAGIC`:
    - The default hexadecimal value: `0x1BADB002`

#### Linking Multiboot
Now we should link our `MultiBoot struct` with our `src/linker.ld`'s `.multiboot` section:
```zig
export var multiboot align(4) linksection(".multiboot") = MultiBoot{
    .magic = MAGIC,
    .flags = FLAGS,
    .checksum = -(MAGIC + FLAGS),
};
```
- `export var multiboot align(4) linksection(".multiboot")`:
    - `export`: _"[...] makes a function or variable externally visible in the generated object file. [...]"_
    - `var`: _"declares a variable that may be modified."_
    - `multiboot`: The name of the variable.
    - `align(4)`:
        - _"can be used to specify the alignment of a pointer. It can also be used after a variable or function declaration to specify the alignment of pointers to that variable or function."_
        - Basically we're making this variable divisible by `4`, so _"when when a value of the type is loaded from or stored to memory, the memory address must be evenly divisible by this number."_.
    - `linksection(".multiboot")`
        - There're no official docs for this `keyword`, yet.
        - Basically we're linking the `Multiboot` variable with `.multiboot` section.

So now, if you try to run `zig build` you will, get the following error:
```shell
LLD Link... warning(link): unexpected LLD stderr:
ld.lld: warning: cannot find entry symbol _start; not setting start address
```

This means that we didn't defined the entrypoint `_start` declared on `src/linker.ld`, we'll do it in the next section:

### Entry Function
Let's add the following code to our `src/main.zig`:

#### Defining Start
So now that we've our `multiboot` set, let's write our entrypoint `_start`:
```zig
export fn _start() callconv(.Naked) noreturn {
    while(true){}
}
```
- `export fn _start() callconv(.Naked) noreturn`
    - `fn`: _"declares a function."_
    - `_start()`: is the name of the function.
    - `callconv(.Naked)`: 
        - `callconv`: _"[...] The callconv specifier changes the calling convention of the function."_ 
        - `.Naked`: _"The naked calling convention makes a function not have any function prologue or epilogue. This can be useful when integrating with assembly. [...]"_
    - `noreturn`: sets the function as non-returnable, so it'll run until the program/process is terminated.

Now, let's try building it again:
1. > $ zig build
2. > $ qemu-system-x86_64 -kernel zig-out/bin/zig-os
```shell
VNC server running on ::1:5900
```
Oh, that's something else :) 
Now, in another terminal run:
> $ vinagre localhost:5900

This should open a window with our kernel running, well, it's doing much but it's something.

## Printing Hello
Now that we've our kernel ~barely~ "working", it's time to write something in the terminal, let's create the file: `src/terminal/terminal.zig`

### Colors
First we need to define some constants:
```zig
// src/terminal/terminal.zig
// Because this is a 16 bits terminal, we need to define the 16 colors
const VgaColor = u8;
const VGA_COLOR_BLACK = 0;
const VGA_COLOR_BLUE = 1;
const VGA_COLOR_GREEN = 2;
const VGA_COLOR_CYAN = 3;
const VGA_COLOR_RED = 4;
const VGA_COLOR_MAGENTA = 5;
const VGA_COLOR_BROWN = 6;
const VGA_COLOR_LIGHT_GREY = 7;
const VGA_COLOR_DARK_GREY = 8;
const VGA_COLOR_LIGHT_BLUE = 9;
const VGA_COLOR_LIGHT_GREEN = 10;
const VGA_COLOR_LIGHT_CYAN = 11;
const VGA_COLOR_LIGHT_RED = 12;
const VGA_COLOR_LIGHT_MAGENTA = 13;
const VGA_COLOR_LIGHT_BROWN = 14;
const VGA_COLOR_WHITE = 15;

// foreground | background color.
fn vgaEntryColor(fg: VgaColor, bg: VgaColor) u8 {
    // will build the byte representing the color.
    return fg | (bg << 4);
}

// character | color
fn vgaEntry(uc: u8, color: u8) u16 {
    var c: u16 = color;

    // build the 2 bytes representing the printable caracter w/ EntryColor.
    return uc | (c << 8);
}
```

### Dimensions
We need to define somehow how many rows/columns the terminal will have, so before we build our terminal, let's define some constants for it:
```zig
// src/terminal/terminal.zig
const VGA_WIDTH = 80;
const VGA_HEIGHT = 45;
```

### Terminal Struct
First, we declared the struct:
```zig
// src/terminal/terminal.zig
pub const terminal = struct {}
```
- `pub` - Keyword to define that it's public, allowing us to import it from `src/main.zig`

But an empty struct, won't do nothing, let's start filling it with code:

#### Attributes
```zig
// row / column are variable to allow us to keep up 
// with the current position in the buffer
var row: usize = 0;
var column: usize = 0;

// color will be a u16 value that represents the fore/back ground color
// of our terminal.
var color = vgaEntryColor(VGA_COLOR_LIGHT_GREY, VGA_COLOR_BLACK);

// buffer is the data in our screen, so if we want to print "Hello, World!"
// we'll need to store it in our buffer
const buffer = @intToPtr([*]volatile u16, 0xB8000);
```

- `const buffer = @intToPtr([*]volatile u16, 0xB8000);`
    - `const buffer`: declaring a constant named _"buffer"_
    - `@intToPtr`: 
        - _"Converts an integer to a pointer. [...]"_
        - `@intToPtr(comptime DestType: type, address: usize) DestType`
    - `[*] volatile u16`: 
        - `[*] T` _"many-item pointer to unknown number of items."_ of type `T`
        - `volatile`: _"can be used to denote loads or stores of a pointer have side effects. It can also modify an inline assembly expression to denote it has side effects."_
        - `u16`: 16 bits - 2 bytes
    - `0xB8000`: _"[...] The text screen video memory for colour monitors resides at 0xB8000 [...]"_

#### Functions
```zig
// initialize fills the current buffer with the empty character(' ').
pub fn initialize() void {
    var y: usize = 0;
    while (y < VGA_HEIGHT) : (y += 1) {
        var x: usize = 0;
        while (x < VGA_WIDTH) : (x += 1) {
            putCharAt(' ', color, x, y);
        }
    }
}

// setColor updates the current color value.
fn setColor(new_color: u8) void {
    color = new_color;
}

// putCharAt receives:
// - `char` the u8.
// - `char_color` the char color.
// - `x` - the column position
// - `y` - the row position
// and with that, stores the `char` in the given buffer [index]
fn putCharAt(char: u8, char_color: u8, x: usize, y: usize) void {
    const index = y * VGA_WIDTH + x;
    buffer[index] = vgaEntry(char, char_color);
}

// putChar will store a byte in the current buffer position
// and then update the current position to the next one.
fn putChar(c: u8) void {
    putCharAt(c, color, column, row);
    column += 1;
    if (column == VGA_WIDTH) {
        column = 0;
        row += 1;
        if (row == VGA_HEIGHT)
            row = 0;
    }
}

// write receives an array of data and stores in the buffer.
pub fn write(data: []const u8) void {
    for (data) |c|
        putChar(c);
}
```

#### Implementing Terminal
In `src/main.zig`:
```zig
// import our terminal module.
const term = @import("terminal/terminal.zig").terminal;


export fn _start() callconv(.Naked) noreturn {
    // initialize the terminal
    term.initialize();
    // write data into the buffer.
    term.write("Hello, World!");
    while (true) {}
}
```

#### Printing:
DISCLAIMER: If you get stuck in terminal, try to Press `CTRL+Alt+2` and then type `quit` and enter.

1. > $ zig build
2. > $ qemu-system-x86_64 -kernel zig-out/bin/zig-os
```shell
VNC server running on ::1:5900
```
3. Now in another terminal run:
    - > $ vinagre localhost:5900

This should pop open a window with `Hello, World!` Written on it

### Next Steps
Well, we're far away from having a working kernel, we don't even have a working shell, so maybe that's something that we could in the next chapter.

[Chapter 3 - TODO]()

## References
- [PVH](https://xenbits.xen.org/docs/4.6-testing/misc/pvh.html)
- [HVM](https://docs.rightscale.com/faq/What_is_Hardware_Virtual_Machine_or_HVM.html)
- [PV](https://wiki.xenproject.org/wiki/Paravirtualization_(PV))
- [PV HVM](https://www.linux.org/threads/hardware-virtual-machine-hvm-and-paravirtualization-pv.12475/)
- [PV HVM (AWS)](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/virtualization_types.html)
- [ELF](https://en.wikipedia.org/wiki/Executable_and_Linkable_Format)
- [Linker Script](https://ftp.gnu.org/old-gnu/Manuals/ld-2.9.1/html_chapter/ld_3.html)
- [LD File](https://fileinfo.com/extension/ld)
- [OSDev ORG](https://wiki.osdev.org/Main_Page)
- [0xB8000](https://wiki.osdev.org/Printing_To_Screen)
