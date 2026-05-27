# Phase 3 — CPU Foundations: GDT, IDT, and Catching Crashes

**Goal of this phase:** When something goes wrong (and it will, daily), you see a crash dump instead of a silent reboot.

## 3.1 The Global Descriptor Table (GDT)

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

## 3.2 The Interrupt Descriptor Table (IDT)

- [ ] **Study x86_64 interrupts**
  - **Why:** Every CPU exception (divide by zero, page fault, etc.) and every hardware interrupt needs an entry in the IDT.
  - **Study:** IDT entry format (interrupt gate vs trap gate), the IST mechanism, exceptions 0-31 (memorize the important ones: 0 #6 #8 #13 #14).
  - **What:** Read OSDev Wiki: "Interrupt Descriptor Table" and "Exceptions".
  - **Verify:** You can list what exceptions 13 (GP) and 14 (#PF) mean.
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
  - **What:** Write a `interruptDispatch(frame: *InterruptFrame)` Zig function. For now, for exceptions 0-31, print the vector, error code, RIP, RSP, RFLAGS, and CR2 (for PF), then halt.
  - **Verify:** The function compiles and is exported.
  - **Notes:**

- [ ] **Load the IDT**
  - **What:** Populate the 256 entries with pointers to your stubs. Call `lidt`.
  - **Verify:** Print the IDTR via `sidt` after loading. Values match.
  - **Notes:**

## 3.3 Test your safety net

- [ ] **Trigger a divide-by-zero**
  - **Why:** Confirms exception delivery works.
  - **What:** Inline assembly: `xor rdx, rdx; xor rcx, rcx; div rcx`.
  - **Verify:** Your handler prints "Exception 0: Divide Error" with register dump. No QEMU reboot.
  - **Notes:**

- [ ] **Trigger a UD (invalid opcode)**
  - **What:** Inline assembly: `ud2`.
  - **Verify:** Handler prints "Exception 6: Invalid Opcode".
  - **Notes:**

- [ ] **Trigger a PF (page fault)**
  - **What:** Dereference address `0xDEADBEEFDEAD`.
  - **Verify:** Handler prints "Exception 14: Page Fault" and the faulting address (from CR2) matches.
  - **Notes:**

## Phase 3 Milestone

Any CPU exception now produces a readable crash dump on screen and serial. No more silent reboots.

## Phase 3 Debug Checkpoint

- [ ] In QEMU monitor, run `info registers` after a crash. Confirm RIP matches your dump.
- [ ] Use `-d int,cpu_reset` in QEMU to see the *emulator's* view of exceptions. Compare to your handler's view.
- [ ] Write a deliberately bad program that hits 3-4 different exceptions in sequence; verify each is caught.
- [ ] Write up: "Walk through one interrupt from CPU detection to your Zig dispatcher."

---
