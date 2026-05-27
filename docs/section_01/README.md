# Section 1: Development Environment Setup

## Chapter 1.1: Zig 0.16.0 Installation

### Zig 0.16.0 compilation pipeline and release model

#### Release Model
Zig uses a rolling pre-1.0 release model, meaning, every release can and does introduce _MAJOR_ breaking changes; so always check the version of Zig used in any resource you're studying/checking, it must match the version you're using.

#### Compilation Pipeline
The Zig compilation pipeline is a multi-stage architecture that transforms the Zig code through several intermediate representations, and then generates machine code.

When you run `zig build`, the following happens:
1. **Zig Code -> ZIR(Zig Intermediate Representation):** 
    - The AST is lowered to ZIR
2. **ZIR -> AIR(Analyzed Intermediate Representation):** 
    - Sema(Semantic Analysis Engine), transforms the untyped ZIR instructions into semantically analyzed AIR.
3. **Air -> Backend:**
    - Code generation, translates AIR into target-specific machine code.

See: [Compilation Pipeline Overview](https://zread.ai/ziglang/zig/13-compilation-pipeline-overview)

---

### Freestanding target configuration (`x86_64-freestanding-none`)

#### What Is a Target Triple?
Zig uses a **target triple** in the format `architecture-os-abi` to describe the environment the compiled binary will run in:
- **`x86_64`** — the CPU architecture (64-bit Intel/AMD)
- **`freestanding`** — no operating system; the code runs directly on hardware with no OS services available
- **`none`** — no ABI (Application Binary Interface), because there is no OS to define calling conventions at the system level

For kernel development this is the only valid target. You are *building* the OS, so there is no OS to target.

#### What "Freestanding" Actually Means
When you specify `freestanding`, the Zig compiler makes the following guarantees and imposes the following constraints:

- **No `std` OS layer:** Anything in `std` that touches the OS — file I/O, threads, signals, memory allocation backed by `mmap`/`VirtualAlloc` — is unavailable. You cannot call `std.debug.print` because it ultimately calls a write syscall that doesn't exist.
- **No libc:** There is no C runtime, no `malloc`, no `printf`, no startup code (`crt0`). The compiler will not link any C runtime objects.
- **No entry point shim:** Zig's `std/start.zig` normally wraps your `main` with startup boilerplate (stack alignment, argument parsing, etc.). With `freestanding`, none of that is injected. Your `export fn _start()` is the literal first instruction the CPU executes after the bootloader hands off control.
- **No panic handler provided:** You must define `pub fn panic(...)` yourself. The compiler will refuse to compile without it.
- **`comptime` and pure Zig std still work:** The parts of `std` that are pure Zig with no OS calls — `std.mem`, `std.math`, `std.fmt` (write-to-buffer variant), `std.ArrayList` backed by your own allocator — all work fine.

#### Configuring the Target in `build.zig`
In the build script, the freestanding target is set via `resolveTargetQuery`:

```zig
const target = b.resolveTargetQuery(.{
    .cpu_arch = .x86_64,
    .os_tag   = .freestanding,
    .abi      = .none,
});
```

Along with the target, two additional settings are **mandatory** for kernel code:

**1. Code model — `.kernel`**
```zig
.code_model = .kernel,
```
The default code model assumes code and data live within a 2GB window (using 32-bit relative addressing). A higher-half kernel is mapped at addresses like `0xFFFFFFFF80000000`, which are far outside that window. The `.kernel` code model tells the compiler to use 64-bit absolute addressing for all references, preventing silent misaddressing bugs.

**2. Disable the red zone**
```zig
.red_zone = false,
```
The System V x86_64 ABI reserves 128 bytes *below* the current stack pointer as a "red zone" — a scratch area that a function may use without adjusting `rsp`. Hardware interrupts and exceptions do not respect this; they will write their interrupt frame directly below `rsp`, overwriting whatever is in the red zone. For kernel code that handles interrupts, the red zone **must** be disabled or you get silent stack corruption.

**3. Disable SIMD (SSE/AVX)**
```zig
.cpu_features_sub = std.Target.x86.featureSet(&.{ .avx, .avx2, .sse, .sse2, .mmx }),
```
The CPU's SIMD unit (SSE, AVX) state is part of the hardware context. When an interrupt fires mid-computation, the interrupted task's SIMD registers are live. If the interrupt handler uses SIMD instructions, it will corrupt those registers. Until you implement full SIMD state save/restore in your context switch and interrupt entry code, SIMD must be disabled entirely for the kernel. The compiler will then never emit SSE/AVX instructions and will use software floating point instead.

#### Verifying the Target Is Available
```sh
zig targets | grep freestanding
```
This should output `x86_64-freestanding-none` among others, confirming the compiler supports it.

---

### Platform-specific build requirements for your host OS

#### The Key Advantage: Zig Is a Cross-Compiler By Default
Unlike GCC or Clang, which typically require a separate cross-compilation toolchain to target a different architecture or OS, Zig bundles its own LLVM backend and linker. This means **cross-compiling to `x86_64-freestanding-none` works out of the box on any host** — Linux (x86_64 or ARM), macOS (Intel or Apple Silicon), or Windows — without installing any additional compiler infrastructure.

The Zig compiler binary itself is the only thing needed to produce the kernel ELF. The platform differences only arise for the *surrounding tooling* used to package and run the kernel.

#### Linux (Recommended Host)
Linux is the path-of-least-resistance host for OS development. All required tools are available in every major distribution's package manager.

```sh
# Debian/Ubuntu
sudo apt install qemu-system-x86 xorriso mtools gdb binutils

# Arch Linux
sudo pacman -S qemu-system-x86 xorriso mtools gdb binutils

# Fedora
sudo dnf install qemu-system-x86 xorriso mtools gdb binutils
```

Key notes:
- `qemu-system-x86_64` runs your kernel in a full hardware emulation sandbox.
- `xorriso` creates bootable ISO 9660 images — required by the Limine ISO build step.
- `mtools` lets Limine manipulate FAT filesystems inside the ISO image without root privileges.
- `gdb` attaches to QEMU's GDB stub for source-level kernel debugging.
- `binutils` provides `objdump`, `nm`, `readelf` for inspecting the kernel ELF.

#### macOS
All tools are available via Homebrew. Note that macOS uses Mach-O binaries natively, but since Zig handles all cross-compilation internally, the host binary format is irrelevant — the output is always ELF.

```sh
brew install qemu xorriso mtools
brew install --cask gdb   # or: brew install gdb (may require codesigning)
```

**Important macOS-specific issues:**
- **GDB codesigning:** macOS requires GDB to be codesigned before it can attach to processes. Follow the [GDB codesigning guide](https://sourceware.org/gdb/wiki/PermissionsDarwin) after installation, or use `lldb` with its GDB-compatibility mode as an alternative.
- **`xorriso` on macOS:** Homebrew's `xorriso` package works correctly. Do not use the version that comes with some older Xcode command-line tools bundles as it may be outdated.
- **KVM unavailable:** QEMU on macOS cannot use KVM (Linux-only kernel virtualization). On Apple Silicon, QEMU uses HVF (Hypervisor.framework) instead. For an x86_64 kernel target on Apple Silicon, QEMU will use software emulation (TCG), which is slower. For development purposes this is fine; your kernel will boot in seconds regardless.

#### A Note on ARM Hosts (Apple Silicon, Raspberry Pi, etc.)
Zig cross-compiles to `x86_64-freestanding-none` from any host architecture without issue. QEMU on an ARM host will emulate the x86_64 CPU in software (TCG mode), which is slower than native execution but fully correct. All debugging and testing workflows work identically.
