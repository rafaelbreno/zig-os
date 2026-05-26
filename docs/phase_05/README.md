# Phase 5 — Physical Memory: Counting the RAM

**Goal of this phase:** Know what RAM exists, what's safe to touch, and be able to hand out 4 KiB physical frames on demand.

## 5.1 Read the memory map

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

## 5.2 The bitmap frame allocator

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

## Phase 5 Milestone

You can allocate and free physical 4 KiB frames. You know exactly how much RAM is usable and how much is currently in use.

## Phase 5 Debug Checkpoint

- [ ] Add a `pmem` debug command (via your keyboard input) that prints allocator stats.
- [ ] In GDB, examine the bitmap memory directly with `x/256xb`. Confirm bits match what you logged.
- [ ] Write up: "What goes wrong if I forget to mark MMIO regions as used?"

---
