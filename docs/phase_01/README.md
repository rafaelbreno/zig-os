# Phase 1 — The Spark: Booting Into Your Kernel

**Goal of this phase:** When you press "play" in QEMU, *your code runs*. Nothing more — but that "nothing more" is everything.

## 1.1 Understand the boot chain

- [x] **Study how an x86_64 PC boots**
  - **Why:** You need to know what hands control to whom. Power → firmware → bootloader → your kernel.
  - **Study:** BIOS vs UEFI. POST. The role of the bootloader. Why we don't write our own bootloader (yet).
  - **What:** Read OSDev Wiki: "Boot Sequence", "Limine".
  - **Verify:** You can draw the boot chain on paper.
  - **Notes:**

- [x] **Study the Limine boot protocol**
  - **Why:** Limine is modern, simple, supports both BIOS and UEFI, and gives your kernel a clean handoff with a memory map already prepared.
  - **Study:** Limine boot protocol specification (request/response model, what info it provides).
  - **What:** Read the Limine protocol docs end-to-end once.
  - **Verify:** You can list three things Limine gives you (memory map, framebuffer, kernel virtual address, HHDM, etc.).
  - **Notes:**

## 1.2 The linker script

- [x] **Study linker scripts**
  - **Why:** The linker decides *where* each part of your kernel lives in memory. The bootloader expects specific addresses.
  - **Study:** GNU `ld` script syntax. `SECTIONS`, `ENTRY`, `PROVIDE`, alignment, the `.` location counter.
  - **What:** Read examples of minimal kernel linker scripts.
  - **Verify:** You can explain what `. = ALIGN(4K);` does.
  - **Notes:**

- [x] **Write `linker.ld`**
  - **Why:** Without this, your sections land at unpredictable addresses and the bootloader can't find anything.
  - **What:** Define `ENTRY(_start)`. Place `.text`, `.rodata`, `.data`, `.bss` at a high-half virtual address (`0xFFFFFFFF80000000`). Align each section to 4K.
  - **Verify:** `readelf -l zig-out/bin/kernel.elf` shows program headers at the addresses you specified.
  - **Notes:**

- [ ] **Wire the linker script into `build.zig`**
  - **Why:** Zig needs to know to use your custom script.
  - **What:** Pass `-T linker.ld` (or the Zig equivalent: `setLinkerScript`).
  - **Verify:** Rebuild — addresses in `readelf` now match your script.
  - **Notes:**

## 1.3 Limine boot setup

- [ ] **Add Limine requests to your kernel**
  - **Why:** Limine only gives you the information you ask for. You request features via specially-marked structs in your binary.
  - **Study:** Limine "requests" — how they work, why they're put in a dedicated `.requests` section.
  - **What:** Add a base revision marker and a framebuffer request to your kernel. Put them in a `.requests` section in the linker script.
  - **Verify:** `readelf -S` shows the `.requests` section in your ELF.
  - **Notes:**

- [ ] **Write `limine.conf`**
  - **Why:** Limine reads this to know which kernel to load.
  - **What:** Create a boot entry pointing to `boot:///kernel.elf` with protocol `limine`.
  - **Verify:** The file syntax matches the Limine docs.
  - **Notes:**

- [ ] **Update `_start` to halt cleanly**
  - **Why:** "Looping forever" with `while(true)` wastes CPU and is harder to spot in QEMU. `cli; hlt` is the canonical "kernel is alive and waiting" pose.
  - **Study:** What `cli` and `hlt` do at the CPU level. Why interrupts must be disabled before halt.
  - **What:** Replace your infinite loop with inline assembly: `cli`, then a loop of `hlt`.
  - **Verify:** Compile and check the disassembly — you see `cli` and `hlt` instructions.
  - **Notes:**

## 1.4 Build the bootable ISO

- [ ] **Add ISO build steps to `build.zig`**
  - **Why:** Automating this means you can iterate fast. Manual steps will exhaust you.
  - **Study:** Limine's "How to install" instructions. The role of `limine-bios.sys`, `limine-uefi-cd.bin`, and `limine bios-install`.
  - **What:** Add a `zig build iso` step that: copies the kernel + Limine binaries + config into a staging folder, runs `xorriso` to make the ISO, runs `limine bios-install` to make it bootable.
  - **Verify:** `zig build iso` produces `os.iso` in `zig-out/`.
  - **Notes:**

- [ ] **Add a `zig build run` step**
  - **Why:** One command to build and boot. Critical for fast iteration.
  - **What:** Add a step that runs `qemu-system-x86_64 -cdrom zig-out/os.iso -serial stdio -no-reboot -no-shutdown`.
  - **Verify:** `zig build run` launches QEMU.
  - **Notes:**

- [ ] **Boot your kernel for the first time**
  - **Why:** This is the milestone moment.
  - **What:** Run `zig build run`.
  - **Verify:** QEMU shows a black screen (or the Limine logo briefly) and stays running. No reboots. No "no bootable device" errors.
  - **Notes:**

## Phase 1 Milestone

QEMU boots, Limine runs, and your kernel reaches `cli; hlt`. You have proven your toolchain works end-to-end. Take a screenshot.

## Phase 1 Debug Checkpoint

- [ ] **Add a GDB build step**
  - **What:** Add a `zig build debug` step that runs QEMU with `-s -S` (gdb server, paused at start).
  - **Verify:** Connect with `gdb zig-out/bin/kernel.elf` then `target remote :1234`. Set a breakpoint at `_start`. Type `continue`. GDB stops at your entry point.

- [ ] **Use the QEMU monitor**
  - **What:** Run QEMU with `-monitor stdio`. Press `Ctrl+A, C` (or open the monitor in the GUI). Try `info registers`, `info mem`, `x/10i $rip`.
  - **Verify:** You can read your kernel's instruction pointer (`RIP`) and see it pointing at the `hlt` loop.
  - **Notes:**

- [ ] Write up in your notes: "What is the exact sequence of events from power-on to `_start`?"

---
