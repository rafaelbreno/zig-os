# Phase 13 — Beyond the Single Core (SMP)

**Goal of this phase:** Use all the CPUs QEMU exposes.

- [ ] **Study SMP startup**
  - **Why:** Bringing up additional cores ("APs") requires the LAPIC, an MP wakeup protocol, and per-CPU data.
  - **Study:** Limine's SMP request (it does the hard part of getting APs out of real mode for you). Per-CPU storage via GS.MSR.
  - **Verify:** You can list what state each AP starts in.
  - **Notes:**

- [ ] **Boot the APs**
  - **What:** Make a Limine SMP request; in the entry callback, set up GDT/IDT/CR3/GS for that core; mark ready.
  - **Verify:** Log "CPU N online" for every core. Count matches QEMU's `-smp`.
  - **Notes:**

- [ ] **Per-CPU data**
  - **What:** A struct per CPU, accessed via GS base.
  - **Verify:** Each core prints a different `cpu_id`.
  - **Notes:**

- [ ] **Make the scheduler SMP-aware**
  - **Why:** Each CPU now picks tasks from a shared (or per-CPU) ready queue.
  - **Study:** Per-CPU vs global run queues. Load balancing.
  - **What:** Start with a single global queue + spinlock. Profile later.
  - **Verify:** All cores show usage during a multi-task workload.
  - **Notes:**

- [ ] **Audit locks**
  - **What:** Every shared data structure needs a real lock now.
  - **Verify:** Stress test for an hour with no corruption.
  - **Notes:**

## Phase 13 Milestone

`qemu-system-x86_64 -smp 4` and your OS uses all four cores.

## Phase 13 Debug Checkpoint

- [ ] Add a `topology` debug command showing CPUs, their states, and current tasks.
- [ ] Write up: "What changed in my kernel to go from 1 to N cores?"

---

