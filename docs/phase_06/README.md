# Phase 6 — Virtual Memory: Building Your Address Space

**Goal of this phase:** Control the page tables. Map and unmap virtual addresses at will. Survive page faults gracefully.

## 6.1 Understand x86_64 paging

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

## 6.2 Inspect existing tables

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

## 6.3 Build your own page tables

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
  - **Verify:** After unmap, accessing the address triggers a PF.
  - **Notes:**

- [ ] **Build your own PML4 and switch to it**
  - **Why:** You should own the address space, not Limine.
  - **What:** Allocate a new PML4. Copy Limine's higher-half entries (so kernel + HHDM still work). Load it into CR3.
  - **Verify:** Print "still alive" *after* loading CR3. If it works, your kernel is now running on its own page tables.
  - **Notes:**

## 6.4 Page fault handler upgrade

- [ ] **Read CR2 in PF**
  - **Why:** CR2 holds the faulting virtual address — essential for debugging.
  - **What:** In your PF handler, read CR2 and decode the error code (P, W/R, U/S, RSVD, I/D bits).
  - **Verify:** Trigger a fault by reading address `0x1`. Handler prints: "Page Fault at 0x1, present=0, write=0, user=0".
  - **Notes:**

## Phase 6 Milestone

You own your address space. You can map and unmap pages anywhere you want. Page faults give you actionable information.

## Phase 6 Debug Checkpoint

- [ ] Write a `vmem dump <vaddr>` command that prints the full walk of a virtual address.
- [ ] In QEMU monitor: `info tlb`, `info mem`. Compare to your own dumps.
- [ ] Map the same physical frame at two different virtual addresses; write through one, read through the other.
- [ ] Write up: "The full journey of `mov rax, [0xFFFFFFFF80001000]` through my page tables."

---
