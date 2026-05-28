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

## 1.2 The linker script.

### What I built
<one paragraph>

### What I learned (concepts)

#### Linker Script
A _Linker Script_ principal use is specifying the format and layout of the final executable binary, this is relevant to OS dev because executable binaries often require specific file layouts in order to be recognized by certain bootloaders.

#### Linker
The Linker combines input files into a single output file.

#### `ld` Syntax

##### Keywords:
- **ENTRY**:
    - Defines the entry point of an application
    - ```
      ENTRY(_start)
      ```
- **SECTIONS**:
    - Tells the linker how to map input sections into output sections, and how to place the output sections in memory.
    - ```
      SECTIONS
      {
          sections - command
          sections - command
      }
      ```
    - Where `sections - command`
- ****:
- ****:

### What surprised me
<things that didn't match the docs, or that took me hours to figure out>

### What I'd do differently
<honest postmortem>

### Verification evidence
<screenshots, serial logs, gdb sessions>

### Open questions
<things I deferred — return to these later>
