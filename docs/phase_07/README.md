# Phase 7 — The Kernel Heap: `malloc` and `free`

**Goal of this phase:** Use `std.ArrayList`, hash maps, and other Zig data structures in kernel code.

## 7.1 Choose and study an allocator

- [ ] **Study allocator strategies**
  - **Why:** Bump, freelist, buddy, slab — each has tradeoffs. Start with freelist (linked-list of free blocks).
  - **Study:** OSDev Wiki: "Memory Allocation". Linked-list allocators.
  - **Verify:** You can describe how splitting and coalescing work.
  - **Notes:**

- [ ] **Reserve heap virtual address range**
  - **What:** Pick a range in the higher half (e.g., `0xFFFF_8800_0000_0000` to `0xFFFF_8900_0000_0000`).
  - **Verify:** Range doesn't overlap kernel or HHDM.
  - **Notes:**

## 7.2 Implement the allocator

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

## Phase 7 Milestone

`std.ArrayList`, `std.AutoHashMap`, and other Zig data structures work in your kernel.

## Phase 7 Debug Checkpoint

- [ ] Add a `heap stats` command: total mapped, total in use, freelist length, fragmentation %.
- [ ] Write a small test suite that does adversarial alloc patterns; run it on every boot in debug builds.
- [ ] Write up: "Why is heap fragmentation harder to detect than physical frame leaks?"

---
