# Phase 2 — Finding Your Voice: Output (and Why It Matters First)

## 2.1 Serial Output

### What I built

I built the full serial output stack for COM1 on x86_64, from bare metal up to formatted printing. This includes a port I/O toolbox (`outb`, `inb`, `outw`, `inw`, `outl`, `inl`) with an architecture-aware abstraction layer (`arch.zig`) that uses a comptime switch to select x86_64-specific implementations — making future RISC-V porting a matter of adding one case. On top of that, I built a UART serial driver (`serial.zig`) that initializes COM1 at 115200 baud with 8N1 format, and exposes `writeByte`, `writeString`, and `print`. The `print` function hooks into `std.Io.Writer` by implementing a custom `drain` vtable function, giving the kernel full `print("value = {d}, addr = {x}\n", .{ v, a })` support without any OS or libc dependency. The final piece was a non-trivial debugging session that uncovered a build configuration bug: the default x86_64 target emits SSE instructions that fault in a freestanding kernel that hasn't enabled SSE in the CPU. Disabling SIMD codegen and enabling `soft_float` in the target query fixed it.

### What I learned (concepts)

- **UARTs (Universal Asynchronous Receiver/Transmitter)**: Hardware devices that convert between digital bits in memory and serial electrical signals on a wire. They sit idle until initialized — you configure baud rate, data format, and control signals before sending anything.

- **Port I/O (x86_64)**: A separate address space from RAM, accessed with dedicated CPU instructions (`in`, `out`) rather than `mov`. Hardware devices like the UART live at fixed port addresses (0x3F8 for COM1). Unlike a memory read (`mov rax, [0x1000]`), a port read requires `in al, dx` with the port number in DX and the result in AL.

- **x86_64 calling convention**: Parameters arrive in registers (RDI, RSI, etc.) per the System V ABI. In inline assembly, I constrain Zig function parameters to specific registers using `"{al}"`, `"{dx}"` syntax, mapping the function's port/value parameters directly to what the `out`/`in` instructions expect.

- **Baud rate and divisor**: Baud rate is bits per second. The UART divides its oscillator frequency (1.8432 MHz) by a divisor to hit the target rate. For 115200 baud, the divisor is 1. The divisor is a 16-bit value split across two registers (low byte at 0x3F8, high byte at 0x3F9) that are only accessible when DLAB is set.

- **DLAB (Divisor Latch Access Bit)**: A quirk of the 8250/16550 UART design. Setting bit 7 of the LCR (0x3FB) switches ports 0x3F8 and 0x3F9 from their normal roles (data and interrupt enable) into divisor registers. You set DLAB, write the divisor, then clear DLAB to return to normal mode. It's a mode switch baked into the hardware to reuse port addresses for dual purposes.

- **Bit-to-hex register values**: Hardware registers are bit-packed. Each bit (or group) controls a specific feature. To configure 8N1 (8 data bits, no parity, 1 stop bit), I laid out the LCR bit fields: `0 0 0 0 0 0 1 1` = `0x03`. This is how you read a CPU datasheet and translate intent into a byte value to write to hardware.

- **Architecture-aware abstraction with comptime**: `arch.zig` selects the right architecture module at compile time using a `switch (builtin.target.cpu.arch)` that is evaluated by the compiler — only the x86_64 code ends up in the binary. When porting to RISC-V, I add one case and implement the same function signatures.

- **std.Io.Writer and dependency injection**: `std.Io.Writer.print` is pure computation — it parses format strings, converts values to characters, and calls `drain()` with the resulting bytes. It has no OS dependency because it doesn't know or care where output goes. By providing a custom `drain` implementation that calls `writeByte`, I inject the serial port as the output sink. This is the same pattern as `std.mem.Allocator`: the standard library accepts interfaces, and you own the implementations.

- **SSE in freestanding kernels**: The default `x86_64` target includes SSE2 as a baseline CPU feature. LLVM uses SSE registers (xmm0) for memory copies and struct passing — including inside `std.Io.Writer`'s formatting code. A freestanding kernel that hasn't configured CR0/CR4 for SSE will fault on any `movdqu xmm0` instruction. Without an IDT, that fault becomes a triple-fault and the CPU halts. The fix: disable SIMD features in the build target (`cpu_features_sub`) and enable `soft_float` (`cpu_features_add`) so the compiler never emits SSE instructions.

### What surprised me

- **The SSE silent kill**: The biggest trap of the session. `writeString("TEST1\n")` worked perfectly. `print("Number: {d}\n", .{42})` produced nothing and halted the kernel. The symptom pointed nowhere near the cause. The logic was probably correct (tested on the host, got the right output). The real culprit was 324 SSE instructions emitted by LLVM inside the formatting path. The lesson: always verify what instructions your freestanding build actually contains, especially when using standard library code for the first time. `objdump -d build/kernel.elf | grep -c xmm` should return 0 for a kernel without SSE enabled.

- **Naked functions can't call other functions**: I started with `callconv(.naked)` on `_start` thinking it was required for a kernel entry point. Naked means "no prologue/epilogue" — which breaks all function calls since the call machinery requires that setup. Removing `.naked` immediately unblocked everything. Naked is only for the bare minimum hand-written assembly; `_start` needs to call real Zig functions.

- **Port addresses are arbitrary**: I kept transposing 0x3F8, 0x3FA, 0x3FB, 0x3FC. There's no mnemonic logic — you memorize them or keep a reference. This is why documenting port addresses as named constants is worth doing from the start.

- **writeString worked while print didn't**: Because `writeString` is a plain byte loop with no memory copies, the compiler had no reason to use SSE. `print` triggered SSE via `std.Io.Writer`'s internal `@memcpy`. The inconsistency between two functions that "both write to serial" made this very hard to diagnose without actually inspecting the generated assembly.

### What I'd do differently

- **Disable SSE in the build target immediately.** The first `build.zig` for any x86_64 freestanding kernel should include `cpu_features_sub` (mmx, sse, sse2, avx, avx2) and `cpu_features_add` (soft_float). Not doing this causes subtle, hard-to-diagnose faults the moment you touch any standard library code that does memory copies. This is not optional — it is a prerequisite for using `std` in freestanding.

- **Document port addresses as named constants from the start.** Instead of hardcoding `0x3F9` everywhere, define `const COM1_IER: u16 = 0x3F9;` at the top of the serial driver. It eliminates transposition errors and makes the code self-documenting.

- **Verify generated assembly when something "should work but doesn't."** `objdump -d` and `grep xmm` would have found the SSE issue immediately. The pattern: run the logic on the host first (to confirm correctness), then inspect the freestanding binary for forbidden instructions (SSE, syscalls, etc.) when behavior diverges.

### Verification evidence

- `zig build run` compiles without errors and boots into the kernel (QEMU window, black screen, halted at `hlt`).
- `objdump -d build/kernel.elf | grep "outb\|inb\|outw"` shows real x86_64 port I/O instructions in the binary.
- `objdump -d build/kernel.elf | grep -c xmm` returns `0` after the SSE fix.
- Serial output confirmed end to end:
  ```
  TEST1
  Number: 42
  String: hello
  ```
- Moved from macOS (M1) to Arch Linux (Ryzen 9950X) mid-session; QEMU required `sudo pacman -S qemu` to get display support, but the kernel code was portable unchanged.

### Open questions

- Should `writeByte` keep the timeout guard, or go back to polling forever? The timeout prevents a wedged UART from hanging the kernel, but it means a broken UART silently drops bytes rather than stalling visibly. For now, keeping it.
- Is it worth adding `const COM1_DATA: u16 = 0x3F8` etc. constants at the top of `serial.zig` to replace the magic numbers?
- Next: Phase 2.2 — Framebuffer output (read Limine's framebuffer response, paint pixels, embed a font, build a console with scrolling).
