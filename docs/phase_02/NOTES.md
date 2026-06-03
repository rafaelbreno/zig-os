# Phase 2 — Finding Your Voice: Output (and Why It Matters First)

## 2.1 Serial Output

### What I built

I built the foundation for serial communication with COM1 on x86_64. This involved creating a port I/O abstraction layer (`outb`, `inb`, `outw`, `inw`, `outl`, `inl`) that translates between Zig code and x86_64 assembly instructions, then using that toolbox to initialize a UART chip with the correct baud rate, data format, and control signals. The UART is now configured for 115200 baud, 8N1 format, and ready to send data.

### What I learned (concepts)

- **UARTs (Universal Asynchronous Receiver/Transmitter)**: Hardware devices that convert between digital bits in memory and serial signals on a wire. They're the bridge between CPU and external devices (like a terminal). The UART sits idle until initialized—you have to tell it what speed, data format, and signals to use.

- **Port I/O (x86_64)**: Separate from memory access. Devices are controlled via special I/O port addresses (0x3F8, 0x3F9, etc.) using dedicated CPU instructions (`in`, `out`). Unlike `mov rax, [0x1000]` (memory read), you use `in al, dx` (port read).

- **x86_64 calling convention**: Parameters arrive in registers (RDI, RSI, etc.). I used inline assembly constraints (`{al}`, `{ax}`, `{dx}`) to map Zig function parameters to the CPU registers needed by `in`/`out` instructions.

- **Baud rate and divisor**: Baud rate is bits per second. The UART divides its oscillator frequency by a divisor to achieve the target rate. For 115200 baud on a 1.8432 MHz clock, the divisor is 1.

- **DLAB (Divisor Latch Access Bit)**: A quirk of the 8250/16550 UART. When DLAB=1, ports 0x3F8/0x3F9 become divisor registers. When DLAB=0, they're data/interrupt registers. It's a mode switch.

- **Bit-to-hex register values**: Hardware registers are bit-packed. Each bit (or group) controls a feature. To configure 8N1 (8 data bits, no parity, 1 stop bit), I worked out the bit layout: `0 0 0 0 0 0 1 1` = `0x03`. This taught me how to read CPU datasheets and convert intentions into byte values.

- **Architecture-aware abstraction**: I designed the code to cleanly separate x86_64-specific implementation from generic logic. Port I/O and serial drivers live in `arch/x86_64/`, exposed through `arch.zig` via comptime switches. This makes RISC-V porting straightforward—swap out the arch directory, implement the same interfaces.

### What surprised me

- **Naked functions can't call other functions**: I started with `callconv(.naked)` on `_start` thinking it was required for kernels. It's not—naked means "no prologue/epilogue," which breaks function calls. Once I removed it, everything worked. Naked is only for the bare minimum assembly.

- **Port addresses are arbitrary**: I kept mixing up 0x3F8, 0x3FA, 0x3FB, 0x3FC. There's no pattern—you just have to memorize them or have a reference. The datasheet is your friend.

- **Limine's protocol is cleaner than I expected**: Setting up Limine requests (putting structs in the `.requests` section) is straightforward. The bootloader just scans that section and fills in responses. No magic, just convention.

### What I'd do differently

- **I'd document port addresses in a constant.** Instead of hardcoding `0x3F9` everywhere, I'd define `const COM1_IER = 0x3F9;` at the top of the serial driver. Saves mental overhead and makes refactoring safer.

- **I'd create a test/verification step earlier.** I compiled the UART init code but didn't verify it actually emitted `out` instructions until later (via `objdump -d`). Testing assumptions early matters, especially with inline assembly.

### Verification evidence

- `zig build run` compiles without errors and boots into the kernel (QEMU window, black screen, halted at `hlt`).
- `objdump -d build/kernel.elf | grep "outb\|inb\|outw"` shows real x86_64 port I/O instructions in the binary.
- The kernel successfully calls `arch.serial.init()` from `_start` without crashing.
- Moved from macOS (M1) to Arch Linux (Ryzen 9950X) mid-session; QEMU required `sudo pacman -S qemu` to get display support, but the kernel code worked unchanged across both.

### Open questions

- How do I verify the UART actually accepted the initialization? (Check status registers?)
- What happens if the divisor is wrong—does the QEMU terminal show garbage, or do characters just not appear?
- Should I add error checking to `serial.init()`, or is it safe to assume the UART is always present in QEMU?
- Next: implementing `writeByte` and `writeString` to actually *send* data and see it on the terminal.
