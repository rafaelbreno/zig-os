# Phase 1 - Notes for `The Spark: Booting Into Your Kernel`

## 1.1 Understand the boot chain

### What I built
Nothing

### What I learned (concepts)

#### Boot Sequence
1. **Power On**: User presses power button
2. **Firmware Execution**: CPU executes a hardcoded JUMP instruction to a predefined address in ROM where the firmware (**BIOS** or **UEFI**) is located
3. **Hardware Init**: Firmware performs hardware test (**P**ower-**O**n **S**elf-**T**est , **POST**)
    - If this fails, the booting halts
4. **Bootloader Handoff**: The firmware loads partition table, looks for a bootable device and hands over to a bootloader (like Limine).
    - **Legacy BIOS**: Reads the first 512 bytes of the disk (**M**aster **B**oot **R**ecord, **MBR**) to find the bootloader
    - **UEFI**: Looks for a specific **FAT32** partition called the EFI System Partition (ESP) and runs a bootloader executable.
5. **Kernel Execution**: The bootloader (Limine) prepares a standardized environment (memory maps, screen framebuffers), loads the OS kernel (e.g., `kernel.elf`) into RAM, and JUMPS to the kernel's entry point to hand over control.

#### BIOS vs UEFI
**BIOS** (**B**asic **I**nput/**O**utput **S**ystem) is a firmware pre-installed on old motherboards that initializes hardware. It's constrained (e.g., 16-bit mode, limited space).

**UEFI** (**U**nified **E**xtensible **F**irmware **I**nterface) is a modern replacement for legacy BIOS with more capabilities.

#### Limine
Limine is an advanced, portable, multiprotocol bootloader that bridges the motherboard's firmware (BIOS/UEFI) and our custom OS kernel. It abstracts away the need to support both BIOS and UEFI directly.

### What surprised me

- **Hardware bootstrapping is hardwired**: The CPU physically jumps to a fixed ROM address on power-up; this is not software-configurable. The bootstrap must be embedded in hardware itself.

- **Historical constraints shape modern design**: The 512-byte MBR rule comes from ancient floppy disk sizes. Despite being obsolete, this constraint persists because firmware designers maintained backward compatibility.

- **Abstraction through standardization**: Limine's value isn't doing magic—it's answering mundane questions (Where is RAM? What mode am I in? Where is the framebuffer?) so the kernel doesn't have to. This lets us focus on kernel logic, not firmware compatibility.

- **Bootloader complexity justifies deferral**: Writing a bootloader requires 16-bit assembly, filesystem drivers, ELF parsing, and dual BIOS/UEFI support. It's a semester-long project on its own—better to use Limine and tackle it later if needed.

### Open questions
- How does Limine actually parse the ELF and know where to load sections?
- What exactly is in the "standardized environment" Limine provides?

## 1.2 The Linker Script

### What I built
A working linker script (`kernel/linker.ld`) that places the kernel as a true higher-half kernel: virtual addresses start at `0xFFFFFFFF80100000`, mapped to physical address `0x100000` (1 MiB). The script uses `AT()` directives to define the virtual→physical split and a `/DISCARD/` rule to strip unused metadata sections. Alongside it, I configured `build.zig` to disable PIE and — critically — force the LLVM backend, which is what makes the linker script actually take effect.

### What I learned (concepts)

#### Linker Script Purpose
A linker script tells the linker how to organize compiled object files into the final executable and where each section lives in memory. For OS dev it's essential: the bootloader reads the ELF program headers to load each section to the right place.

#### Virtual vs Physical Addresses
- **Virtual Address (VAddr):** where the CPU executes the code (what running code sees).
- **Physical Address (PAddr):** where the bootloader places bytes in RAM.
- Higher-half kernel: VAddr = `0xFFFFFFFF80100000+`, PAddr = `0x100000+`.
- `AT(ADDR(.section) - KERNEL_VADDR_BASE)` computes the physical address by subtracting the high-half base from the virtual address.

#### Why higher-half / why 1 MiB physical
- The kernel lives in the upper half so the lower half stays free for user space later.
- `.text` is placed at base + 1 MiB so the physical load address is `0x100000`, avoiding the low-memory regions the firmware reserves.

#### GNU Linker Script Syntax
- `ENTRY(symbol)` — sets the entry point (`_start`).
- `SECTIONS { ... }` — maps input sections to output sections and addresses.
- `.` — the location counter; the current virtual address. Assigning to it (`. = KERNEL_VADDR_TEXT;`) sets where the next section begins.
- `ALIGN(4K)` — start the section on a 4 KiB page boundary (needed so each section can later get independent page permissions).
- `AT(...)` — set the physical load address separately from the virtual address.
- `*(.text)` — wildcard collecting all `.text` input sections from every object file.
- `/DISCARD/ : { ... }` — drop matched sections from the output entirely.

#### Alignment to 4 KiB
x86_64 manages memory in 4 KiB pages, and page permissions (R/W/X) are per-page. Aligning each section to a page boundary lets `.text` be executable, `.rodata` read-only, and `.data` read-write without any section's permissions bleeding into another.

#### Position Independent Executable (PIE)
- PIE on (default): linker emits relocatable code that can run at any address; it ignores fixed addresses.
- `exe.pie = false`: linker respects the exact addresses. Required for a kernel — we *are* the OS, so there's no runtime relocator.

#### The backend is what makes linker scripts work (the big one)
- Recent Zig (including 0.16.0) **defaults to its own self-hosted x86_64 backend** instead of LLVM.
- The self-hosted backend's ELF linker has **incomplete linker-script support**: it ignores the location counter (`. = ...;`) and substitutes `--image-base`, and it doesn't resolve linker-script-defined symbols (tracked in ziglang/zig#24717).
- `exe.use_llvm = true` switches codegen to the **LLVM backend**, whose linker (LLD) honors the script properly. This is the fix.

#### compiler_rt
With the LLVM backend, `readelf` shows hundreds of `.text.compiler_rt.*` sections. These are compiler support routines (memcpy, memset, 128-bit division, software float math, oversized atomics) — primitives the CPU lacks single instructions for. They are *not* OS functionality and using them is not in tension with "from scratch" (even Linux/libgcc do this). They collapse into one clean `.text` LOAD segment; the long list is just `readelf` verbosity.

### Working configuration

`build.zig`:
```zig
exe.pie = false;       // kernel must not be PIE
exe.use_llvm = true;   // LLVM backend → linker script is honored
exe.setLinkerScript(b.path("kernel/linker.ld"));
// no image_base, no use_lld
```

### What surprised me

- **The default backend silently broke the linker script.** For hours the script was parsed and passed to the linker, yet its addresses were ignored — because the self-hosted backend's linker uses `--image-base` instead of the location counter. Nothing errored; the addresses were just wrong.
- **`use_lld` vs `use_llvm` are different things.** `use_lld` swaps only the linker; feeding self-hosted-backend output to LLD segfaulted. `use_llvm` swaps the codegen backend (and brings LLD along correctly). The fix was the backend, not the linker.
- **`image_base = 0xFFFFFFFF80000000` overflowed** the self-hosted linker — another symptom of the same incomplete support.
- **A proven reference settled it:** the Ymir hypervisor produces a perfect high-half ELF with essentially this exact linker script, because it uses the LLVM backend. That confirmed the script was fine and the backend was the variable.

### What I'd do differently

- When a linker script is parsed but ignored, suspect the **backend/linker**, not the script syntax. Check `use_llvm` early on Zig ≥ 0.14.
- Find a known-good reference project (Ymir, limine-zig) early and diff its `build.zig` against mine before deep debugging.
- Verify with `readelf -l` (program headers) from the start — it shows the real VAddr/PAddr split, which is the actual success metric.

### Verification evidence

`readelf -l build/kernel.elf` after the fix and `/DISCARD/`:
```
Entry point 0xffffffff801171b0
Type   VirtAddr             PhysAddr             Flags
LOAD   0xffffffff80100000   0x0000000000100000   R E    (.text)
LOAD   0xffffffff80140310   0x0000000000140310   RW     (.data)
LOAD   0xffffffff80141000   0x0000000000141000   RW     (.bss)
```

Three clean LOAD segments; virtual addresses in the higher half, physical at 1 MiB; entry point inside `.text`. Exactly the intended layout.

### Open questions (resolved + deferred)

- **RESOLVED — higher-half mapping on Zig 0.16.0/macOS:** earlier I believed this was impossible and had to be deferred to Phase 6. That was wrong. The cause was the default self-hosted backend (ziglang/zig#24717); `exe.use_llvm = true` fixes it. The kernel is now correctly higher-half from the start.
- **Possible bug to report:** `exe.use_lld = true` (with the self-hosted backend) produced a hard SEGV rather than a clean error. A crash is arguably a real bug worth filing on Codeberg, separate from the known #24717.
- **Deferred (Phase 14 polish):** the bundled `compiler_rt` includes many functions the kernel never calls. Link-time section GC (~`exe.link_gc_sections = true`, verify the exact field) could strip the unused ones. Purely a size concern; not needed now.
