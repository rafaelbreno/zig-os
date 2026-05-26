# Phase 0 — The Sandbox: Tooling, Emulation, and Your First ELF

**Goal of this phase:** Have a build pipeline you trust. You will produce many broken binaries before you produce a working OS; if you can't trust your tools, you can't trust your debugging.

## 0.1 Install the toolchain

- [x] **Install Zig 0.16.0**
  - **Why:** Zig is your only compiler. Version matters — `build.zig` APIs shift between minor versions.
  - **Study:** Zig release notes for 0.16.0 (focus on `build.zig` API changes).
  - **What:** Download Zig 0.16.0, add to `PATH`, run `zig version`.
  - **Verify:** `zig version` prints `0.16.0`.
  - **Notes:**
    - Currently I installed on MacOS using `brew`

- [x] **Install QEMU**
  - **Why:** You will *never* test on real hardware first. QEMU emulates a full x86_64 machine, lets you pause it, inspect registers, and reboot in milliseconds.
  - **Study:** Difference between emulation (QEMU) and virtualization (KVM). Why QEMU is preferred for early OS dev.
  - **What:** Install `qemu-system-x86_64`. On Arch: `sudo pacman -S qemu-full`.
  - **Verify:** `qemu-system-x86_64 --version` prints a version.
  - **Notes:**
    - Currently I installed on MacOS using `brew`

- [x] **Install GDB with multi-arch support**
  - **Why:** GDB attached to QEMU is your X-ray machine. You'll use it from Phase 1 onward.
  - **Study:** What "remote debugging" means. The role of `gdbserver`.
  - **What:** Install `gdb` (Arch package: `gdb`). Confirm it lists `i386:x86-64` as a target.
  - **Verify:** `gdb -ex "set architecture i386:x86-64" -ex "quit"` exits cleanly.
  - **Notes:**
    - Installed on MacOS using `brew`

- [x] **Install ISO/disk image tools**
  - **Why:** Bootable media is how Limine and QEMU hand off to your kernel.
  - **Study:** What an ISO 9660 image is. The role of `xorriso`.
  - **What:** Install `xorriso` and `mtools` (Limine needs both).
  - **Verify:** `xorriso --version` prints a version.
  - **Notes:**
    - Installed on MacOS using `brew`

## 0.2 Understand the build target

- [ ] **Study freestanding targets**
  - **Why:** Your kernel runs *before* any OS exists. There is no `libc`, no syscalls, no `printf`. "Freestanding" is the compiler mode for this.
  - **Study:** What "freestanding" means in compiler terms. The difference between `x86_64-linux-gnu` and `x86_64-freestanding-none`.
  - **What:** Read Zig docs on target triples and `std.Target`.
  - **Verify:** You can explain in one sentence why your kernel can't use `std.io`.
  - **Notes:**

- [ ] **Study ELF basics**
  - **Why:** Your compiler outputs an ELF file. The bootloader reads ELF headers to load your kernel into memory.
  - **Study:** ELF sections (`.text`, `.data`, `.bss`, `.rodata`). Program headers vs section headers. What `readelf` shows.
  - **What:** Pick any compiled binary and run `readelf -a` on it. Identify each section.
  - **Verify:** You can name what each of the four sections above holds.
  - **Notes:**

## 0.3 First freestanding build

- [ ] **Create the project skeleton**
  - **Why:** A predictable directory layout saves hours later.
  - **What:** Create `kernel/`, `boot/`, `build/`. Inside `kernel/`, create `src/main.zig`.
  - **Verify:** `tree .` shows your structure.
  - **Notes:**

- [ ] **Write a minimal `main.zig`**
  - **Why:** Start with the smallest thing that compiles for a freestanding target.
  - **What:** Define an exported function `_start` that loops forever (`while (true) {}`).
  - **Verify:** The file is under 10 lines.
  - **Notes:**

- [ ] **Write `build.zig` for freestanding x86_64**
  - **Why:** This file is how you control the compiler. Get it right once.
  - **Study:** `std.Build`, `addExecutable`, `setTarget`, `code_model`, `red_zone`.
  - **What:** Configure the target as `x86_64-freestanding-none`. Disable the red zone. Set the code model to `.kernel`. Disable SIMD/SSE for now.
  - **Verify:** `zig build` succeeds and produces an ELF file under `zig-out/`.
  - **Notes:**

- [ ] **Inspect your output**
  - **Why:** Trust but verify. Look at what the compiler produced.
  - **What:** Run `readelf -h zig-out/bin/kernel.elf` and `objdump -d zig-out/bin/kernel.elf`.
  - **Verify:** You can find `_start` in the disassembly and it's a simple infinite loop.
  - **Notes:**

## Phase 0 Milestone

You can run `zig build` and reliably produce an ELF kernel binary. You can read its assembly and find your `_start` function.

## Phase 0 Debug Checkpoint

- [ ] Practice using `readelf -S` to list sections.
- [ ] Practice using `objdump -d --disassembler-color=on` to read x86_64 assembly.
- [ ] Bookmark the OSDev Wiki page on "Bare Bones" and "Beginner Mistakes".
- [ ] Open a notebook or `docs/` folder. From this point forward, write down every weird thing you encounter.

---

## What I built
<one paragraph>

## What I learned (concepts)
- Concept 1: <my explanation, not copy-pasted>
- Concept 2: ...

## What surprised me
<things that didn't match the docs, or that took me hours to figure out>

## What I'd do differently
<honest postmortem>

## Verification evidence
<screenshots, serial logs, gdb sessions>

## Open questions
<things I deferred — return to these later>
