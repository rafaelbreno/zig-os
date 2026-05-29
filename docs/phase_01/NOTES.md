# Phase 1 — The Spark: Booting Into Your Kernel

---

## 1.1 Understand the Boot Chain

### What I built
Nothing — this was pure study.

### What I learned (concepts)

#### Boot Sequence
1. **Power On** — user presses power button.
2. **Firmware Execution** — CPU executes a hardcoded JUMP to a fixed ROM address where the firmware (BIOS or UEFI) lives.
3. **POST** — firmware performs Power-On Self-Test. Halts if hardware fails.
4. **Bootloader Handoff** — firmware loads the partition table, finds a bootable device, and hands off to a bootloader:
   - **Legacy BIOS**: reads the first 512 bytes of the disk (Master Boot Record, MBR).
   - **UEFI**: finds a FAT32 EFI System Partition (ESP) and runs a bootloader executable.
5. **Kernel Execution** — Limine prepares a standardized environment (memory maps, framebuffer), loads `kernel.elf` into RAM, and JUMPs to `_start`.

#### BIOS vs UEFI
- **BIOS** (Basic Input/Output System) — legacy firmware, 16-bit mode, limited space.
- **UEFI** (Unified Extensible Firmware Interface) — modern replacement, richer capabilities.

#### Limine
Limine bridges the motherboard firmware (BIOS/UEFI) and the kernel. It abstracts firmware differences, sets up 64-bit mode and paging, and gives the kernel a clean, standardized handoff.

### What surprised me
- **Hardware bootstrapping is hardwired.** The CPU physically jumps to a fixed ROM address on power-up. Not software-configurable.
- **Historical constraints shape modern design.** The 512-byte MBR rule comes from ancient floppy disk geometry and persists purely for backward compatibility.
- **Bootloader complexity justifies deferral.** Writing a bootloader requires 16-bit assembly, filesystem drivers, ELF parsing, and dual BIOS/UEFI support — a project on its own.

### Open questions
- How does Limine actually parse the ELF and decide where to load each section?
- What exactly is in the "standardized environment" Limine sets up before jumping to `_start`?

---

## 1.2 The Linker Script

### What I built
A working `kernel/linker.ld` that places the kernel as a true higher-half kernel: virtual addresses start at `0xFFFFFFFF80100000`, physical load address at `0x100000` (1 MiB). Uses `AT()` directives for the virtual/physical split and `/DISCARD/` to strip unused metadata. Alongside it, `build.zig` disables PIE and forces the LLVM backend.

### What I learned (concepts)

#### Linker Script Purpose
Tells the linker how to organize compiled object files into the final executable and where each section lives in memory. The bootloader reads ELF program headers to load each section to the correct address.

#### Virtual vs Physical Addresses
- **VAddr** — where the CPU executes code (what running code sees).
- **PAddr** — where the bootloader places bytes in RAM.
- `AT(ADDR(.section) - KERNEL_VADDR_BASE)` converts virtual to physical.

#### Why Higher-Half / Why 1 MiB Physical
- Upper half reserved for the kernel; lower half stays free for future user space.
- 1 MiB physical (`0x100000`) avoids low-memory regions reserved by firmware.

#### GNU Linker Script Syntax
- `ENTRY(symbol)` — sets the entry point.
- `SECTIONS { }` — maps input sections to output sections and addresses.
- `.` — the location counter; tracks the current virtual address.
- `ALIGN(4K)` — advance to the next 4 KiB boundary.
- `AT(...)` — set physical load address separately from virtual address.
- `*(.text)` — wildcard collecting all `.text` sections from all object files.
- `/DISCARD/ { }` — drop matched sections from the output.

#### PIE
- PIE on (default): linker emits relocatable code, ignores fixed addresses.
- `exe.pie = false`: linker respects exact addresses. Required for a kernel.

#### Zig 0.16.0 Self-Hosted Backend Bug
Zig 0.16.0 defaults to its own self-hosted x86_64 backend. That backend's ELF linker ignores the location counter (`. = ...;`) and silently substitutes `--image-base`. Nothing errors — the addresses are just wrong. Tracked in ziglang/zig#24717.

Fix: `exe.use_llvm = true` switches to the LLVM backend, whose linker (LLD) honors the script correctly.

Note: `use_lld = true` (linker only) and `use_llvm = true` (full backend) are different. Feeding self-hosted output to LLD directly caused a SEGFAULT.

### Working `build.zig` configuration
```zig
exe.pie = false;
exe.use_llvm = true;
exe.setLinkerScript(b.path("kernel/linker.ld"));
```

### What surprised me
- The self-hosted backend silently ignored the linker script. No error — just wrong addresses.
- `use_lld` vs `use_llvm` are completely different. The fix was the codegen backend, not the linker.
- A reference project (Ymir hypervisor) confirmed the script was correct and the backend was the variable.

### Verification evidence
```
Entry point 0xffffffff801171b0

LOAD  0xffffffff80100000  0x0000000000100000  R E   (.text)
LOAD  0xffffffff80140310  0x0000000000140310  RW    (.data)
LOAD  0xffffffff80141000  0x0000000000141000  RW    (.bss)
```

### Open questions
- Deferred: `exe.link_gc_sections = true` to strip unused compiler_rt functions (Phase 14 polish).

---

## 1.3 Limine Boot Setup

### What I built
Three Limine protocol request structs (`HHDMRequest`, `FrameBufferRequest`, `MemMapRequest`) in `kernel/limine.zig`, exported from `kernel/main.zig`. A bootable ISO built by `scripts/build-iso.sh`, wired into `build.zig` as `zig build iso` and `zig build run`. A working `kernel/limine.conf`. The kernel boots in QEMU: Limine loads `kernel.elf`, jumps to `_start`, and the CPU halts cleanly. GDB confirms the entry point.

### What I learned (concepts)

#### The Limine Protocol: Request/Response Model
Before jumping to `_start`, Limine scans the loaded kernel image for request structs (identified by magic numbers). For each recognized request, it fills in the `response` pointer with data the kernel can read after boot.

Three essential requests:
- **HHDM** — gives the virtual offset mapping all physical memory into the upper half. Without it, physical addresses cannot be dereferenced from kernel code.
- **Framebuffer** — gives a pointer to the screen's pixel buffer (already virtually mapped).
- **Memory Map** — lists every RAM region (usable, reserved, ACPI, firmware, etc.).

The fundamental relationship: `Virtual Address = Physical Address + HHDM Offset`

#### Base Revisions
Limine protocol versions are called base revisions. Revisions 0–5 are deprecated. Base Revision 6 is current. For x86-64, revisions 5 and 6 are identical; revision 6 only adds constraints for other architectures. Always target the latest.

The base revision tag is a 3-element `u64` array: two magic values followed by the revision number. It must be present in the binary alongside the requests.

#### Zig Struct Layouts for C Interop
Three struct types exist in Zig with different memory guarantees:
- `struct` — automatic layout; compiler may reorder fields. Cannot be `export`ed (no guaranteed in-memory representation).
- `packed struct` — bit-level packing. Cannot contain arrays (`[4]u64` has no bit-packed representation).
- `extern struct` — C-compatible layout; fields in order, natural alignment. Required for anything crossing an ABI boundary.

#### Placing Variables in Linker Sections (Zig)
The correct Zig idiom to place a variable in a specific linker section:
```zig
export var hhdm_request: limine.HHDMRequest linksection(".requests") = .{ ... };
```
This is the direct equivalent of GCC's `__attribute__((section("...")))`. Not `@export`, not `comptime` tricks — just `linksection`.

#### `const` vs `var` for Limine Requests
`export const` places data in `.rodata` (read-only memory). Limine writes the response pointer into the struct at load time. Writing to read-only memory faults. Always use `export var` so the struct lands in `.data` (writable).

#### Duplicate Magic Symbols (LLVM Footgun)
Named intermediate constants in Zig (e.g. `const hhdm_common_magic = [4]u64{...}`) cause LLVM to emit the array as a separate `.rodata` symbol. When used as a struct field default, the bytes appear twice in the binary. Limine's scanner found two HHDM request patterns and panicked with a duplicate request error.

Fix: inline magic values directly into struct field defaults. No named intermediate constants.

#### ISO 9660 Filename Truncation
ISO 9660 Level 1 (the default) enforces 8.3 filenames. `limine.conf` (11 characters) is silently truncated to `limine.con`. Limine looks for `limine.conf` and finds nothing.

Attempted fixes that did NOT work with macOS xorriso 1.5.8 `-as mkisofs`:
- `-r`, `-J` (short forms)
- `-rockridge`, `-joliet` (long forms — unrecognized)

Fix that worked: **`-iso-level 4`** (ISO 9660:1999, supports names up to 207 characters). Found in the xorriso man page.

#### Limine Config File Syntax (v11.x)
Wrong (old-style):
```
:Zig OS
PROTOCOL=limine
KERNEL_PATH=boot:///kernel.elf
```

Correct:
```
timeout: 5

/ Zig OS
    protocol: limine
    kernel_path: boot():/boot/limine/kernel.elf
```

Key differences:
- Entry names start with `/`, not `:`
- Options use `key: value`, not `KEY=VALUE`
- Path syntax is `resource(argument):/path`; `boot()` means "partition containing the config file"

#### Limine Config File Search Order (BIOS)
Limine scans the boot drive's partitions in order and looks for the config at:
1. `/boot/limine/limine.conf`
2. `/boot/limine.conf`
3. `/limine/limine.conf`
4. `/limine.conf`

ISO staging structure that works:
```
iso_root/
├── boot/limine/
│   ├── kernel.elf
│   ├── limine.conf
│   ├── limine-bios.sys        (used by bios-install)
│   ├── limine-bios-cd.bin     (the El Torito boot image)
│   └── limine-uefi-cd.bin
└── EFI/BOOT/
    └── BOOTX64.EFI
```

#### ELF Segment Alignment (Limine Requirement)
Limine enforces that no two LOAD segments with different permissions share the same 4K memory page. If `.text` (R E) and `.data` (RW) touch the same page, Limine panics:
```
PANIC: elf: Attempted to load ELF file with PHDRs with different permissions
sharing the same memory page.
```

Fix: place `. = ALIGN(4K);` between sections in the linker script, outside the section braces.

- Inside braces: creates extra output sections (wrong).
- In the section header as `ALIGN(4K)` alone: insufficient with LLD.
- Between sections as `. = ALIGN(4K);`: correct.

Working linker script pattern:
```ld
.text ALIGN(4K) : AT(ADDR(.text) - KERNEL_VADDR_BASE)
{
  *(.text)
  *(.rodata*)
}

. = ALIGN(4K);
.data : AT(ADDR(.data) - KERNEL_VADDR_BASE)
{
  *(.data)
}

. = ALIGN(4K);
.bss : AT(ADDR(.bss) - KERNEL_VADDR_BASE)
{
  *(COMMON)
  *(.bss)
}

. = ALIGN(4K);
.requests : AT(ADDR(.requests) - KERNEL_VADDR_BASE)
{
  *(.requests)
}
```

---

### Walls hit and how they were resolved

**Wall 1: `packed struct` rejects `[4]u64`**
Zig's `packed struct` requires all fields to have a bit-packed representation. Arrays don't qualify.
Fix: use `extern struct`.

**Wall 2: `struct` cannot be `export`ed**
Regular Zig structs have automatic layout with no in-memory guarantee. The compiler refuses to export them.
Fix: use `extern struct` (C-compatible layout, exportable).

**Wall 3: `export const` prevents Limine from writing the response pointer**
Limine writes the response pointer into the struct at load time. `const` → `.rodata` → read-only → fault.
Fix: use `export var`.

**Wall 4: Duplicate magic constants caused Limine to find two HHDM requests**
Named intermediate constants caused LLVM to emit the magic bytes twice. Limine panicked on duplicate requests.
Fix: inline magic values directly into struct field defaults.

**Wall 5: `linksection` was not being used**
Without `linksection(".requests")`, the request structs were placed in `.data` by default. Limine couldn't locate them through its section scanner.
Fix: add `linksection(".requests")` to every request variable declaration.

**Wall 6: `limine.conf` truncated to `limine.con` in the ISO**
ISO 9660 Level 1 enforces 8.3 filenames. Flags `-r`, `-J`, `-rockridge`, `-joliet` all failed on macOS xorriso.
Fix: `-iso-level 4` found in the xorriso man page.

**Wall 7: Boot menu shows `[config file not found]` despite correct filenames**
The config was at `/boot/limine.conf` instead of `/boot/limine/limine.conf`. Limine searches specific paths in a specific order.
Fix: restructure the staging directory to `/boot/limine/limine.conf`.

**Wall 8: Boot menu shows `[config file contains no valid entries]`**
The config used old syntax (`:EntryName`, `KEY=VALUE`, `boot:///path`). Limine v11.x uses different syntax.
Fix: rewrite config to `/ EntryName`, `key: value`, `boot():/path`.

**Wall 9: Limine panics on ELF segment alignment**
`.data` was at `0xffffffff80140430` (not 4K aligned), sharing a page with `.text`.
Fix: `. = ALIGN(4K);` between sections in the linker script.

**Wall 10: Limine v7.x was 3 years old**
Initially cloned `v7.x-binary`. Upgraded to `v11.x-binary`. Newer Limine has stricter validation that caught real bugs in the kernel binary.

---

### What surprised me
- `linksection` is the Zig idiom for section placement. One attribute, straightforward.
- `const` vs `var` has security-relevant consequences when the bootloader writes into your struct.
- Duplicate symbol emission from named constants is a real footgun. A magic-number constant triggering a bootloader panic is not obvious.
- Old Limine (v7.x) silently accepted broken binaries that new Limine (v11.x) correctly rejects. Always use a recent bootloader.
- The xorriso man page had the fix (`-iso-level 4`) that none of the common flags provided.
- **A blank screen is success.** No output code exists yet. The kernel is halted in `cli; hlt`. Exactly correct.

---

### What I'd do differently
- Start with `extern struct` for anything crossing an ABI boundary.
- Use `linksection` from the first draft of any protocol struct.
- Check `readelf -S` for section names before debugging bootloader behavior.
- Use the latest Limine binary from day one. Old versions hide bugs.
- Read `CONFIG.md` before writing `limine.conf`. Don't guess syntax.
- Check the man page before trying multiple flags that all fail.

---

### Verification evidence

`.requests` section in the binary:
```
[449] .requests   PROGBITS   ffffffff80141000   00042000
```

GDB session confirming `_start` is reached:
```
(gdb) target remote :1234
(gdb) break _start
Breakpoint 1 at 0xffffffff801171b0: file main.zig, line 31.
(gdb) continue
Breakpoint 1, main._start () at main.zig:31
31    asm volatile ("cli");
(gdb) next
33        asm volatile ("hlt");
(gdb) info registers rip rsp eflags
rip    0xffffffff801171b2
rsp    0xffff800007f98ff8
```

---

### Open questions
- How does Limine parse the ELF? It reads program headers, checks permissions, and validates alignment before mapping — the alignment panic proves it validates before loading.
- What is the full machine state at `_start`? The Limine spec lists it (GDT, IDT, paging, stack) but we haven't inspected it yet. Phase 3 work.
- Where does `rsp = 0xffff800007f98ff8` come from? This is Limine's provided stack. We replace it with our own in Phase 3.
- What does the HHDM offset actually resolve to at runtime? We declared the request but haven't read the response yet. Phase 2 work.
