# Complete 64-bit x86_64 Operating System in Zig 0.16.0
## Comprehensive TODO List — Study-Then-Implement Methodology

---

## Section 1: Development Environment Setup

### Chapter 1.1: Zig 0.16.0 Installation

#### Study Phase
- [ ] Study: Zig 0.16.0 compilation pipeline and release model
- [ ] Study: Freestanding target configuration (`x86_64-freestanding-none`)
- [ ] Study: Platform-specific build requirements for your host OS

#### Implementation Phase
- [ ] Install Zig 0.16.0 and add to `$PATH`
- [ ] Verify installation: `zig version` outputs `0.16.0`
- [ ] Confirm freestanding target is available: `zig targets | grep x86_64-freestanding`

### Chapter 1.2: Additional Development Tools

#### Study Phase
- [ ] Study: QEMU emulator architecture and machine models
- [ ] Study: GDB debugging for OS/kernel development
- [ ] Study: ELF binary analysis tools and their use cases

#### Implementation Phase
- [ ] Install `qemu-system-x86_64` (version >= 8.0) and verify
- [ ] Install and configure GDB with x86_64 support
- [ ] Install Limine bootloader tools
- [ ] Install binary analysis utilities: `objdump`, `nm`, `readelf`, `hexdump`
- [ ] Install ISO creation tools: `xorriso`, `mtools`
- [ ] Run a check script confirming all tools are on `$PATH`

### Chapter 1.3: Project Structure and Build System

#### Study Phase
- [ ] Study: Zig build system architecture (`build.zig` as a Zig program)
- [ ] Study: Freestanding target configuration — no libc, no runtime
- [ ] Study: Red zone and why it must be disabled for kernel interrupt handlers
- [ ] Study: Linker script syntax and section layout concepts

#### Implementation Phase
- [ ] Create the full project directory tree:
  ```
  src/{boot/,drivers/,arch/,mm/,sched/,syscall/,fs/}
  userland/
  iso/boot/
  ```
- [ ] Create `build.zig` with `x86_64-freestanding-none` target and red zone disabled
- [ ] Attach `src/boot/boot.s` as an assembly source file
- [ ] Set `linker.ld` as the linker script; disable stack protector and PIE
- [ ] Add `iso` build step (packages ELF into bootable ISO via Limine)
- [ ] Add `run` build step (launches QEMU with `-serial stdio -m 256M -no-reboot`)
- [ ] Add `debug` build step (launches QEMU with `-s -S` for GDB attachment)
- [ ] Verify build script parses cleanly: `zig build --help`

### Chapter 1.4: Linker Script (`linker.ld`)

#### Study Phase
- [ ] Study: VMA (virtual) vs LMA (load) addresses and why they differ for a higher-half kernel
- [ ] Study: ELF section types — PROGBITS vs NOBITS (`.bss`)

#### Implementation Phase
- [ ] Define `KERNEL_PHYS_BASE`, `KERNEL_VIRT_BASE`, and `KERNEL_VMA_OFFSET` constants
- [ ] Set output format to `elf64-x86-64` and entry point to `_start`
- [ ] Place `.boot` section first (Limine header within first 32KB)
- [ ] Place `.text` (R-X), `.rodata` (R--), `.data` (RW-) with 4K alignment and correct LMAs
- [ ] Place `.bss` (NOBITS) and export `_bss_start` / `_bss_end` symbols
- [ ] Export `_kernel_start` and `_kernel_end` symbols
- [ ] Discard `.comment`, `.note*`, `.eh_frame*` sections
- [ ] Verify section VMAs with `objdump -h kernel.elf` (`.text` should be in the higher half)

---

## Section 2: Bootloader Integration and Entry

### Chapter 2.1: Limine Bootloader Setup

#### Study Phase
- [ ] Study: Limine bootloader protocol (Base Revision 3) — requests, responses, and tags
- [ ] Study: Limine entry state — already in 64-bit Long Mode with paging enabled
- [ ] Study: Limine memory map entry types (usable, reserved, bootloader-reclaimable, etc.)
- [ ] Study: Limine module request (for loading the initrd in Section 13)
- [ ] Study: Limine-Zig integration patterns

#### Implementation Phase
- [ ] Add Limine as a `build.zig` dependency (fetch via `zig fetch`)
- [ ] Create `limine.conf` with kernel path and any boot modules
- [ ] Update `linker.ld` to handle Limine request sections (`.limine_requests`)
- [ ] Create the ISO build step using `limine-deploy` on the output image

### Chapter 2.2: Kernel Entry Point

#### Study Phase
- [ ] Study: x86_64 System V ABI calling conventions
- [ ] Study: Freestanding environment requirements — no `std` runtime, manual panic handler
- [ ] Study: Limine entry state — guaranteed 64-bit, paging on, stack valid, interrupts off

#### Implementation Phase
- [ ] Create `src/main.zig` with Limine base revision request (`limine.BaseRevision`)
- [ ] Define `export fn _start() callconv(.C) noreturn` as the kernel entry point
- [ ] Verify Limine base revision is valid; halt with error if not
- [ ] Declare `extern` symbols for `_bss_start`, `_bss_end`, `_kernel_start`, `_kernel_end`
- [ ] Zero the `.bss` section manually in `_start` before calling any Zig code
- [ ] Implement `pub fn hang() noreturn` using `asm volatile ("cli; hlt")`
- [ ] Implement the required `pub fn panic(msg, trace, ret_addr) noreturn` handler
- [ ] Add stubbed `TODO` calls in `_start` for each future subsystem
- [ ] Test minimal kernel boot in QEMU; confirm no triple-fault reboot loop
- [ ] Verify Long Mode is active: open QEMU monitor (`Ctrl+Alt+2`), run `info registers`, confirm `CS` has the `l` flag

### Chapter 2.3: GDB Integration

#### Implementation Phase
- [ ] Create `kernel.gdb`: connect to `localhost:1234`, load symbols, break at `_start`
- [ ] Add convenience commands: `print-regs`, `print-cr-regs`, `print-pml4`
- [ ] Test: boot QEMU with `-s -S`, attach GDB, confirm breakpoint fires at `_start`

---

## Section 3: Basic Output — "Hello World"

### Chapter 3.1: Port I/O Primitives (`src/arch/io.zig`)

#### Implementation Phase
- [ ] Implement `outb(port: u16, value: u8)` using inline assembly (`out dx, al`)
- [ ] Implement `inb(port: u16) u8` using inline assembly (`in al, dx`)
- [ ] Implement `outw` and `inw` 16-bit variants
- [ ] Implement `ioDelay()` (write to unused port `0x80`)

### Chapter 3.2: Serial Port Driver (`src/drivers/serial.zig`)

#### Study Phase
- [ ] Study: UART 16550 register map (RBR/THR, IER, FCR, LCR, MCR, LSR) and DLAB mode
- [ ] Study: Baud rate divisor calculation and 8N1 framing
- [ ] Study: QEMU `-serial stdio` integration

#### Implementation Phase
- [ ] Define COM1 base address (`0x3F8`) and all register offset constants
- [ ] Implement `init()`: disable IRQs, set DLAB, write baud divisor, set 8N1, enable FIFO, set MCR
- [ ] Implement loopback self-test in `init()`; mark port unavailable on failure
- [ ] Implement `writeByte(byte: u8)` with busy-wait on `LSR_TX_EMPTY`
- [ ] Implement `writeString(s: []const u8)`
- [ ] Implement `writeHex(value: u64)` for address/pointer debug output
- [ ] Implement `writeDec(value: u64)` for integer debug output
- [ ] Implement log-level infrastructure: `DEBUG`, `INFO`, `WARN`, `ERROR` prefixed output
- [ ] Call `serial.init()` as the very first operation in `_start`; print kernel load address range
- [ ] Update `panic` handler to write to serial before halting
- [ ] Test: confirm output appears in terminal via `-serial stdio`

### Chapter 3.3: VGA Text Mode Driver (`src/drivers/vga.zig`)

#### Study Phase
- [ ] Study: VGA text buffer layout — `0xB8000`, 80×25, 2 bytes per cell
- [ ] Study: `*volatile T` in Zig and why it is mandatory for MMIO
- [ ] Study: VGA color attribute byte format (fg nibble, bg nibble)

#### Implementation Phase
- [ ] Define `Color` enum (`u4`) with all 16 VGA palette entries
- [ ] Implement `makeColor(fg, bg) u8`
- [ ] Define `VgaEntry` as a `packed struct(u16)` (`char: u8`, `attribute: u8`)
- [ ] Declare the VGA buffer as `*volatile [25][80]VgaEntry` pointing to `0xB8000`
- [ ] Implement `init()`: set buffer pointer, set default color, call `clear()`
- [ ] Implement `clear()`: fill buffer with blank entries, reset cursor to (0, 0)
- [ ] Implement `putChar(c: u8)` handling `\n`, `\r`, `\t`, backspace, and printable characters
- [ ] Implement `writeString(s: []const u8)` and `setColor(fg, bg)`
- [ ] Implement scroll-up when the cursor reaches row 25
- [ ] Implement `updateHardwareCursor()` via CRTC ports `0x3D4`/`0x3D5`
- [ ] Call `vga.init()` in `_start`; print a colored startup banner
- [ ] Update `panic` handler to display message on VGA with red background
- [ ] Test: confirm colored text in QEMU display window
- [ ] Test: temporarily add `@panic("test")` to verify the red panic screen works

---

## Section 4: Core Kernel Structures

### Chapter 4.1: Global Descriptor Table (`src/arch/gdt.zig`)

#### Study Phase
- [ ] Study: x86_64 segmentation model — mostly flat, but GDT still required
- [ ] Study: GDT entry format — 8-byte descriptor bit layout
- [ ] Study: TSS in 64-bit mode — 104-byte structure, IST entries, RSP0
- [ ] Study: GDT loading procedure — `lgdt`, far return trick to reload CS

#### Implementation Phase
- [ ] Define `GdtEntry` as a `packed struct(u64)` matching the hardware descriptor format
- [ ] Define the `Tss` structure as a `packed struct` (104 bytes per Intel spec)
- [ ] Build a GDT: null, kernel code, kernel data, user code, user data, TSS (16-byte entry)
- [ ] Define segment selector constants: `KERNEL_CS`, `KERNEL_DS`, `USER_CS`, `USER_DS`, `TSS_SEL`
- [ ] Define `GdtPointer` as a `packed struct` with `limit: u16` and `base: u64`
- [ ] Implement `load()`: call `lgdt`, reload CS via far return, reload DS/ES/SS
- [ ] Implement `loadTss()`: call `ltr` via inline assembly with the TSS selector
- [ ] Set `TSS.rsp0` to the kernel stack pointer (required for Ring 3 → Ring 0 transitions)
- [ ] Call `gdt.init()` early in `_start` before IDT
- [ ] Verify: QEMU monitor `info gdt` shows valid descriptors

### Chapter 4.2: Interrupt Descriptor Table (`src/arch/idt.zig`)

#### Study Phase
- [ ] Study: x86_64 interrupt/exception architecture — hardware-pushed stack frame
- [ ] Study: IDT entry format — 16-byte gate descriptor bit layout
- [ ] Study: Interrupt handling procedure — privilege checks, stack switching
- [ ] Study: Common CPU exceptions: #DE (0), #PF (14), #GP (13), #DF (8)

#### Implementation Phase
- [ ] Define `IdtEntry` as a `packed struct(u128)` matching the hardware 16-byte gate format
- [ ] Define `IdtPointer` as a `packed struct` with `limit: u16` and `base: u64`
- [ ] Implement `setEntry(vector, handler_addr, selector, flags)` helper
- [ ] Use `comptime` to generate stub handler functions for all 256 vectors
- [ ] Implement a common interrupt handler that logs vector number and halts
- [ ] Implement `load()`: populate the IDT array and call `lidt` via inline assembly
- [ ] Call `idt.init()` in `_start` after GDT; enable interrupts with `sti` after PIC init

### Chapter 4.3: Exception Handlers

#### Study Phase
- [ ] Study: Exception stack frames — hardware-pushed RIP, CS, RFLAGS, RSP, SS
- [ ] Study: Error code format for #PF, #GP, #TS, #SS, #NP, #DF
- [ ] Study: Double fault handling with IST — dedicated stack in TSS

#### Implementation Phase
- [ ] Implement dedicated handlers for exceptions 0–14, dispatching to a common handler
- [ ] Define a `CpuState` struct; save full register state (all GPRs) on exception entry
- [ ] Print a complete register dump to serial on any unhandled exception
- [ ] Implement `#PF` handler: read faulting address from `CR2`, decode error code bits
- [ ] Implement `#DF` handler on a dedicated IST stack (set IST index in TSS and IDT entry)
- [ ] Test: trigger a divide-by-zero from `_start`; verify the handler fires and prints info

---

## Section 5: Hardware Interaction

### Chapter 5.1: Programmable Interrupt Controller (`src/arch/pic.zig`)

#### Study Phase
- [ ] Study: 8259A PIC architecture — master (IRQ 0–7) and slave (IRQ 8–15) cascade
- [ ] Study: PIC remapping — move IRQs to vectors 32–47 to avoid collision with CPU exceptions
- [ ] Study: Interrupt Mask Register (IMR) and End-of-Interrupt (EOI) protocol

#### Implementation Phase
- [ ] Define master (`0x20`) and slave (`0xA0`) PIC port constants
- [ ] Implement `init()`: send ICW1–ICW4 to remap IRQs to vectors 32–47
- [ ] Implement `sendEoi(irq: u8)`: send EOI to master and conditionally to slave
- [ ] Implement `maskIrq(irq: u8)` and `unmaskIrq(irq: u8)` via the IMR
- [ ] Implement `disable()`: mask all IRQs on both PICs (for future APIC migration)
- [ ] Call `pic.init()` in `_start` before enabling interrupts

### Chapter 5.2: Programmable Interval Timer (`src/arch/pit.zig`)

#### Study Phase
- [ ] Study: 8253/8254 PIT architecture — channels, operating modes, divisor calculation
- [ ] Study: Timer interrupt (IRQ 0) — the heartbeat of the preemptive scheduler

#### Implementation Phase
- [ ] Define PIT channel 0 port (`0x40`) and command port (`0x43`) constants
- [ ] Implement `init(hz: u32)`: calculate divisor (`1193182 / hz`), program channel 0 in mode 3
- [ ] Implement IRQ0 handler: increment a global tick counter, send EOI
- [ ] Unmask IRQ0 after PIT init and enable interrupts
- [ ] Implement `getTicks() u64` returning the current tick count
- [ ] Implement `sleep(ms: u64)`: busy-wait until tick count advances by the required amount
- [ ] Test: print tick count to serial every 100 ticks; confirm it increments

### Chapter 5.3: PS/2 Keyboard (`src/drivers/keyboard.zig`)

#### Study Phase
- [ ] Study: PS/2 keyboard controller — data port (`0x60`), status/command port (`0x64`)
- [ ] Study: Scancode Set 1 — make/break codes and key mapping to ASCII

#### Implementation Phase
- [ ] Implement IRQ1 handler: read scancode from port `0x60`, push to circular buffer, send EOI
- [ ] Implement a power-of-2 circular ring buffer for scancodes
- [ ] Implement a Scancode Set 1 → ASCII translation table
- [ ] Implement `getChar() ?u8`: return next ASCII character from the buffer, or null if empty
- [ ] Implement `getLine(buf: []u8) []u8`: block until a newline is received
- [ ] Unmask IRQ1 after keyboard init
- [ ] Test: type characters in QEMU; confirm they appear via VGA `putChar`

---

## Section 6: Physical Memory Management

### Chapter 6.1: Memory Map Parsing

#### Study Phase
- [ ] Study: Limine memory map response structure and entry types
- [ ] Study: Physical memory layout — reserved regions, kernel location, MMIO holes
- [ ] Study: Memory frame concept — 4KB pages as the unit of physical allocation

#### Implementation Phase
- [ ] Add Limine memory map request to `_start`
- [ ] Create `src/mm/pmm.zig` physical memory module
- [ ] Iterate Limine memory map entries; collect and display usable regions
- [ ] Print total usable RAM to serial at boot
- [ ] Calculate and record kernel physical start and end addresses from linker symbols

### Chapter 6.2: Physical Frame Allocator — Bitmap

#### Study Phase
- [ ] Study: Bitmap allocator algorithm — 1 bit per 4KB frame, first-fit search
- [ ] Study: Frame allocator invariants — must not allocate kernel or reserved frames

#### Implementation Phase
- [ ] Place the bitmap in a usable memory region large enough to cover all physical RAM
- [ ] Implement `init(memory_map)`: size bitmap, mark all frames used, free usable regions, re-mark kernel frames as used
- [ ] Implement `allocFrame() ?u64`: find first free bit, mark used, return physical address
- [ ] Implement `freeFrame(phys_addr: u64)`: clear the corresponding bit
- [ ] Implement `allocContiguous(n: usize) ?u64`: find `n` consecutive free frames
- [ ] Implement `getStats()` returning total/free/used frame counts
- [ ] Test: allocate 10 frames; verify addresses are unique and non-overlapping with the kernel

---

## Section 7: Virtual Memory Management

### Chapter 7.1: Page Table Structures

#### Study Phase
- [ ] Study: x86_64 4-level paging hierarchy — PML4 → PDPT → PD → PT
- [ ] Study: Page sizes — 4KB (PT entry), 2MB (PD huge page), 1GB (PDPT huge page)
- [ ] Study: TLB and the `invlpg` instruction for targeted TLB invalidation
- [ ] Study: Recursive page table mapping vs HHDM — trade-offs and HHDM advantages

#### Implementation Phase
- [ ] Define `PageTableEntry` as a `packed struct(u64)` with named flag bits (Present, Writable, User, WriteThrough, NoCache, Accessed, Dirty, HugePage, Global, NX)
- [ ] Define `PageTable` as `[512]PageTableEntry`
- [ ] Implement virtual address parsing: extract PML4/PDPT/PD/PT indices from a `u64`
- [ ] Implement `setEntry` and `getPhysAddr` helpers

### Chapter 7.2: Higher-Half Kernel Mapping

#### Study Phase
- [ ] Study: Higher-half kernel concept (`0xFFFFFFFF80000000` base convention)
- [ ] Study: HHDM (Higher Half Direct Map) provided by Limine — offset for physical-to-virtual conversion
- [ ] Study: Kernel section permissions — `.text` R-X, `.rodata` R--, `.data`/`.bss` RW-

#### Implementation Phase
- [ ] Add Limine HHDM request; store the HHDM offset at boot
- [ ] Implement `physToVirt(phys: u64) u64` and `virtToPhys(virt: u64) u64`
- [ ] Access existing page tables via the HHDM offset
- [ ] Implement `newPageTable() *PageTable`: allocate a frame via PMM, zero it, return virtual pointer
- [ ] Map kernel `.text` as R-X, `.rodata` as R--, `.data`/`.bss` as RW- in a new page table
- [ ] Map VGA buffer (`0xB8000`) into the kernel virtual address space

### Chapter 7.3: Page Table Management (`src/mm/vmm.zig`)

#### Study Phase
- [ ] Study: Page walk — traversing 4 levels to reach a PT entry, creating tables on demand
- [ ] Study: Page fault handling — present bit, write fault, protection violation

#### Implementation Phase
- [ ] Implement `getOrCreateTable(parent, index, flags) *PageTable`: walk one level, allocate via PMM if not present
- [ ] Implement `mapPage(pml4, virt, phys, flags)`: walk/create all 4 levels, set the PT entry
- [ ] Implement `unmapPage(pml4, virt)`: clear the PT entry, flush TLB with `invlpg` via inline assembly
- [ ] Implement `loadPageTable(pml4_phys: u64)`: write to `CR3` via inline assembly
- [ ] Implement `cloneKernelMappings(dest_pml4)`: copy upper-half PML4 entries into a new table
- [ ] Switch to the new kernel page table with `loadPageTable`
- [ ] Improve the `#PF` handler to use VMM info for meaningful error messages
- [ ] Test: confirm kernel continues executing after the CR3 switch; print a serial confirmation

---

## Section 8: Kernel Heap Management

### Chapter 8.1: Simple Heap Allocator (`src/mm/heap.zig`)

#### Study Phase
- [ ] Study: Heap allocator requirements — alignment, minimum block size, metadata overhead
- [ ] Study: Free-list allocator design — block header, first-fit search, coalescing
- [ ] Study: Zig `std.mem.Allocator` interface — `allocFn`, `resizeFn`, `freeFn` vtable pattern

#### Implementation Phase
- [ ] Reserve a virtual address range for the kernel heap (e.g., 4MB at a fixed higher-half address)
- [ ] Map the initial heap region (e.g., first 64KB) using the VMM
- [ ] Define a `BlockHeader` struct: `size: usize`, `free: bool`, `next: ?*BlockHeader`
- [ ] Implement `init()`: place the first free block header at the heap base
- [ ] Implement `findFree(size: usize) ?*BlockHeader`: first-fit search through the free list
- [ ] Implement `splitBlock(block, size)`: split if the remainder is large enough for a header + 1 byte
- [ ] Implement `alloc(size: usize, alignment: usize) ?[*]u8`: find/split a block, mark used, return aligned pointer
- [ ] Implement `free(ptr: [*]u8)`: mark block free, coalesce with adjacent free blocks
- [ ] Implement `expandHeap()`: map additional pages from PMM when no suitable block is found

### Chapter 8.2: Zig Allocator Integration

#### Study Phase
- [ ] Study: Zig `std.mem.Allocator` vtable pattern in a freestanding context

#### Implementation Phase
- [ ] Implement `allocFn`, `resizeFn`, and `freeFn` matching the `std.mem.Allocator` interface signatures
- [ ] Create a global `std.mem.Allocator` instance backed by the heap functions
- [ ] Test: create a `std.ArrayList(u32)` using the kernel allocator; append 100 items and verify values
- [ ] Implement heap statistics tracking (peak usage, allocation count)
- [ ] Add guard pages (unmapped pages at heap boundaries) to catch overflows in debug builds
- [ ] Add allocation tracking for leak detection in debug builds

---

## Section 9: Basic Cooperative Multitasking

### Chapter 9.1: Task Structure (`src/sched/task.zig`)

#### Study Phase
- [ ] Study: Process vs thread concepts — address space ownership vs execution stream
- [ ] Study: Thread states — ready, running, blocked, zombie and valid transitions between them
- [ ] Study: Context save data — only callee-saved registers need saving across a voluntary switch

#### Implementation Phase
- [ ] Define `TaskState` enum: `ready`, `running`, `blocked`, `zombie`
- [ ] Define `CpuContext` struct holding callee-saved registers (`rbx`, `rbp`, `r12`–`r15`, `rsp`, `rip`)
- [ ] Define `Task` struct: `id: u64`, `context: CpuContext`, `state: TaskState`, `kernel_stack: []u8`, `user_stack: ?[]u8`, `page_table: ?u64`, `next: ?*Task`
- [ ] Implement an atomic task ID counter
- [ ] Implement `createTask(entry: fn() noreturn, stack_size: usize) *Task`: allocate stacks via heap, set up initial context

### Chapter 9.2: Context Switching

#### Study Phase
- [ ] Study: Context switch procedure — save callee-saved regs, swap stacks, restore, return
- [ ] Study: x86_64 callee-saved registers per System V ABI: `rbx`, `rbp`, `r12`–`r15`
- [ ] Study: Initial task setup — the first return from `contextSwitch` must jump to the entry function

#### Implementation Phase
- [ ] Implement `contextSwitch(old: *CpuContext, new: *CpuContext)` in assembly: save callee-saved regs into `old`, load from `new`, return
- [ ] Write a `taskEntryWrapper` trampoline: called when a task runs for the first time, calls the entry function, then calls `scheduler.exit()`
- [ ] Ensure a new task's initial stack frame returns into `taskEntryWrapper`
- [ ] Implement `createTask`: allocate kernel stack via heap, set `rsp` and `rip` in `CpuContext`
- [ ] Initialize the first kernel task representing the current execution context
- [ ] Test: create two tasks that print alternating messages; confirm interleaving via `yield()`

### Chapter 9.3: Round-Robin Scheduler (`src/sched/scheduler.zig`)

#### Study Phase
- [ ] Study: Round-robin scheduling — equal time slices, FIFO ready queue
- [ ] Study: Circular linked list as a ready queue — O(1) enqueue and dequeue
- [ ] Study: Yield concept — voluntary relinquishing of the CPU

#### Implementation Phase
- [ ] Maintain a circular ready queue of `*Task` pointers
- [ ] Implement `addTask(task: *Task)`: append to the ready queue
- [ ] Implement `removeTask(task: *Task)`: unlink from the ready queue
- [ ] Implement `schedule()`: pick the next ready task, call `contextSwitch`
- [ ] Implement `yield()`: move current task to back of queue, call `schedule()`
- [ ] Initialize a kernel idle task (loops calling `yield()`) as the always-ready fallback
- [ ] Test: confirm multiple cooperating tasks interleave correctly

---

## Section 10: Preemptive Multitasking

### Chapter 10.1: Timer-Based Preemption

#### Study Phase
- [ ] Study: Preemptive scheduling — the scheduler runs without task cooperation
- [ ] Study: Timer interrupt as the preemption trigger — saving the full interrupted context
- [ ] Study: Time quantum/slice — how long a task runs before forced rescheduling

#### Implementation Phase
- [ ] Add `quantum_remaining: u32` field to `Task`
- [ ] In the PIT IRQ0 handler: decrement current task's quantum; call `schedule()` when it reaches zero
- [ ] Save and restore the full interrupt frame (all GPRs, not just callee-saved) in the timer handler
- [ ] Reset quantum to a default value (e.g., 10 ticks) each time a task is scheduled
- [ ] Test: create two CPU-bound tasks with no `yield()` calls; confirm they interleave

### Chapter 10.2: Advanced Scheduler

#### Study Phase
- [ ] Study: Priority-based scheduling — multiple ready queues, one per priority level
- [ ] Study: Sleeping tasks and timer-driven wakeup — sleep queue sorted by wakeup tick
- [ ] Study: Task termination — zombie state, resource reclamation, parent notification

#### Implementation Phase
- [ ] Add `priority: u8` field to `Task`; maintain separate ready queues per priority level
- [ ] Implement `sleep(ticks: u64)`: block the current task, record wakeup tick, move to sleep queue
- [ ] In the timer handler: scan sleep queue and move tasks whose wakeup tick has passed to the ready queue
- [ ] Implement `exit()`: set task state to `zombie`, call `schedule()`
- [ ] Implement zombie reaping: free kernel stack memory of exited tasks
- [ ] Test: verify priority scheduling prefers higher-priority tasks; verify `sleep()` wakes correctly

---

## Section 11: Userspace Infrastructure

### Chapter 11.1: Ring 3 Transition

#### Study Phase
- [ ] Study: CPU privilege rings — Ring 0 (kernel) vs Ring 3 (user) and enforcement
- [ ] Study: TSS `RSP0` field — the kernel stack pointer used on Ring 3 → Ring 0 transitions
- [ ] Study: `iretq` instruction — the mechanism for transitioning to a lower privilege level
- [ ] Study: User stack setup — separate stack in user-accessible memory

#### Implementation Phase
- [ ] Ensure `TSS.rsp0` is updated to the current task's kernel stack top on every context switch
- [ ] Allocate and map a user stack page (user-accessible, RW) in the task's page table
- [ ] Implement `jumpToUserMode(entry: u64, user_stack_top: u64)`: build the `iretq` frame on the kernel stack (`rip`, `USER_CS`, `rflags=0x202`, `rsp`, `USER_DS`), execute `iretq`
- [ ] Test: transition to Ring 3 with a minimal test function that calls a syscall and returns

### Chapter 11.2: Loading User Programs

#### Study Phase
- [ ] Study: ELF64 file format — header, program headers, section headers
- [ ] Study: `PT_LOAD` program headers — `vaddr`, `filesz`, `memsz`, `flags` fields
- [ ] Study: User virtual address space layout — conventional base addresses (e.g., `0x400000`)

#### Implementation Phase
- [ ] Define `Elf64Header` and `Elf64Phdr` as `packed struct` types matching the ELF64 spec
- [ ] Implement `loadElf(data: []const u8, page_table: *PageTable) !u64`:
  - Verify ELF magic (`\x7FELF`), class (64-bit), and machine (x86_64)
  - Parse and iterate `PT_LOAD` program headers
  - Allocate physical frames and map each segment with correct flags (R/W/X, user-accessible)
  - Copy `filesz` bytes from ELF data; zero the remaining `memsz - filesz` bytes (BSS)
  - Return the ELF entry point address
- [ ] Implement `setupUserStack(page_table, size) u64`: allocate and map a user stack, return top address
- [ ] Test: load a hand-crafted minimal ELF; verify it executes in Ring 3

---

## Section 12: System Calls

### Chapter 12.1: SYSCALL/SYSRET Mechanism (`src/syscall/syscall.zig`)

#### Study Phase
- [ ] Study: `syscall`/`sysret` instructions — fast path vs `int 0x80` / `iretq`
- [ ] Study: MSR setup — `IA32_STAR` (selectors), `IA32_LSTAR` (entry point), `IA32_FMASK` (RFLAGS mask)
- [ ] Study: Syscall argument passing convention — `rax` (number), `rdi`, `rsi`, `rdx`, `r10`, `r8`, `r9`
- [ ] Study: System call numbering conventions (Linux ABI as reference)

#### Implementation Phase
- [ ] Implement `writeMsr(msr: u32, value: u64)` and `readMsr(msr: u32) u64` via inline assembly
- [ ] Set `IA32_STAR`: encode kernel CS/SS and user CS/SS selectors
- [ ] Set `IA32_LSTAR`: point to the assembly syscall entry handler
- [ ] Set `IA32_FMASK`: mask `RFLAGS.IF` on syscall entry
- [ ] Enable `syscall`/`sysret` by setting bit 0 of `IA32_EFER`
- [ ] Write `syscallEntry` in assembly: save all user registers, swap to kernel stack, call Zig dispatcher, restore user registers, `sysretq`
- [ ] Implement `syscallDispatch(frame: *SyscallFrame) u64`: dispatch on `rax` to handler functions
- [ ] Test: write a Ring 3 function that executes `syscall` with a known number; verify dispatch fires

### Chapter 12.2: System Call Interface

#### Study Phase
- [ ] Study: POSIX system call conventions — return value in `rax`, negative errno on error
- [ ] Study: Common system calls — `exit`, `write`, `read`, `open`, `close`, `yield`, `sleep`

#### Implementation Phase
- [ ] Define a `Syscall` enum: `sys_read=0`, `sys_write=1`, `sys_exit=60`, `sys_getpid=39`, `sys_yield=24`, `sys_sleep=35`, `sys_open=2`, `sys_close=3`
- [ ] Implement `sys_exit(code: u64) noreturn`: mark task zombie, call `scheduler.schedule()`
- [ ] Implement `sys_write(fd, buf_ptr, len) i64`: validate user pointer, write bytes to VGA and serial
- [ ] Implement `sys_read(fd, buf_ptr, len) i64`: block on keyboard buffer, copy bytes to user buffer
- [ ] Implement `sys_getpid() u64`: return current task ID
- [ ] Implement `sys_yield() i64`: call `scheduler.yield()`
- [ ] Implement `sys_sleep(ms: u64) i64`: call `scheduler.sleep()`
- [ ] Write syscall wrapper functions in `userland/` using `asm volatile ("syscall")`
- [ ] Test: Ring 3 program calls `sys_write`, confirms output on screen, then calls `sys_exit`

---

## Section 13: Initial RAM Disk (initrd)

### Chapter 13.1: TAR-Based initrd

#### Study Phase
- [ ] Study: Ramdisk concept — filesystem image loaded into RAM by the bootloader
- [ ] Study: USTAR TAR format — 512-byte header block layout, filename, size, checksum fields
- [ ] Study: Limine module request — how to load a binary blob alongside the kernel

#### Implementation Phase
- [ ] Add Limine module request to `_start`; parse the module tag to get start/end physical addresses
- [ ] Add a `build.zig` step that packs `initrd_root/` into `initrd.tar` using `tar`
- [ ] Copy `initrd.tar` to the ISO; add `module` line to `limine.conf`
- [ ] Define `UstarHeader` as a `packed struct` matching the 512-byte USTAR block layout
- [ ] Implement `init(mod_start, mod_end)`: store the module address range
- [ ] Implement `listFiles()`: iterate 512-byte blocks, print filenames and sizes to serial
- [ ] Implement `findFile(name: []const u8) ?[]const u8`: return a slice pointing to the file's data
- [ ] Implement `mount()`: register the initrd as the root filesystem
- [ ] Test: call `listFiles()` at boot; confirm files from `initrd_root/` appear in serial output

### Chapter 13.2: Simple Filesystem Interface (`src/fs/vfs.zig`)

#### Study Phase
- [ ] Study: VFS abstraction — a uniform interface over heterogeneous filesystems
- [ ] Study: Inode and file descriptor abstractions — separating identity from open state

#### Implementation Phase
- [ ] Define a `FileOps` struct of function pointers: `open`, `read`, `write`, `seek`, `close`
- [ ] Define an `Inode` struct: `name: [256]u8`, `size: u64`, `data: ?[*]const u8`, `ops: *const FileOps`
- [ ] Define a `FileDescriptor` struct: `inode: *Inode`, `position: u64`
- [ ] Define a per-process `FdTable` (fixed array of `?FileDescriptor`)
- [ ] Implement `vfsOpen(path: []const u8) !u32`: look up inode, allocate fd, return fd number
- [ ] Implement `vfsRead(fd: u32, buf: []u8) !usize`: call inode's `read` op, advance position
- [ ] Implement `vfsClose(fd: u32)`: release the fd table entry
- [ ] Register initrd as the root filesystem implementation
- [ ] Wire `sys_open`, `sys_read`, and `sys_close` syscalls to the VFS layer
- [ ] Test: Ring 3 program opens a file from the initrd, reads it, and prints it via `sys_write`

---

## Section 14: FAT32 Filesystem

### Chapter 14.1: FAT32 Structures

#### Study Phase
- [ ] Study: FAT32 on-disk layout — BPB, reserved sectors, FAT region, data region
- [ ] Study: Boot sector and BIOS Parameter Block (BPB) — cluster size, FAT count, root cluster
- [ ] Study: FAT table structure — 32-bit cluster chain entries, EOC marker
- [ ] Study: Short directory entries (8.3 format) — attribute, first cluster, file size fields
- [ ] Study: Long File Name (LFN) directory entries — encoding and ordering

#### Implementation Phase
- [ ] Define `Fat32Bpb`, `Fat32BootSector`, `Fat32DirEntry`, and `Fat32LfnEntry` as `packed struct` types
- [ ] Implement `parseBpb(sector_data: []const u8)`: extract cluster size, FAT offset, data offset
- [ ] Implement `readFatEntry(cluster: u32) u32`: look up the next cluster in the FAT
- [ ] Implement `followClusterChain(first_cluster: u32, callback: fn(u32))`: iterate a cluster chain
- [ ] Implement `parseDirEntries(cluster: u32)`: iterate and yield directory entries
- [ ] Implement `parseLfnName(entries: []Fat32LfnEntry, buf: []u8) []u8`: reconstruct long filename

### Chapter 14.2: FAT32 Operations

#### Study Phase
- [ ] Study: FAT32 read path — cluster chain → sector calculation → block read
- [ ] Study: FAT32 write path — find free cluster, update FAT, write data, update directory
- [ ] Study: Free cluster management — `FSInfo` sector and free cluster hint

#### Implementation Phase
- [ ] Implement `readFile(path: []const u8, buf: []u8) !usize`
- [ ] Implement `listDirectory(path: []const u8)`: print names and sizes to serial
- [ ] Implement `navigatePath(path: []const u8) ?u32`: resolve a path to a starting cluster
- [ ] Implement `writeFile(path: []const u8, data: []const u8) !void`
- [ ] Implement `createFile(dir_cluster: u32, name: []const u8) !u32`
- [ ] Implement `deleteFile(path: []const u8) !void`
- [ ] Implement `allocCluster() !u32`: find a free cluster in the FAT, mark it EOC
- [ ] Implement `freeClusterChain(first_cluster: u32)`: mark all clusters in chain as free
- [ ] Test: mount a FAT32 disk image in QEMU; read and write files end-to-end

---

## Section 15: Virtual File System (VFS) Layer

### Chapter 15.1: VFS Architecture

#### Study Phase
- [ ] Study: Full VFS abstraction — superblock, inode, dentry, and file object layers
- [ ] Study: Mount points — associating a filesystem instance with a path in the namespace
- [ ] Study: Path resolution — iterative directory lookup, handling `.` and `..`

#### Implementation Phase
- [ ] Define `VfsOps` interface (function pointer struct): `mount`, `unmount`, `lookup`, `open`, `read`, `write`, `close`
- [ ] Define `Superblock` struct: `ops: *VfsOps`, `root_inode: *Inode`, `private_data: *anyopaque`
- [ ] Define `Mount` struct: `path: []const u8`, `sb: *Superblock`, `next: ?*Mount`
- [ ] Implement `mount(path, sb)`: insert into the global mount list
- [ ] Implement `unmount(path)`: remove from the mount list, flush pending writes
- [ ] Implement `resolvePath(path: []const u8) !*Inode`: walk the mount table, iterate directory entries

### Chapter 15.2: VFS File Operations

#### Study Phase
- [ ] Study: VFS file operations abstraction — uniform `read`/`write`/`seek` over any filesystem
- [ ] Study: File position tracking — per-fd offset, `lseek` semantics
- [ ] Study: Page cache / buffer cache basics — avoiding redundant disk reads

#### Implementation Phase
- [ ] Implement generic `vfsOpen`, `vfsRead`, `vfsWrite`, `vfsSeek`, `vfsClose` dispatching through `VfsOps`
- [ ] Integrate initrd with VFS (register as a `Superblock` at `/`)
- [ ] Integrate FAT32 with VFS (register as a `Superblock` at `/mnt`)
- [ ] Test: open the same logical path through VFS regardless of which filesystem backs it

---

## Section 16: Storage Drivers

### Chapter 16.1: ATA PIO Driver (`src/drivers/ata.zig`)

#### Study Phase
- [ ] Study: ATA/IDE interface — primary channel ports (`0x1F0`–`0x1F7`, `0x3F6`)
- [ ] Study: Programmed I/O (PIO) mode — CPU-driven data transfer, 16-bit words
- [ ] Study: ATA commands — `IDENTIFY` (0xEC), `READ SECTORS` (0x20), `WRITE SECTORS` (0x30)
- [ ] Study: LBA28 addressing (28-bit sector address) and LBA48 (48-bit, for large disks)

#### Implementation Phase
- [ ] Define ATA primary/secondary channel port constants
- [ ] Implement `waitReady()`: poll `BSY` bit in the status register
- [ ] Implement `identify() !DriveInfo`: send `IDENTIFY`, read 256 words, extract geometry
- [ ] Implement `readSectors(lba: u64, count: u16, buf: []u16) !void` using LBA28
- [ ] Implement `writeSectors(lba: u64, count: u16, buf: []const u16) !void` using LBA28
- [ ] Test: read sector 0 and print the first 16 bytes to serial

### Chapter 16.2: Block Device Layer

#### Study Phase
- [ ] Study: Block device abstraction — uniform sector read/write interface over different hardware
- [ ] Study: Device registration and lookup by device ID

#### Implementation Phase
- [ ] Define `BlockDeviceOps` interface: `read_sectors`, `write_sectors`, `get_sector_count`
- [ ] Define `BlockDevice` struct: `ops: *BlockDeviceOps`, `sector_size: u32`, `private: *anyopaque`
- [ ] Implement `registerDevice(dev: *BlockDevice) u32`: add to global device table, return device ID
- [ ] Implement `blockRead(dev_id, lba, count, buf)` and `blockWrite(dev_id, lba, count, buf)` wrappers
- [ ] Connect the ATA driver to the block device layer
- [ ] Connect FAT32 to use the block device layer for sector I/O
- [ ] Test: read a FAT32 filesystem from an ATA disk image attached to QEMU

---

## Section 17: Advanced Features

### Chapter 17.1: Symmetric Multiprocessing (SMP)

#### Study Phase
- [ ] Study: APIC/LAPIC architecture — per-CPU interrupt controller, replacing the 8259A
- [ ] Study: SMP boot protocol — BSP sends INIT/SIPI to wake Application Processors
- [ ] Study: Per-CPU data structures — separate stacks, GDT, TSS, and scheduler state per core

#### Implementation Phase
- [ ] Parse the ACPI MADT table to discover LAPIC and IOAPIC entries
- [ ] Implement LAPIC initialization (enable, set spurious vector, configure timer)
- [ ] Implement IOAPIC initialization (map external IRQs to LAPIC vectors)
- [ ] Add Limine SMP request; iterate Limine-provided CPU entries
- [ ] Write AP startup code: initialize GDT, IDT, and per-CPU scheduler state on each AP
- [ ] Allocate per-CPU kernel stacks and update TSS for each core
- [ ] Implement `SpinLock` using `@atomicRmw` for SMP-safe critical sections
- [ ] Test: print a per-core boot message from each AP to serial

### Chapter 17.2: Basic Networking

#### Study Phase
- [ ] Study: Network stack layers — link (Ethernet), network (IP), transport (UDP/TCP)
- [ ] Study: Ethernet frame format — preamble, MAC addresses, EtherType, payload, FCS
- [ ] Study: IPv4 packet format — header fields, checksum, fragmentation
- [ ] Study: ARP protocol — request/reply, cache maintenance

#### Implementation Phase
- [ ] Implement a NIC driver (e.g., RTL8139 or `virtio-net` for QEMU)
- [ ] Implement Ethernet frame send/receive
- [ ] Implement an ARP cache: `lookupMac(ip) ?[6]u8`, update on received ARP replies
- [ ] Implement IPv4 packet parsing and forwarding to upper-layer handlers
- [ ] Implement ICMP echo reply (respond to ping)
- [ ] Test: ping the kernel from the host via QEMU user networking

### Chapter 17.3: Userspace C Library (`userland/libc/`)

#### Study Phase
- [ ] Study: C standard library components required for basic programs
- [ ] Study: System call wrapper conventions for the C ABI

#### Implementation Phase
- [ ] Implement string functions: `strlen`, `strcpy`, `strcmp`, `memcpy`, `memset`, `memmove`
- [ ] Implement syscall wrappers matching the Linux x86_64 ABI: `write`, `read`, `exit`, `open`, `close`
- [ ] Implement `printf` (subset: `%s`, `%d`, `%x`, `%c`) backed by `sys_write`
- [ ] Implement `malloc` / `free` backed by a `sys_brk`-like heap expansion syscall
- [ ] Compile user programs linking against this custom libc
- [ ] Test: a C-style user program calls `printf("Hello from libc!\n")` and exits cleanly

---

## Appendix: Testing and Debugging Infrastructure

### Automated Testing
- [ ] Add a `test` build step to `build.zig` that boots QEMU non-interactively and checks serial output
- [ ] Implement `assert(condition: bool, msg: []const u8)` using `@panic` with `@src()` location
- [ ] Write unit tests for the PMM (alloc/free/double-free detection)
- [ ] Write unit tests for the VMM (map/unmap/TLB flush)
- [ ] Write unit tests for the TAR parser (list/find on a known archive)
- [ ] Write an integration test: boot kernel, confirm shell prompt appears in serial output within 5 seconds

### Debugging Tools
- [ ] Extend `kernel.gdb` with helpers: `print-pml4`, `print-task-list`, `print-heap`, `print-idt`
- [ ] Implement `dumpMemory(addr: u64, len: usize)`: print a hex+ASCII dump to serial
- [ ] Add compile-time log level filtering (`DEBUG` logs everything; `ReleaseSafe` logs `WARN`+)
- [ ] Add `@src()` file and line number to all panic messages
- [ ] Implement a basic kernel debugger: breakpoint on `Ctrl+Alt+D`, print task list and register state

### Documentation
- [ ] Document kernel architecture and subsystem initialization order
- [ ] Create API documentation for each public module interface
- [ ] Write a developer guide covering the build system, debug workflow, and adding new syscalls
- [ ] Document the build process end-to-end (dependencies → ISO → QEMU)
- [ ] Create a troubleshooting guide for common failures (triple fault, black screen, GPF on boot)
