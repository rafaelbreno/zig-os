# Phase 9 — User Space: Ring 3 and Syscalls

**Goal of this phase:** Run untrusted code in Ring 3. It can't crash the kernel. It can only ask for things via syscalls.

## 9.1 Prepare the GDT and TSS

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

## 9.2 The first user task

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
  - **Verify:** First user instruction runs. If you instead get a GP, recheck selector RPLs.
  - **Notes:**

## 9.3 Syscalls

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

## Phase 9 Milestone

A user-mode program runs, makes syscalls, and cannot crash your kernel even when it deliberately tries.

## Phase 9 Debug Checkpoint

- [ ] Try every "bad" thing in user mode: write to CR3, execute `cli`, read kernel memory. Confirm each generates a GP or #PF caught by your kernel.
- [ ] Use GDB to step into the syscall stub from a breakpoint in the user program.
- [ ] Write up: "What is on the stack at each step from `syscall` to my Zig dispatcher and back?"

---
