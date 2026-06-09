# Phase 2 — Finding Your Voice: Output (and Why It Matters First)

**Goal of this phase:** Two independent ways to see what your kernel is doing — a serial port (text to your host terminal) and a framebuffer (pixels on the screen). Output before everything else, because debugging without output is suffering.

> Note on VGA text mode: the original roadmap used `0xB8000`. Modern Limine-booted kernels run in long mode with a graphical framebuffer, not VGA text mode. We will use the framebuffer instead — it's more useful and more honest about how real systems work. The serial port comes *first* because it works even when the framebuffer is broken.

## 2.1 Serial output (do this first)

- [x] **Study x86 port I/O**
  - **Why:** Many legacy devices (including the serial port) are controlled through I/O ports, a separate address space from memory.
  - **Study:** `in`/`out` instructions. Port addresses for COM1 (`0x3F8`). The 8250/16550 UART.
  - **What:** Read OSDev Wiki: "Serial Ports".
  - **Verify:** You can list the offsets for the data register, line status register, and line control register.
  - **Notes:**

- [x] **Write port I/O wrappers in Zig**
  - **Why:** You'll use `inb`/`outb` from dozens of places. Wrap them once.
  - **Study:** Zig inline assembly syntax (`asm volatile`, output/input/clobber).
  - **What:** Create `src/arch/x86_64/port.zig` with `outb`, `inb`, `outw`, `inw`, `outl`, `inl`.
  - **Verify:** Code compiles. Inspect generated assembly with `objdump` to confirm real `in`/`out` instructions.
  - **Notes:**

- [x] **Initialize COM1**
  - **Why:** Without initialization the UART won't transmit.
  - **Study:** UART init sequence: disable interrupts, set DLAB, set baud divisor, set 8N1, enable FIFO, set DTR/RTS.
  - **What:** Create `src/drivers/serial.zig` with `init()`.
  - **Verify:** After calling `init()`, the loopback test (set bit 4 of MCR, write byte, read back) succeeds.
  - **Notes:**

- [x] **Implement `writeByte` and `writeString`**
  - **Why:** This is your first real output.
  - **What:** Add functions that poll the Line Status Register's "transmitter empty" bit, then write a byte to the data register.
  - **Verify:** Call `serial.writeString("Hello from kernel!\n")` from `_start`. Run with `-serial stdio`. Text appears in your terminal.
  - **Notes:**

- [x] **Hook serial into Zig's `std.fmt`**
  - **Why:** You want `print("value = {}\n", .{x})` to work. This is huge for debugging.
  - **Study:** `std.fmt.format`, the `Writer` interface, how to satisfy it without `std.io`.
  - **What:** Create a minimal `Writer` that calls `serial.writeByte`. Wrap `std.fmt.format` in a `print` function.
  - **Verify:** `print("hex: {x}, dec: {d}\n", .{0xDEAD, 42})` outputs correctly to your terminal.
  - **Notes:**

## 2.2 Framebuffer output

- [x] **Read Limine's framebuffer response**
  - **Why:** Limine has already set up a linear framebuffer for you in long mode. You just need the pointer, width, height, and pitch.
  - **Study:** Limine's framebuffer request/response structures. What "pitch" means (it's not always `width * bpp`).
  - **What:** Access the response from your framebuffer request. Print its width, height, pitch, and address to serial.
  - **Verify:** Serial shows reasonable values (e.g., 1024x768, pitch 4096).
  - **Notes:**

- [x] **Paint your first pixel**
  - **Why:** Smallest possible framebuffer test.
  - **What:** Write a 32-bit color value to `framebuffer[0]`.
  - **Verify:** A single colored dot appears at the top-left of the QEMU window.
  - **Notes:**

- [x] **Fill the screen with a color**
  - **Why:** Confirms you understand pitch and dimensions.
  - **What:** Loop over every pixel using `y * pitch + x * 4` indexing.
  - **Verify:** QEMU shows a solid color across the whole window.
  - **Notes:**

- [x] **Embed a bitmap font**
  - **Why:** Drawing text requires glyph data. Don't write your own — use a standard PSF font or an 8x8 ROM font.
  - **Study:** The PSF1/PSF2 font formats, or just a public-domain 8x8 bitmap font header.
  - **What:** Add a font file to your project. Embed it with `@embedFile`.
  - **Verify:** You can index into the font and get the bitmap for the letter `A`.
  - **Notes:**

- [x] **Draw a single glyph**
  - **Why:** Verifies your font logic before building a full console.
  - **What:** Write `drawChar(c, x, y, fg, bg)`. For each bit in the glyph, write a pixel.
  - **Verify:** The letter `A` appears on the screen.
  - **Notes:**

- [x] **Build a console abstraction**
  - **Why:** You want `console.print("...")` to work like serial does.
  - **What:** Track cursor position. Implement `putChar` with `\n` handling. Wrap `std.fmt.format` over it.
  - **Verify:** Multi-line text prints correctly across the screen.
  - **Notes:**

- [x] **Implement scrolling**
  - **Why:** Once the screen fills up, you need to shift content up.
  - **What:** When the cursor reaches the bottom, copy each row's memory up by one row height; clear the last row.
  - **Verify:** Print 100 lines in a loop — text scrolls smoothly.
  - **Notes:**

## 2.3 Unify your output

- [ ] **Build a single `log` module**
  - **Why:** You want every important event to appear in *both* serial and framebuffer. Serial is for post-mortem analysis; framebuffer is for live feel.
  - **What:** Create `src/log.zig` with `info`, `warn`, `err` functions that write to both sinks with a prefix.
  - **Verify:** `log.info("kernel booted at {x}", .{addr})` shows in QEMU's window *and* your host terminal.
  - **Notes:**

## Phase 2 Milestone

Your kernel prints colored, formatted log lines to both the QEMU window and your host terminal. You can `print` any integer in hex or decimal. You will never feel "in the dark" again.

## Phase 2 Debug Checkpoint

- [ ] Print every Limine response struct's contents at boot. Confirm sane values.
- [ ] Print your kernel's load address. Compare it to your linker script's expected address.
- [ ] In GDB, set a breakpoint on `serial.writeByte` and step through one character's worth of output.
- [ ] Write up: "How does `std.fmt.format` route from my `print()` to the UART data register?"

---
