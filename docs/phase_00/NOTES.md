# Phase 0 - Notes for `The Sandbox: Tooling, Emulation, and Your First ELF`

## 0.1 Install the toolschain

### What I built
Installed `qemu`, `gdb`, `zig`, `xorriso` and `mtools`.

### What I learned (concepts)
- What is QEMU: Basically a "recompiler" of machine code, translates from host to target(ARM emulates x86)
- What is KVM: Basically it emulates a program directly on the host hardware, so it must match archs (x86 running x86)
- ISO 9660: Standards for CD-ROMs

### What surprised me
<things that didn't match the docs, or that took me hours to figure out>

### What I'd do differently
<honest postmortem>

### Verification evidence
- `zig version`
```shell
0.16.0
```

- `qemu-system-x86_64 --version`
```shell
QEMU emulator version 9.2.3
Copyright (c) 2003-2024 Fabrice Bellard and the QEMU Project developers
```

- `gdb -ex "set architecture i386:x86-64" -ex "quit"`
```shell
GNU gdb (GDB) 17.2
Copyright (C) 2025 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
Type "show copying" and "show warranty" for details.
This GDB was configured as "--host=aarch64-apple-darwin25.4.0 --target=x86_64-apple-darwin20".
Type "show configuration" for configuration details.
For bug reporting instructions, please see:
<https://www.gnu.org/software/gdb/bugs/>.
Find the GDB manual and other documentation resources online at:
    <http://www.gnu.org/software/gdb/documentation/>.

For help, type "help".
Type "apropos word" to search for commands related to "word".
The target architecture is set to "i386:x86-64".
```

- `xorriso --version`
```shell
GNU xorriso 1.5.8.pl02 : RockRidge filesystem manipulator, libburnia project.

GNU xorriso 1.5.8.pl02
ISO 9660 Rock Ridge filesystem manipulator and CD/DVD/BD burn program
Copyright (C) 2026, Thomas Schmitt <scdbackup@gmx.net>, libburnia project.
xorriso version   :  1.5.8.pl02
Version timestamp :  2026.05.22.150001
Build timestamp   :  -none-given-
libisofs   in use :  1.5.8  (min. 1.5.8)
libjte     in use :  2.0.0  (min. 2.0.0)
libburn    in use :  1.5.8  (min. 1.5.8)
libburn OS adapter:  internal X/Open adapter sg-dummy
libisoburn in use :  1.5.8  (min. 1.5.8)
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
```

- ``
```shell
```

- ``
```shell
```

### Open questions

#### Difference between emulation (QEMU) and virtualization (KVM). Why QEMU is preferred for early OS dev.
QEMU emulates machines, it works by "recompiling" binary code written for a given processor into another one, e.g running ARM in an x86_64 PC.
KVM isolate a slice of real hardware, so the guest code/OS runs directly on the host CPU, so it MUST match the host architecture, e.g running x86 in an x86 PC.

There's a few motives for sticking with QEMU for most of this study:
1. Cross-platform: No need for a specific hardware, we can just emulate it.
2. Debugging: With QEMU we can integrate it with `gdb` and do a bunch of debugging that in a KVM it would be incredibily difficult.
3. Safety from Crashes: To avoid a "Triple Fault", where on a real hardware would reboot the host machine, with QEMU it just logs telling you what happened.

#### What "remote debugging" means. The role of `gdbserver`.
"Remote debugging" is basically debugging a program that is running on a different host.
In our case we are developing an OS that is running on QEMU (a remote setup), so `gdb` is split into a client-server interaction, this is where `gdb-server` comes in.
`gdb-server` acts like the eyes and hands of `gdb`, so in our host machine we're running `gdb` that is doing the heavy lifting, while in our target machine (qemu) the `gdb-server` is running and communicating with `gdb`.

#### What is ISO 9660?
Is a standard file system used for formatting CD-ROMs, so a `.iso` file is literally a section-by-section copy of an ISO 9660 disc stored as a single file.


#### The role of `xorriso` and `mtools`
Not important right now, but:
- `xorriso`: create/manipulate `.iso`, it will be used way later on
- `mtools`: Manipulate FAT(12, 16 and 32) filesystems without mounting.

## 0.2 Understand the build target

### What I built
<one paragraph>

### What I learned (concepts)

#### Freestanding Program(Standalone Program): 
- Is a program that does not load any external module, library function or program.
- Designed to run on bare metal (without an OS)

#### Target Triplets:
- Identifier for how the machine-code should be generated
- Format: `arch-vendor-os-abi`
    - `arch`: Is the architecture, e.g `x86_64`
    - `vendor`: Creator/maintainer of the build, e.g `microsoft`, `apple`
    - `os`: The Operating System, e.g `linux`
    - `abi`: Application Binary Interface, e.g `gnu`
- `x86_64-linux-gnu`:
    - 64-bit Intel/AMD Operations
    - Linux Operating System 
    - GNU C-Library (`glibc`)
- `x86_64-freestanding-none`
    - 64-bit Intel/AMD Operations
    - Freestanding, so no vendor specific operations
    - No operating system, meaning no system calls, no memory management, nothing.

#### ELF

##### What is ELF
_Executable and Linking Format_, aka **ELF**, aka _object file format_, is a standard intended to streamline software development by providing developers with a set of binary interface definitions that extend across multiple operating environments.
There're three main types of object files:
- _Relocatable File_: Holds code and data suitable for linking with other object files.
- _Executable File_: Holds a program suitable for execution.
- _Shared Object File_: Hold code and data suitable for linking in two contexts:
    1. Link editor may process it with other _Relocatable Files_ to create another _object file_.
    2. Dynamic Linker combines it with another _executable file_ and other _shared object files_ to create a process image.

_Object Files_ are binary representations of programs inteded to execute _directly on a processor_, and that's what we want, because we will be writing a freestanding program.


##### Sections
- `.text` (Code)
    - Holds the actual executable machine language instructions (compiled from a code).
- `.data` (Initialized Data)
    - Holds the initialized data that contributes to the program's memory image.
- `.bss` (Block Started by Symbol / Unitialized Data)
    - Holds global and static variables that are either unitialized or initialized to zero.
- `.rodata` (Read-Only Data)
    - Holds constant data that cannot be changed during execution.

### What surprised me
<things that didn't match the docs, or that took me hours to figure out>

### What I'd do differently
<honest postmortem>

### Verification evidence
- _"You can explain in one sentence why your kernel can't use `std.io`."_:
    - `std.io` uses modules from the host machine, in a freestanding environment those modules don't exists.

### Open questions
<things I deferred — return to these later>

## 0.3 First freestanding build

### What I built
A minimal freestanding x86_64 kernel binary that compiles to ELF format. The kernel has a single `_start` entry point that loops forever.

### What I learned (concepts)

#### Project Structure
```shell
.
├── boot/ 
├── build/
├── build.zig
├── build.zig.zon
├── docs/
├── kernel/
│   └── src/
│       └── main.zig
├── LICENSE
├── README.md
└── TODO.md
```

- `boot/`
    - Here we will have all the necessary files for booting (linker script, Limine config, etc.)
    - Populated starting in Phase 1.2
- `build/`
    - Output directory for compiled artifacts (controlled by `build.zig`)
- `docs/`
    - Development documentation in Markdown files
- `kernel/src/`
    - Ring 0 code that talks directly to hardware

#### The `_start` Function
- `_start` is the **entry point** — the linker looks for this symbol to know where the CPU should jump first
- Must be `export`ed so it appears in the ELF object file and the linker can find it
- Marked `noreturn` because it never returns (loops forever)

#### `build.zig` Configuration
The build file configures:
- **Target**: `x86_64-freestanding-none` (64-bit Intel/AMD, no OS layer, no ABI)
- **Code Model**: `.kernel` (generates code suitable for kernel-space addresses)
- **Red Zone**: Disabled (`false`) — the red zone is a System V ABI feature we can't use in freestanding code
- **Artifact Installation**: Compiles to ELF and places in `zig-out/bin/`

Removed the `run` step because `zig build run` would try to execute a kernel binary on the host (which makes no sense — we'll boot with QEMU instead).

#### Assembly Output
The compiler generates:
```asm
_start:
  push %rbp           # Function prologue (not strictly needed for noreturn)
  mov %rsp,%rbp
  nop
  jmp <_start+0x4>    # Infinite loop back to nop
```

The prologue happens automatically; the `jmp` is your `while(true){}` in assembly form.

### What surprised me
The compiler automatically adds function prologue/epilogue code even for a `noreturn` function that doesn't need it. For now this is fine, but in optimized code we could use `naked` functions to remove it.
With `.naked` the `main.zig` file would look like this:
```zig
```

### What I'd do differently
Nothing — straightforward phase. The structure is clean and the build output is as expected.

### Verification evidence
- `zig build` succeeds
- `readelf -h zig-out/bin/zig-os` shows ELF64 executable, entry point at `0x103def0`
- `objdump -d zig-out/bin/zig-os` shows `_start` as a simple infinite loop

### Open questions
- Why does the compiler add prologue/epilogue to a `noreturn` function? (Minor optimization opportunity for later)
- How does the linker script (Phase 1.2) change the entry point address from `0x103def0` to the high-half kernel space?
