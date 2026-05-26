# Building a 64-bit x86_64 Operating System in Zig 0.16.0

## A Progressive Roadmap from Zero to a Working OS

> [!IMPORTANT]
> **How to use this roadmap**
>
> Each task follows the same structure:
> - **Why** — the concept behind it and what to go study
> - **What** — the concrete action to take
> - **Verify** — how to *see* it working (no working in the dark)
> - **Notes** — a blank space for you to write your own documentation as you go
>
> Every phase ends with a **Milestone** (a visible, demonstrable result) and a **Debug Checkpoint** (tools and techniques to inspect what's happening). Don't skip the debug checkpoints — they are how you keep your sanity.
>
> Study pointers are intentionally short. The roadmap tells you *what* to learn and *why you need it*, not the full theory. Use OSDev Wiki, Intel SDM Vol. 3, and the Zig source as your study companions.

---

## Phase 0 — The Sandbox: Tooling, Emulation, and Your First ELF

**Goal of this phase:** Have a build pipeline you trust. You will produce many broken binaries before you produce a working OS; if you can't trust your tools, you can't trust your debugging.

### 0.1 Install the toolchain

- [ ] **Install Zig 0.16.0**
  - **Why:** Zig is your only compiler. Version matters — `build.zig` APIs shift between minor versions.
  - **Study:** Zig release notes for 0.16.0 (focus on `build.zig` API changes).
  - **What:** Download Zig 0.16.0, add to `PATH`, run `zig version`.
  - **Verify:** `zig version` prints `0.16.0`.
  - **Notes:**

- [ ] **Install QEMU**
  - **Why:** You will *never* test on real hardware first. QEMU emulates a full x86_64 machine, lets you pause it, inspect registers, and reboot in milliseconds.
  - **Study:** Difference between emulation (QEMU) and virtualization (KVM). Why QEMU is preferred for early OS dev.
  - **What:** Install `qemu-system-x86_64`. On Arch: `sudo pacman -S qemu-full`.
  - **Verify:** `qemu-system-x86_64 --version` prints a version.
  - **Notes:**

- [ ] **Install GDB with multi-arch support**
  - **Why:** GDB attached to QEMU is your X-ray machine. You'll use it from Phase 1 onward.
  - **Study:** What "remote debugging" means. The role of `gdbserver`.
  - **What:** Install `gdb` (Arch package: `gdb`). Confirm it lists `i386:x86-64` as a target.
  - **Verify:** `gdb -ex "set architecture i386:x86-64" -ex "quit"` exits cleanly.
  - **Notes:**

- [ ] **Install ISO/disk image tools**
  - **Why:** Bootable media is how Limine and QEMU hand off to your kernel.
  - **Study:** What an ISO 9660 image is. The role of `xorriso`.
  - **What:** Install `xorriso` and `mtools` (Limine needs both).
  - **Verify:** `xorriso --version` prints a version.
  - **Notes:**

### 0.2 Understand the build target

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

### 0.3 First freestanding build

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

### Phase 0 Milestone

You can run `zig build` and reliably produce an ELF kernel binary. You can read its assembly and find your `_start` function.

### Phase 0 Debug Checkpoint

- [ ] Practice using `readelf -S` to list sections.
- [ ] Practice using `objdump -d --disassembler-color=on` to read x86_64 assembly.
- [ ] Bookmark the OSDev Wiki page on "Bare Bones" and "Beginner Mistakes".
- [ ] Open a notebook or `docs/` folder. From this point forward, write down every weird thing you encounter.

---

## Phase 1 — The Spark: Booting Into Your Kernel

**Goal of this phase:** When you press "play" in QEMU, *your code runs*. Nothing more — but that "nothing more" is everything.

### 1.1 Understand the boot chain

- [ ] **Study how an x86_64 PC boots**
  - **Why:** You need to know what hands control to whom. Power → firmware → bootloader → your kernel.
  - **Study:** BIOS vs UEFI. POST. The role of the bootloader. Why we don't write our own bootloader (yet).
  - **What:** Read OSDev Wiki: "Boot Sequence", "Limine".
  - **Verify:** You can draw the boot chain on paper.
  - **Notes:**

- [ ] **Study the Limine boot protocol**
  - **Why:** Limine is modern, simple, supports both BIOS and UEFI, and gives your kernel a clean handoff with a memory map already prepared.
  - **Study:** Limine boot protocol specification (request/response model, what info it provides).
  - **What:** Read the Limine protocol docs end-to-end once.
  - **Verify:** You can list three things Limine gives you (memory map, framebuffer, kernel virtual address, HHDM, etc.).
  - **Notes:**

### 1.2 The linker script

- [ ] **Study linker scripts**
  - **Why:** The linker decides *where* each part of your kernel lives in memory. The bootloader expects specific addresses.
  - **Study:** GNU `ld` script syntax. `SECTIONS`, `ENTRY`, `PROVIDE`, alignment, the `.` location counter.
  - **What:** Read examples of minimal kernel linker scripts.
  - **Verify:** You can explain what `. = ALIGN(4K);` does.
  - **Notes:**

- [ ] **Write `linker.ld`**
  - **Why:** Without this, your sections land at unpredictable addresses and the bootloader can't find anything.
  - **What:** Define `ENTRY(_start)`. Place `.text`, `.rodata`, `.data`, `.bss` at a high-half virtual address (`0xFFFFFFFF80000000`). Align each section to 4K.
  - **Verify:** `readelf -l zig-out/bin/kernel.elf` shows program headers at the addresses you specified.
  - **Notes:**

- [ ] **Wire the linker script into `build.zig`**
  - **Why:** Zig needs to know to use your custom script.
  - **What:** Pass `-T linker.ld` (or the Zig equivalent: `setLinkerScript`).
  - **Verify:** Rebuild — addresses in `readelf` now match your script.
  - **Notes:**

### 1.3 Limine boot setup

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

### 1.4 Build the bootable ISO

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

### Phase 1 Milestone

QEMU boots, Limine runs, and your kernel reaches `cli; hlt`. You have proven your toolchain works end-to-end. Take a screenshot.

### Phase 1 Debug Checkpoint

- [ ] **Add a GDB build step**
  - **What:** Add a `zig build debug` step that runs QEMU with `-s -S` (gdb server, paused at start).
  - **Verify:** Connect with `gdb zig-out/bin/kernel.elf` then `target remote :1234`. Set a breakpoint at `_start`. Type `continue`. GDB stops at your entry point.

- [ ] **Use the QEMU monitor**
  - **What:** Run QEMU with `-monitor stdio`. Press `Ctrl+A, C` (or open the monitor in the GUI). Try `info registers`, `info mem`, `x/10i $rip`.
  - **Verify:** You can read your kernel's instruction pointer (`RIP`) and see it pointing at the `hlt` loop.
  - **Notes:**

- [ ] Write up in your notes: "What is the exact sequence of events from power-on to `_start`?"

---

## Phase 2 — Finding Your Voice: Output (and Why It Matters First)

**Goal of this phase:** Two independent ways to see what your kernel is doing — a serial port (text to your host terminal) and a framebuffer (pixels on the screen). Output before everything else, because debugging without output is suffering.

> Note on VGA text mode: the original roadmap used `0xB8000`. Modern Limine-booted kernels run in long mode with a graphical framebuffer, not VGA text mode. We will use the framebuffer instead — it's more useful and more honest about how real systems work. The serial port comes *first* because it works even when the framebuffer is broken.

### 2.1 Serial output (do this first)

- [ ] **Study x86 port I/O**
  - **Why:** Many legacy devices (including the serial port) are controlled through I/O ports, a separate address space from memory.
  - **Study:** `in`/`out` instructions. Port addresses for COM1 (`0x3F8`). The 8250/16550 UART.
  - **What:** Read OSDev Wiki: "Serial Ports".
  - **Verify:** You can list the offsets for the data register, line status register, and line control register.
  - **Notes:**

- [ ] **Write port I/O wrappers in Zig**
  - **Why:** You'll use `inb`/`outb` from dozens of places. Wrap them once.
  - **Study:** Zig inline assembly syntax (`asm volatile`, output/input/clobber).
  - **What:** Create `src/arch/x86_64/port.zig` with `outb`, `inb`, `outw`, `inw`, `outl`, `inl`.
  - **Verify:** Code compiles. Inspect generated assembly with `objdump` to confirm real `in`/`out` instructions.
  - **Notes:**

- [ ] **Initialize COM1**
  - **Why:** Without initialization the UART won't transmit.
  - **Study:** UART init sequence: disable interrupts, set DLAB, set baud divisor, set 8N1, enable FIFO, set DTR/RTS.
  - **What:** Create `src/drivers/serial.zig` with `init()`.
  - **Verify:** After calling `init()`, the loopback test (set bit 4 of MCR, write byte, read back) succeeds.
  - **Notes:**

- [ ] **Implement `writeByte` and `writeString`**
  - **Why:** This is your first real output.
  - **What:** Add functions that poll the Line Status Register's "transmitter empty" bit, then write a byte to the data register.
  - **Verify:** Call `serial.writeString("Hello from kernel!\n")` from `_start`. Run with `-serial stdio`. Text appears in your terminal.
  - **Notes:**

- [ ] **Hook serial into Zig's `std.fmt`**
  - **Why:** You want `print("value = {}\n", .{x})` to work. This is huge for debugging.
  - **Study:** `std.fmt.format`, the `Writer` interface, how to satisfy it without `std.io`.
  - **What:** Create a minimal `Writer` that calls `serial.writeByte`. Wrap `std.fmt.format` in a `print` function.
  - **Verify:** `print("hex: {x}, dec: {d}\n", .{0xDEAD, 42})` outputs correctly to your terminal.
  - **Notes:**

### 2.2 Framebuffer output

- [ ] **Read Limine's framebuffer response**
  - **Why:** Limine has already set up a linear framebuffer for you in long mode. You just need the pointer, width, height, and pitch.
  - **Study:** Limine's framebuffer request/response structures. What "pitch" means (it's not always `width * bpp`).
  - **What:** Access the response from your framebuffer request. Print its width, height, pitch, and address to serial.
  - **Verify:** Serial shows reasonable values (e.g., 1024x768, pitch 4096).
  - **Notes:**

- [ ] **Paint your first pixel**
  - **Why:** Smallest possible framebuffer test.
  - **What:** Write a 32-bit color value to `framebuffer[0]`.
  - **Verify:** A single colored dot appears at the top-left of the QEMU window.
  - **Notes:**

- [ ] **Fill the screen with a color**
  - **Why:** Confirms you understand pitch and dimensions.
  - **What:** Loop over every pixel using `y * pitch + x * 4` indexing.
  - **Verify:** QEMU shows a solid color across the whole window.
  - **Notes:**

- [ ] **Embed a bitmap font**
  - **Why:** Drawing text requires glyph data. Don't write your own — use a standard PSF font or an 8x8 ROM font.
  - **Study:** The PSF1/PSF2 font formats, or just a public-domain 8x8 bitmap font header.
  - **What:** Add a font file to your project. Embed it with `@embedFile`.
  - **Verify:** You can index into the font and get the bitmap for the letter `A`.
  - **Notes:**

- [ ] **Draw a single glyph**
  - **Why:** Verifies your font logic before building a full console.
  - **What:** Write `drawChar(c, x, y, fg, bg)`. For each bit in the glyph, write a pixel.
  - **Verify:** The letter `A` appears on the screen.
  - **Notes:**

- [ ] **Build a console abstraction**
  - **Why:** You want `console.print("...")` to work like serial does.
  - **What:** Track cursor position. Implement `putChar` with `\n` handling. Wrap `std.fmt.format` over it.
  - **Verify:** Multi-line text prints correctly across the screen.
  - **Notes:**

- [ ] **Implement scrolling**
  - **Why:** Once the screen fills up, you need to shift content up.
  - **What:** When the cursor reaches the bottom, copy each row's memory up by one row height; clear the last row.
  - **Verify:** Print 100 lines in a loop — text scrolls smoothly.
  - **Notes:**

### 2.3 Unify your output

- [ ] **Build a single `log` module**
  - **Why:** You want every important event to appear in *both* serial and framebuffer. Serial is for post-mortem analysis; framebuffer is for live feel.
  - **What:** Create `src/log.zig` with `info`, `warn`, `err` functions that write to both sinks with a prefix.
  - **Verify:** `log.info("kernel booted at {x}", .{addr})` shows in QEMU's window *and* your host terminal.
  - **Notes:**

### Phase 2 Milestone

Your kernel prints colored, formatted log lines to both the QEMU window and your host terminal. You can `print` any integer in hex or decimal. You will never feel "in the dark" again.

### Phase 2 Debug Checkpoint

- [ ] Print every Limine response struct's contents at boot. Confirm sane values.
- [ ] Print your kernel's load address. Compare it to your linker script's expected address.
- [ ] In GDB, set a breakpoint on `serial.writeByte` and step through one character's worth of output.
- [ ] Write up: "How does `std.fmt.format` route from my `print()` to the UART data register?"

---

## Phase 3 — CPU Foundations: GDT, IDT, and Catching Crashes

**Goal of this phase:** When something goes wrong (and it will, daily), you see a crash dump instead of a silent reboot.

### 3.1 The Global Descriptor Table (GDT)

- [ ] **Study segmentation in long mode**
  - **Why:** In 64-bit mode, segmentation is mostly disabled — but the CPU still requires a GDT with valid descriptors to function.
  - **Study:** GDT entry format, segment selectors, code/data segments, the `L` (long mode) bit, why `CS` and `SS` still matter.
  - **What:** Read OSDev Wiki: "Global Descriptor Table".
  - **Verify:** You can describe what each field of a 64-bit code segment descriptor does.
  - **Notes:**

- [ ] **Define GDT structs**
  - **Why:** Zig's `packed struct` is your friend here.
  - **Study:** `packed struct`, bit layout, endianness on x86.
  - **What:** Create `src/arch/x86_64/gdt.zig`. Define `Entry` and `Ptr` (the GDTR descriptor).
  - **Verify:** `@sizeOf(Entry) == 8` and `@sizeOf(Ptr) == 10`.
  - **Notes:**

- [ ] **Build a minimal GDT**
  - **Why:** Limine gives you a working GDT, but it's good practice (and necessary later for the TSS) to install your own.
  - **What:** Define entries: null, kernel code, kernel data. Place in a global array.
  - **Verify:** Print each entry's raw bytes via serial; values match Intel docs.
  - **Notes:**

- [ ] **Load the GDT**
  - **Why:** `lgdt` tells the CPU about your new table. A "far jump" or far return after is required to refresh segment caches.
  - **Study:** `lgdt` instruction. Why a far jump is needed. How to do a far return in 64-bit mode.
  - **What:** Write inline assembly to `lgdt`, then reload `CS` via a far return and reload `DS/ES/FS/GS/SS` with the new data selector.
  - **Verify:** Print `CS` and `DS` selector values before and after. They change to your new selectors.
  - **Notes:**

### 3.2 The Interrupt Descriptor Table (IDT)

- [ ] **Study x86_64 interrupts**
  - **Why:** Every CPU exception (divide by zero, page fault, etc.) and every hardware interrupt needs an entry in the IDT.
  - **Study:** IDT entry format (interrupt gate vs trap gate), the IST mechanism, exceptions 0-31 (memorize the important ones: #0 #6 #8 #13 #14).
  - **What:** Read OSDev Wiki: "Interrupt Descriptor Table" and "Exceptions".
  - **Verify:** You can list what exceptions 13 (#GP) and 14 (#PF) mean.
  - **Notes:**

- [ ] **Define IDT structs**
  - **What:** Create `src/arch/x86_64/idt.zig`. Define `Entry` (16 bytes in long mode) and `Ptr`.
  - **Verify:** `@sizeOf(Entry) == 16`.
  - **Notes:**

- [ ] **Build the interrupt stub generator**
  - **Why:** Each of the 256 IDT entries needs an assembly stub that saves registers and calls a common Zig handler. Hand-writing 256 stubs is unrealistic; you generate them with macros or `comptime`.
  - **Study:** Zig `comptime` and inline assembly. The x86_64 SysV ABI for what registers must be saved.
  - **What:** Define an `InterruptFrame` struct (the layout the CPU pushes + what you push). Write a `comptime` loop that emits a naked stub for each vector. Each stub pushes a dummy error code if the CPU didn't, pushes the vector number, then jumps to a common handler.
  - **Verify:** `objdump -d` shows 256 distinct stubs.
  - **Notes:**

- [ ] **Write the common handler**
  - **Why:** This is where Zig takes over. You receive the frame, decide what to do.
  - **What:** Write a `interruptDispatch(frame: *InterruptFrame)` Zig function. For now, for exceptions 0-31, print the vector, error code, RIP, RSP, RFLAGS, and CR2 (for #PF), then halt.
  - **Verify:** The function compiles and is exported.
  - **Notes:**

- [ ] **Load the IDT**
  - **What:** Populate the 256 entries with pointers to your stubs. Call `lidt`.
  - **Verify:** Print the IDTR via `sidt` after loading. Values match.
  - **Notes:**

### 3.3 Test your safety net

- [ ] **Trigger a divide-by-zero**
  - **Why:** Confirms exception delivery works.
  - **What:** Inline assembly: `xor rdx, rdx; xor rcx, rcx; div rcx`.
  - **Verify:** Your handler prints "Exception #0: Divide Error" with register dump. No QEMU reboot.
  - **Notes:**

- [ ] **Trigger a #UD (invalid opcode)**
  - **What:** Inline assembly: `ud2`.
  - **Verify:** Handler prints "Exception #6: Invalid Opcode".
  - **Notes:**

- [ ] **Trigger a #PF (page fault)**
  - **What:** Dereference address `0xDEADBEEFDEAD`.
  - **Verify:** Handler prints "Exception #14: Page Fault" and the faulting address (from CR2) matches.
  - **Notes:**

### Phase 3 Milestone

Any CPU exception now produces a readable crash dump on screen and serial. No more silent reboots.

### Phase 3 Debug Checkpoint

- [ ] In QEMU monitor, run `info registers` after a crash. Confirm RIP matches your dump.
- [ ] Use `-d int,cpu_reset` in QEMU to see the *emulator's* view of exceptions. Compare to your handler's view.
- [ ] Write a deliberately bad program that hits 3-4 different exceptions in sequence; verify each is caught.
- [ ] Write up: "Walk through one interrupt from CPU detection to your Zig dispatcher."

---

## Phase 4 — Hardware Interrupts: Timer, Keyboard, and Time Itself

**Goal of this phase:** Your kernel can react to the outside world. You can type. Time passes.

### 4.1 The legacy PIC (start here, then upgrade)

- [ ] **Study the 8259 PIC**
  - **Why:** The PIC routes hardware IRQs (timer, keyboard, etc.) to the CPU. Real systems use the APIC, but the PIC is simpler — start here, switch to APIC in Phase 4.4.
  - **Study:** PIC initialization (the 4 ICW bytes). IRQ-to-vector mapping. Why default vectors conflict with CPU exceptions.
  - **What:** Read OSDev Wiki: "8259 PIC".
  - **Verify:** You can list which IRQ goes to which device (IRQ0 = PIT, IRQ1 = keyboard).
  - **Notes:**

- [ ] **Remap the PIC**
  - **Why:** Default IRQ vectors (8-15) collide with CPU exceptions. Move them to 32-47.
  - **What:** Send ICW1-4 to ports `0x20/0x21` (master) and `0xA0/0xA1` (slave). Mask all IRQs initially.
  - **Verify:** Print PIC mask registers — all bits set (all masked).
  - **Notes:**

- [ ] **Wire IRQ handlers into the IDT**
  - **What:** For vectors 32-47, install handlers that call your dispatcher and then send EOI to the PIC.
  - **Verify:** Code path compiles; no IRQs unmasked yet.
  - **Notes:**

### 4.2 The PIT (your first ticking clock)

- [ ] **Study the 8253/8254 PIT**
  - **Why:** The PIT is the simplest way to get a periodic timer. Configure once, fires forever.
  - **Study:** PIT modes (especially mode 2 and mode 3), how to compute the divisor for a target frequency.
  - **What:** Read OSDev Wiki: "Programmable Interval Timer".
  - **Verify:** You can compute the divisor for 100 Hz (~11932).
  - **Notes:**

- [ ] **Configure the PIT for 100 Hz**
  - **Why:** Start slow. 1000 Hz can be too fast for early debugging.
  - **What:** Write to PIT ports (`0x40-0x43`) to set mode 3 at 100 Hz.
  - **Verify:** Code runs without faulting.
  - **Notes:**

- [ ] **Install a PIT handler**
  - **What:** On IRQ0, increment a `ticks` counter. Log `ticks` every 100 ticks.
  - **Verify:** Unmask IRQ0 on the PIC. Enable interrupts (`sti`). You see "ticks: 100" once per second on serial.
  - **Notes:**

### 4.3 The keyboard

- [ ] **Study the PS/2 keyboard**
  - **Why:** QEMU emulates a PS/2 keyboard regardless of your host. Scancodes come in via port `0x60`.
  - **Study:** PS/2 controller, scancode set 1 vs 2, make/break codes.
  - **What:** Read OSDev Wiki: "PS/2 Keyboard".
  - **Verify:** You can describe what happens when you press and release the `A` key.
  - **Notes:**

- [ ] **Install a keyboard handler**
  - **What:** On IRQ1, read port `0x60`, log the raw scancode.
  - **Verify:** Type in QEMU — raw scancodes log to serial.
  - **Notes:**

- [ ] **Build a scancode-to-ASCII map**
  - **What:** Create a lookup table for scancode set 1, lowercase only.
  - **Verify:** Pressing keys prints letters to the console.
  - **Notes:**

- [ ] **Add modifier state**
  - **What:** Track shift, ctrl, alt press/release. Handle uppercase, basic symbols.
  - **Verify:** Shift+A produces `A`, not `a`.
  - **Notes:**

- [ ] **Build a keyboard event ring buffer**
  - **Why:** You don't want your IRQ handler doing heavy work. It posts events to a buffer; consumers drain it later.
  - **What:** Implement a fixed-size circular buffer of `KeyEvent`. IRQ enqueues; a `pollKey()` API dequeues.
  - **Verify:** Buffer doesn't drop keys under fast typing.
  - **Notes:**

### 4.4 Upgrade: LAPIC and IOAPIC

> Don't skip this. Multitasking, SMP, and modern timers all require the APIC.

- [ ] **Study the LAPIC and IOAPIC**
  - **Why:** PIC is single-CPU and legacy. APIC is per-CPU and is what real systems use.
  - **Study:** LAPIC registers, IOAPIC redirection entries, MSI basics, the role of ACPI in finding them.
  - **What:** Read OSDev Wiki: "APIC".
  - **Verify:** You can explain the difference between LAPIC and IOAPIC.
  - **Notes:**

- [ ] **Find the LAPIC base**
  - **Why:** ACPI's MADT table tells you where the LAPIC and IOAPICs are mapped.
  - **Study:** ACPI RSDP/XSDT/MADT tables. (Limine provides the RSDP address.)
  - **What:** Walk ACPI tables, find MADT, parse LAPIC and IOAPIC entries.
  - **Verify:** Log the LAPIC base address.
  - **Notes:**

- [ ] **Disable the PIC, enable the LAPIC**
  - **What:** Mask all IRQs on both PICs. Enable LAPIC via its spurious interrupt vector register.
  - **Verify:** PIT interrupts stop (until you redirect via IOAPIC).
  - **Notes:**

- [ ] **Route keyboard IRQ through the IOAPIC**
  - **What:** Program the IOAPIC redirection entry for IRQ1 → vector 33 → your LAPIC.
  - **Verify:** Typing works again, now via APIC.
  - **Notes:**

- [ ] **Set up the LAPIC timer**
  - **Why:** Replaces the PIT for scheduling. Per-CPU, much higher resolution.
  - **Study:** LAPIC timer modes (one-shot, periodic, TSC-deadline). Calibrating against the PIT or HPET.
  - **What:** Calibrate the LAPIC timer using the PIT for a known interval, then set it to periodic mode at 1000 Hz.
  - **Verify:** Your `ticks` counter now advances via the LAPIC timer.
  - **Notes:**

### Phase 4 Milestone

Your kernel is "alive" — time passes, keys are received, and you've upgraded from legacy PIC to APIC. You can type at a prompt.

### Phase 4 Debug Checkpoint

- [ ] Add a `uptime` log line printed every 5 seconds. Confirm steady cadence.
- [ ] Print every IRQ as it fires (toggle with a flag for noise control).
- [ ] Use QEMU's `-d int` to compare interrupt deliveries against your logs.
- [ ] Write up: "The path of one keystroke: from QEMU's PS/2 model to my ring buffer."

---

## Phase 5 — Physical Memory: Counting the RAM

**Goal of this phase:** Know what RAM exists, what's safe to touch, and be able to hand out 4 KiB physical frames on demand.

### 5.1 Read the memory map

- [ ] **Study how the bootloader describes memory**
  - **Why:** RAM is full of forbidden regions: firmware reserved, ACPI, MMIO. You can only use "usable" entries.
  - **Study:** Limine's memory map entry types. The difference between physical addresses, virtual addresses, and Limine's HHDM offset.
  - **What:** Read OSDev Wiki: "Detecting Memory" and Limine's memory map protocol.
  - **Verify:** You can list all entry types.
  - **Notes:**

- [ ] **Print the memory map**
  - **What:** Add a memory map request to your Limine setup. Loop and log every entry.
  - **Verify:** Output includes regions like `[0x100000-0x7FE0000] Usable` totaling close to your QEMU `-m` setting.
  - **Notes:**

- [ ] **Compute total usable RAM**
  - **What:** Sum the sizes of all `Usable` entries.
  - **Verify:** Matches QEMU's configured memory (minus reserved overhead).
  - **Notes:**

### 5.2 The bitmap frame allocator

- [ ] **Study bitmap allocators**
  - **Why:** Simplest possible allocator. One bit per 4 KiB frame: 0 = free, 1 = used. Slow but easy and visible.
  - **Study:** OSDev Wiki: "Page Frame Allocation".
  - **Verify:** You can compute the bitmap size for 4 GiB of RAM (128 KiB).
  - **Notes:**

- [ ] **Locate space for the bitmap**
  - **Why:** Bootstrap problem: you need memory to manage memory.
  - **What:** Find the largest `Usable` region. Place the bitmap at its start. Mark those frames as used in the bitmap itself.
  - **Verify:** Log the bitmap's physical address and size.
  - **Notes:**

- [ ] **Mark every region's status**
  - **What:** Loop the memory map again. For every non-usable byte and your bitmap region, set bits to 1.
  - **Verify:** Print bitmap statistics — count free vs used. Free roughly equals total usable RAM in frames.
  - **Notes:**

- [ ] **Implement `allocFrame`**
  - **What:** Scan for the first 0 bit, set it, return `bit_index * 4096`.
  - **Verify:** Call `allocFrame()` 10 times. Returned addresses are increasing by 4096.
  - **Notes:**

- [ ] **Implement `freeFrame`**
  - **What:** Take a physical address, compute bit index, clear bit.
  - **Verify:** Alloc → free → alloc returns the same address.
  - **Notes:**

- [ ] **Stress test**
  - **What:** Alloc until exhaustion, then free all, then alloc again.
  - **Verify:** Counts match before and after. No corruption.
  - **Notes:**

### Phase 5 Milestone

You can allocate and free physical 4 KiB frames. You know exactly how much RAM is usable and how much is currently in use.

### Phase 5 Debug Checkpoint

- [ ] Add a `pmem` debug command (via your keyboard input) that prints allocator stats.
- [ ] In GDB, examine the bitmap memory directly with `x/256xb`. Confirm bits match what you logged.
- [ ] Write up: "What goes wrong if I forget to mark MMIO regions as used?"

---

## Phase 6 — Virtual Memory: Building Your Address Space

**Goal of this phase:** Control the page tables. Map and unmap virtual addresses at will. Survive page faults gracefully.

### 6.1 Understand x86_64 paging

- [ ] **Study 4-level paging**
  - **Why:** Every memory access goes through the page tables. You must own them.
  - **Study:** PML4 → PDPT → PD → PT structure. PTE flags (P, R/W, U/S, PWT, PCD, A, D, PS, G, NX). The role of CR3.
  - **What:** Read Intel SDM Vol 3, Chapter 4. Read OSDev Wiki: "Paging".
  - **Verify:** You can decompose a virtual address into its 4 indices + offset on paper.
  - **Notes:**

- [ ] **Study the higher-half kernel mapping**
  - **Why:** Limine maps your kernel into the upper half (`0xFFFFFFFF80000000+`) and provides a "higher half direct map" (HHDM) of all physical memory.
  - **Study:** Limine HHDM. Canonical addresses. Why kernels live in the upper half.
  - **Verify:** You can convert a physical address to its HHDM virtual address.
  - **Notes:**

### 6.2 Inspect existing tables

- [ ] **Read CR3**
  - **Why:** Find Limine's page tables before replacing them.
  - **What:** Use inline assembly: `mov rax, cr3`.
  - **Verify:** Log the value. It's a physical address aligned to 4096.
  - **Notes:**

- [ ] **Walk Limine's tables**
  - **Why:** Understanding what's already there before you change anything.
  - **What:** Write a `walk(vaddr)` function that returns the PTE for any virtual address, traversing through HHDM.
  - **Verify:** `walk(kernel_text_start)` returns a PTE with P=1 and the physical address matching where the bootloader loaded you.
  - **Notes:**

### 6.3 Build your own page tables

- [ ] **Define PTE structs**
  - **What:** A `packed struct(u64)` for PTEs with named bitfields.
  - **Verify:** `@sizeOf(PTE) == 8`.
  - **Notes:**

- [ ] **Implement `mapPage`**
  - **What:** Given a virtual address, physical address, and flags: walk the tables, calling `allocFrame()` to create missing levels. Set the final PTE.
  - **Verify:** Map a fresh frame at a high address; write to it; read back the value.
  - **Notes:**

- [ ] **Implement `unmapPage`**
  - **What:** Walk to the PTE, clear it, invalidate the TLB entry (`invlpg`).
  - **Study:** TLB (Translation Lookaside Buffer). Why `invlpg` is required after unmap.
  - **Verify:** After unmap, accessing the address triggers a #PF.
  - **Notes:**

- [ ] **Build your own PML4 and switch to it**
  - **Why:** You should own the address space, not Limine.
  - **What:** Allocate a new PML4. Copy Limine's higher-half entries (so kernel + HHDM still work). Load it into CR3.
  - **Verify:** Print "still alive" *after* loading CR3. If it works, your kernel is now running on its own page tables.
  - **Notes:**

### 6.4 Page fault handler upgrade

- [ ] **Read CR2 in #PF**
  - **Why:** CR2 holds the faulting virtual address — essential for debugging.
  - **What:** In your #PF handler, read CR2 and decode the error code (P, W/R, U/S, RSVD, I/D bits).
  - **Verify:** Trigger a fault by reading address `0x1`. Handler prints: "Page Fault at 0x1, present=0, write=0, user=0".
  - **Notes:**

### Phase 6 Milestone

You own your address space. You can map and unmap pages anywhere you want. Page faults give you actionable information.

### Phase 6 Debug Checkpoint

- [ ] Write a `vmem dump <vaddr>` command that prints the full walk of a virtual address.
- [ ] In QEMU monitor: `info tlb`, `info mem`. Compare to your own dumps.
- [ ] Map the same physical frame at two different virtual addresses; write through one, read through the other.
- [ ] Write up: "The full journey of `mov rax, [0xFFFFFFFF80001000]` through my page tables."

---

## Phase 7 — The Kernel Heap: `malloc` and `free`

**Goal of this phase:** Use `std.ArrayList`, hash maps, and other Zig data structures in kernel code.

### 7.1 Choose and study an allocator

- [ ] **Study allocator strategies**
  - **Why:** Bump, freelist, buddy, slab — each has tradeoffs. Start with freelist (linked-list of free blocks).
  - **Study:** OSDev Wiki: "Memory Allocation". Linked-list allocators.
  - **Verify:** You can describe how splitting and coalescing work.
  - **Notes:**

- [ ] **Reserve heap virtual address range**
  - **What:** Pick a range in the higher half (e.g., `0xFFFF_8800_0000_0000` to `0xFFFF_8900_0000_0000`).
  - **Verify:** Range doesn't overlap kernel or HHDM.
  - **Notes:**

### 7.2 Implement the allocator

- [ ] **Start with a bump allocator**
  - **Why:** Simpler than freelist. Get something working first.
  - **What:** Maintain a `next_free_vaddr` pointer. Each alloc maps pages on demand and returns the current pointer.
  - **Verify:** Alloc 1000 small objects in a loop. No crash.
  - **Notes:**

- [ ] **Wire into `std.mem.Allocator`**
  - **Why:** Lets you use Zig's standard data structures.
  - **Study:** The `std.mem.Allocator` vtable (`alloc`, `resize`, `free`, `remap`).
  - **What:** Wrap your bump allocator. Expose a global `kernel_allocator`.
  - **Verify:** `var list = std.ArrayList(u32).init(kernel_allocator);` then `try list.append(42);` works.
  - **Notes:**

- [ ] **Upgrade to a freelist allocator**
  - **What:** Maintain a list of free blocks with headers. Alloc finds a fit, splits if too big. Free coalesces adjacent blocks.
  - **Verify:** Many small allocs + frees in random order — no leak, no fragmentation collapse.
  - **Notes:**

- [ ] **Implement heap expansion**
  - **What:** When the freelist can't satisfy a request, map more physical frames at the end of the heap.
  - **Verify:** Allocate something bigger than your initial heap. It succeeds.
  - **Notes:**

### Phase 7 Milestone

`std.ArrayList`, `std.AutoHashMap`, and other Zig data structures work in your kernel.

### Phase 7 Debug Checkpoint

- [ ] Add a `heap stats` command: total mapped, total in use, freelist length, fragmentation %.
- [ ] Write a small test suite that does adversarial alloc patterns; run it on every boot in debug builds.
- [ ] Write up: "Why is heap fragmentation harder to detect than physical frame leaks?"

---

## Phase 8 — Multitasking: From One Thread to Many

**Goal of this phase:** Two kernel tasks run concurrently. Then ten. Then preemptively. Then with sleep.

### 8.1 Cooperative tasks

- [ ] **Define the Task struct**
  - **Why:** Each task needs its own stack, register state, ID, and a list link.
  - **Study:** Callee-saved vs caller-saved registers in SysV x86_64 ABI. What "context" means in a context switch.
  - **What:** Define `Task { id, state, kernel_stack, rsp, next }`.
  - **Verify:** Compiles. `@sizeOf(Task)` is reasonable.
  - **Notes:**

- [ ] **Write `contextSwitch(old: **Task, new: *Task)`**
  - **Why:** Save old task's callee-saved regs to its stack, save its RSP, load new RSP, restore new task's callee-saved regs, return.
  - **What:** Write this in naked assembly. Only callee-saved registers (RBX, RBP, R12-R15) need pushing.
  - **Verify:** Inspect disassembly — exactly the pushes/pops you expect.
  - **Notes:**

- [ ] **Bootstrap a new task's stack**
  - **Why:** A brand-new task has nothing on its stack. You must hand-craft the initial frame so the first `contextSwitch` lands at the task's entry function.
  - **What:** Write `taskCreate(entry_fn)`: allocate a stack, push fake register values + entry address, save RSP in the Task struct.
  - **Verify:** Create two tasks that each call `log.info("hello from task N")` in a loop.
  - **Notes:**

- [ ] **Implement cooperative `yield()`**
  - **What:** Move current task to the back of the ready queue; pick the next task; context switch.
  - **Verify:** Both tasks alternate output. Counter values match expected sequence.
  - **Notes:**

### 8.2 Preemptive scheduling

- [ ] **Hook the LAPIC timer into the scheduler**
  - **Why:** Tasks shouldn't have to be polite.
  - **Study:** What "preemption" means and why it must be careful (interrupts must be disabled in critical sections).
  - **What:** In the timer IRQ handler, after a fixed quantum, call `yield()`.
  - **Verify:** Two tasks that never yield voluntarily still alternate output.
  - **Notes:**

- [ ] **Add task states**
  - **What:** Enum: `running`, `ready`, `blocked`, `sleeping`, `zombie`.
  - **Verify:** State transitions log correctly.
  - **Notes:**

- [ ] **Implement `sleep(ms)`**
  - **What:** Mark task `sleeping`, store wake-up tick, remove from ready queue. In timer handler, walk sleepers and wake any whose time has come.
  - **Verify:** `sleep(1000)` actually sleeps for ~1 second.
  - **Notes:**

### 8.3 Synchronization primitives

- [ ] **Study locks at single-CPU level**
  - **Why:** Even single-CPU kernels need to protect against IRQ-vs-task races.
  - **Study:** Why you can't just `cli` for everything. Spinlocks with IRQ disable/restore.
  - **Verify:** You can describe a race between a task and an IRQ handler touching the same list.
  - **Notes:**

- [ ] **Implement an IRQ-safe spinlock**
  - **What:** `acquire()` saves the RFLAGS interrupt bit, disables IRQs, takes the lock. `release()` releases and restores.
  - **Verify:** Wrap your ready queue operations in the lock. Stress test with many tasks.
  - **Notes:**

- [ ] **Implement a semaphore and a mutex**
  - **What:** Built on top of the spinlock + wait queues. Mutex sleeps the task instead of spinning.
  - **Verify:** Producer/consumer test with bounded buffer works without lost or duplicated items.
  - **Notes:**

### Phase 8 Milestone

You have a real multitasking kernel. Dozens of tasks can run; some sleep; some block on locks. The screen and serial both reflect this concurrency.

### Phase 8 Debug Checkpoint

- [ ] Add a `ps` debug command listing all tasks, states, CPU time used.
- [ ] Add stack-canary checks to detect stack overflow in a task.
- [ ] Run a stress test: 100 tasks doing random sleep+work+yield. Confirm no crash for 10 minutes.
- [ ] Write up: "Step-by-step what happens inside `contextSwitch` for the first switch from task A to task B."

---

## Phase 9 — User Space: Ring 3 and Syscalls

**Goal of this phase:** Run untrusted code in Ring 3. It can't crash the kernel. It can only ask for things via syscalls.

### 9.1 Prepare the GDT and TSS

- [ ] **Study privilege levels**
  - **Why:** Ring 0 (kernel) can do anything; Ring 3 (user) can't touch I/O, can't change CR3, can't disable interrupts.
  - **Study:** DPL/CPL/RPL. The TSS (Task State Segment) and why long mode still needs it. The `IST` mechanism for safer interrupt stacks.
  - **Verify:** You can explain why a syscall changes both CS and SS.
  - **Notes:**

- [ ] **Add user code/data segments to the GDT**
  - **What:** Append two more descriptors with DPL=3.
  - **Verify:** GDT now has 5 entries (null, k-code, k-data, u-code, u-data) — order matters for `sysret`.
  - **Notes:**

- [ ] **Set up a TSS**
  - **What:** Define the TSS struct, populate `RSP0` with your current kernel stack, add a TSS descriptor to the GDT (it's 16 bytes), and load it with `ltr`.
  - **Verify:** No fault after `ltr`. Print the TR value.
  - **Notes:**

### 9.2 The first user task

- [ ] **Allocate a user-mode stack**
  - **What:** Map pages with the U/S bit set, in a separate user-space virtual range.
  - **Verify:** Pages show up in your `vmem dump` with user-accessible flag.
  - **Notes:**

- [ ] **Write a tiny user program**
  - **Why:** You don't need an ELF loader yet — just hand-place some code at a known virtual address.
  - **What:** Inline machine code or a separately compiled blob that does `mov rax, 1; mov rdi, ...; syscall; jmp $`.
  - **Verify:** `objdump` it; manually copy bytes into a mapped user page.
  - **Notes:**

- [ ] **Drop to Ring 3**
  - **What:** Set up the iretq frame: push user SS, user RSP, RFLAGS (with IF=1), user CS, user RIP. Execute `iretq`.
  - **Verify:** First user instruction runs. If you instead get a #GP, recheck selector RPLs.
  - **Notes:**

### 9.3 Syscalls

- [ ] **Study the `syscall`/`sysret` instructions**
  - **Why:** Faster than `int 0x80`. The modern way.
  - **Study:** STAR, LSTAR, SFMASK MSRs. The ABI: RAX=syscall number, RDI/RSI/RDX/R10/R8/R9 = args, RCX is clobbered (holds return RIP), R11 holds saved RFLAGS.
  - **Verify:** You can list the calling convention.
  - **Notes:**

- [ ] **Configure the syscall MSRs**
  - **What:** Write STAR (segment selectors), LSTAR (your handler address), SFMASK (which RFLAGS bits to clear). Set the SCE bit in EFER.
  - **Verify:** Inspect MSRs from the QEMU monitor (`info registers`).
  - **Notes:**

- [ ] **Write the syscall entry stub**
  - **Why:** This is delicate. User RSP must be swapped for a kernel RSP (typically via `swapgs` + per-CPU data).
  - **Study:** `swapgs`, per-CPU storage via GS base.
  - **What:** Naked assembly: swapgs, save user RSP, load kernel RSP, push registers, call Zig dispatcher, restore, swapgs, sysretq.
  - **Verify:** A user program calling `syscall` returns cleanly.
  - **Notes:**

- [ ] **Implement first syscalls**
  - **What:** `sys_write(fd, buf, len)` (just routes to your serial/console for now), `sys_exit(code)`, `sys_getpid()`, `sys_yield()`.
  - **Verify:** User program writes "hello from ring 3" via `sys_write`. The string appears on screen + serial.
  - **Notes:**

- [ ] **Validate user pointers**
  - **Why:** A user program can pass a kernel address as `buf`. You must check before dereferencing.
  - **Study:** SMAP/SMEP. Why naive validation isn't enough.
  - **What:** Write `validateUserPointer(ptr, len)` that walks page tables and confirms all pages are user-accessible.
  - **Verify:** A malicious user program passing `0xFFFFFFFF80000000` to `sys_write` gets `-EFAULT`, not a kernel oops.
  - **Notes:**

### Phase 9 Milestone

A user-mode program runs, makes syscalls, and cannot crash your kernel even when it deliberately tries.

### Phase 9 Debug Checkpoint

- [ ] Try every "bad" thing in user mode: write to CR3, execute `cli`, read kernel memory. Confirm each generates a #GP or #PF caught by your kernel.
- [ ] Use GDB to step into the syscall stub from a breakpoint in the user program.
- [ ] Write up: "What is on the stack at each step from `syscall` to my Zig dispatcher and back?"

---

## Phase 10 — Storage and Filesystems

**Goal of this phase:** Load files from disk. Execute them.

### 10.1 Initial ramdisk (start here)

- [ ] **Study initrd and the TAR/USTAR format**
  - **Why:** Asking the bootloader to load a TAR file into memory is the easiest "filesystem".
  - **Study:** USTAR header layout. Limine's "modules" mechanism.
  - **Verify:** You can describe the USTAR header fields.
  - **Notes:**

- [ ] **Add a module request**
  - **What:** Ask Limine to load `initrd.tar` alongside your kernel.
  - **Verify:** Print the module's address and size at boot.
  - **Notes:**

- [ ] **Parse the TAR**
  - **What:** Walk the headers; list filenames + sizes to serial.
  - **Verify:** `ls /` command (typed at your keyboard) lists every file you put in the TAR.
  - **Notes:**

### 10.2 The Virtual File System (VFS)

- [ ] **Study VFS concepts**
  - **Why:** Decouples "open/read/write/close" from the underlying storage.
  - **Study:** Inodes, dentries, file descriptors, vfs vtables.
  - **Verify:** You can sketch the relationship between an `Inode` and a `File`.
  - **Notes:**

- [ ] **Define VFS interfaces**
  - **What:** `Inode`, `File`, `Mount`, with vtables (`read`, `write`, `lookup`, `readdir`).
  - **Verify:** Multiple filesystem types can implement the same vtable.
  - **Notes:**

- [ ] **Mount the initrd as a TARFS**
  - **What:** Implement the vtable on top of your TAR parser.
  - **Verify:** `cat /hello.txt` (typed at your keyboard) prints the file's content.
  - **Notes:**

- [ ] **Add VFS syscalls**
  - **What:** `sys_open`, `sys_read`, `sys_write`, `sys_close`, `sys_lseek`.
  - **Verify:** User program reads a file from initrd and prints it.
  - **Notes:**

### 10.3 Real disk I/O

- [ ] **Pick a disk protocol**
  - **Why:** ATA PIO is dead simple but slow; AHCI (SATA) is more realistic. Start with ATA PIO.
  - **Study:** ATA PIO command set, ports `0x1F0-0x1F7`. OSDev Wiki: "ATA PIO Mode".
  - **Verify:** You can describe the read-sector command sequence.
  - **Notes:**

- [ ] **Configure QEMU with a disk**
  - **What:** Add `-drive file=disk.img,format=raw` to your QEMU args. Create a 64 MiB raw image.
  - **Verify:** QEMU boots and you can see disk via `info block` in the monitor.
  - **Notes:**

- [ ] **ATA PIO read driver**
  - **What:** Implement `readSector(lba, buf)`. Identify the drive first.
  - **Verify:** Read sector 0 and print as hex. Matches what `hexdump disk.img | head` shows on your host.
  - **Notes:**

- [ ] **Add a block device layer**
  - **What:** Generic `BlockDevice` interface with `read`/`write`. Wraps ATA.
  - **Verify:** Read sector via the block device interface; result matches direct ATA read.
  - **Notes:**

### 10.4 FAT32 read-only

- [ ] **Study FAT32**
  - **Why:** Simple, universal, well-documented. Read-only is enough to start.
  - **Study:** BPB (BIOS Parameter Block), FAT chains, directory entries (8.3 + LFN).
  - **Verify:** You can describe how to find the first cluster of a file.
  - **Notes:**

- [ ] **Format and populate `disk.img`**
  - **What:** On host: `mkfs.fat -F32 disk.img`, mount with loopback, copy files in.
  - **Verify:** `file disk.img` reports a FAT32 filesystem.
  - **Notes:**

- [ ] **Parse the BPB**
  - **What:** Read sector 0, verify signature, extract sectors-per-cluster, FAT location, root directory cluster.
  - **Verify:** Logged values match `fsck.fat` output on the host.
  - **Notes:**

- [ ] **Walk the root directory**
  - **What:** Read directory entries cluster by cluster following the FAT chain.
  - **Verify:** Listing shows the files you put on disk.
  - **Notes:**

- [ ] **Read a file**
  - **What:** Follow the cluster chain, return data.
  - **Verify:** Contents of `/test.txt` on disk match what you wrote on the host.
  - **Notes:**

- [ ] **Mount FAT32 in the VFS**
  - **What:** Implement the vtable.
  - **Verify:** Same `cat /file` command works on both initrd and FAT32 mounts.
  - **Notes:**

### Phase 10 Milestone

Your kernel reads files from a real disk through a real filesystem, exposed through a real VFS, accessed by real user programs.

### Phase 10 Debug Checkpoint

- [ ] Add `mount`, `ls`, `cat`, `xxd` debug commands.
- [ ] Cross-verify every file you read against the host (`md5sum`).
- [ ] Write up: "The full path of `cat /test.txt` from keystroke to pixel."

---

## Phase 11 — ELF Loader and a Real User Program

**Goal of this phase:** Stop hand-crafting user code. Compile a separate Zig program, put it on the filesystem, and run it from your shell.

- [ ] **Study ELF loading**
  - **Why:** You parsed your kernel ELF in your head; now do it programmatically for user programs.
  - **Study:** Program headers, `PT_LOAD` segments, `p_vaddr`, `p_memsz`, `p_filesz`, the `.bss` zero-fill behavior.
  - **Verify:** You can list the steps to load a static ELF.
  - **Notes:**

- [ ] **Compile a user program**
  - **What:** Create a separate Zig project targeting `x86_64-freestanding-none` for your "userland ABI". It calls only your syscalls.
  - **Verify:** Produces a static ELF.
  - **Notes:**

- [ ] **Write the ELF loader**
  - **What:** Read ELF from VFS, map `PT_LOAD` segments to user pages, copy data, zero `.bss`, set entry point.
  - **Verify:** Load and run a "hello world" user program via syscall.
  - **Notes:**

- [ ] **Add `sys_exec` and `sys_fork` (or `sys_spawn`)**
  - **Why:** Real OSes can launch processes from user code.
  - **Study:** Tradeoffs between fork/exec vs posix_spawn vs your own design.
  - **What:** Implement at least `sys_spawn(path, argv, envp)`.
  - **Verify:** Shell program launches other programs.
  - **Notes:**

- [ ] **Add `sys_wait`**
  - **What:** Block parent until child exits; reap exit status.
  - **Verify:** Shell shows child's exit code.
  - **Notes:**

### Phase 11 Milestone

You can write a Zig program, drop it in the disk image, and run it from a shell prompt inside your OS.

### Phase 11 Debug Checkpoint

- [ ] Crash your user program deliberately (null deref, syscall with bad args). Confirm only that program dies.
- [ ] Write up: "What does my kernel do between `sys_spawn("/bin/hello")` and the first instruction of `hello`?"

---

## Phase 12 — A Real Shell and the User Experience

**Goal of this phase:** You have a usable interactive system.

- [ ] **Move the keyboard handling into user space**
  - **What:** Add `sys_read` from `/dev/kbd` (or stdin). The kernel exposes the keyboard event queue as a file.
  - **Verify:** User program reads keystrokes via standard `read`.
  - **Notes:**

- [ ] **Build a TTY layer**
  - **What:** Line editing, canonical mode, echo on/off, basic cursor control.
  - **Verify:** Typing into the shell shows characters; backspace works; enter submits.
  - **Notes:**

- [ ] **Write a shell as a user program**
  - **What:** Reads lines, tokenizes, looks up `/bin/<cmd>`, spawns, waits.
  - **Verify:** `ls`, `cat`, `echo`, `pwd` work as separate binaries.
  - **Notes:**

- [ ] **Add pipes**
  - **Why:** The killer feature of unix.
  - **What:** `sys_pipe(fds: [2]i32)`. In-kernel buffer with reader/writer file descriptors.
  - **Verify:** `ls | cat` shows the listing.
  - **Notes:**

- [ ] **Add basic redirection**
  - **What:** Parse `>` and `<` in the shell; `sys_dup2` to wire FDs before exec.
  - **Verify:** `echo hi > /file && cat /file` prints `hi`.
  - **Notes:**

### Phase 12 Milestone

You have a working unix-like shell on your own OS. You can pipe `ls | cat`. This is the moment to take a video for your future self.

### Phase 12 Debug Checkpoint

- [ ] Run a 10-command session entirely in your shell. Note every bug; fix them.
- [ ] Write up: "From keypress to the prompt re-appearing — every layer involved."

---

## Phase 13 — Beyond the Single Core (SMP)

**Goal of this phase:** Use all the CPUs QEMU exposes.

- [ ] **Study SMP startup**
  - **Why:** Bringing up additional cores ("APs") requires the LAPIC, an MP wakeup protocol, and per-CPU data.
  - **Study:** Limine's SMP request (it does the hard part of getting APs out of real mode for you). Per-CPU storage via GS.MSR.
  - **Verify:** You can list what state each AP starts in.
  - **Notes:**

- [ ] **Boot the APs**
  - **What:** Make a Limine SMP request; in the entry callback, set up GDT/IDT/CR3/GS for that core; mark ready.
  - **Verify:** Log "CPU N online" for every core. Count matches QEMU's `-smp`.
  - **Notes:**

- [ ] **Per-CPU data**
  - **What:** A struct per CPU, accessed via GS base.
  - **Verify:** Each core prints a different `cpu_id`.
  - **Notes:**

- [ ] **Make the scheduler SMP-aware**
  - **Why:** Each CPU now picks tasks from a shared (or per-CPU) ready queue.
  - **Study:** Per-CPU vs global run queues. Load balancing.
  - **What:** Start with a single global queue + spinlock. Profile later.
  - **Verify:** All cores show usage during a multi-task workload.
  - **Notes:**

- [ ] **Audit locks**
  - **What:** Every shared data structure needs a real lock now.
  - **Verify:** Stress test for an hour with no corruption.
  - **Notes:**

### Phase 13 Milestone

`qemu-system-x86_64 -smp 4` and your OS uses all four cores.

### Phase 13 Debug Checkpoint

- [ ] Add a `topology` debug command showing CPUs, their states, and current tasks.
- [ ] Write up: "What changed in my kernel to go from 1 to N cores?"

---

## Phase 14 — Polish and Stretch Goals

These are the things that turn a "demo OS" into something you'd be proud to show.

- [ ] **Networking** — RTL8139 driver, ARP, IPv4, UDP, then TCP. (Months of work.)
- [ ] **Sound** — AC'97 or HDA driver. Play a WAV.
- [ ] **PCI enumeration** — Walk PCI config space, discover devices, hand off to drivers.
- [ ] **USB stack** — xHCI driver. Mouse and keyboard over USB.
- [ ] **A windowing system** — Compositor in user space, mouse cursor, drag-and-drop.
- [ ] **More filesystems** — ext2 read/write, then read-write FAT, then your own FS design.
- [ ] **A package format and a port system** — for adding new userland programs.
- [ ] **UEFI boot path** — already supported by Limine; explore writing a Zig UEFI app yourself.
- [ ] **Boot on real hardware** — write the ISO to a USB stick; boot an old laptop. Bring a fire extinguisher.

---

## Cross-Cutting Practices

These aren't a phase — they're habits to keep from Phase 0 onward.

- [ ] **Commit often**, with messages describing *what changed and why it worked* (or didn't).
- [ ] **Keep a `docs/` folder** with one Markdown file per phase. Use the "Notes" spaces in this roadmap as the seed.
- [ ] **Re-run earlier milestones often.** Phase 8 can subtly break Phase 6; catch regressions early.
- [ ] **Use `zig build test`** for everything testable in userland (parsers, allocators, data structures).
- [ ] **Don't optimize until you measure.** Naive algorithms are fine for years.
- [ ] **Read other people's code.** Sortix, SerenityOS, Theseus, Hubris, Redox, the Linux 0.01 source. Steal ideas, never steal code (license).
- [ ] **Keep a "weird behavior" log.** Every QEMU quirk, every Intel SDM footnote that bit you. Future-you will thank you.

---

## Suggested Documentation Template (for your own notes)

For each phase, create `docs/phase-NN.md`:

```markdown
# Phase NN — <title>

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
```

Treat this roadmap as a scaffold for *your* documentation. The point isn't to finish the checkboxes — it's to be able to teach someone else what you learned at each step.
