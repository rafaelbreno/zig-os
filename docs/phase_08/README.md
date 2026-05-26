# Phase 8 — Multitasking: From One Thread to Many

**Goal of this phase:** Two kernel tasks run concurrently. Then ten. Then preemptively. Then with sleep.

## 8.1 Cooperative tasks

- [ ] **Define the Task struct**
  - **Why:** Each task needs its own stack, register state, ID, and a list link.
  - **Study:** Callee-saved vs caller-saved registers in SysV x86_64 ABI. What "context" means in a context switch.
  - **What:** Define `Task { id, state, kernel_stack, rsp, next }`.
  - **Verify:** Compiles. `@sizeOf(Task)` is reasonable.
  - **Notes:**

- [ ] **Write `contextSwitch(old: **Task, new: *Task)`**
  - **Why:** Save old task's callee-saved regs to its stack, save its RSP, load new RSP, restore new task's callee-saved regs, return.
  - **What:** Write this in naked assembly. Only callee-saved registers (RBX, RBP, R12-R15) need pushing.
  - **Verify:** Inspect disassembly — exactly the pushes/pops you expect.
  - **Notes:**

- [ ] **Bootstrap a new task's stack**
  - **Why:** A brand-new task has nothing on its stack. You must hand-craft the initial frame so the first `contextSwitch` lands at the task's entry function.
  - **What:** Write `taskCreate(entry_fn)`: allocate a stack, push fake register values + entry address, save RSP in the Task struct.
  - **Verify:** Create two tasks that each call `log.info("hello from task N")` in a loop.
  - **Notes:**

- [ ] **Implement cooperative `yield()`**
  - **What:** Move current task to the back of the ready queue; pick the next task; context switch.
  - **Verify:** Both tasks alternate output. Counter values match expected sequence.
  - **Notes:**

## 8.2 Preemptive scheduling

- [ ] **Hook the LAPIC timer into the scheduler**
  - **Why:** Tasks shouldn't have to be polite.
  - **Study:** What "preemption" means and why it must be careful (interrupts must be disabled in critical sections).
  - **What:** In the timer IRQ handler, after a fixed quantum, call `yield()`.
  - **Verify:** Two tasks that never yield voluntarily still alternate output.
  - **Notes:**

- [ ] **Add task states**
  - **What:** Enum: `running`, `ready`, `blocked`, `sleeping`, `zombie`.
  - **Verify:** State transitions log correctly.
  - **Notes:**

- [ ] **Implement `sleep(ms)`**
  - **What:** Mark task `sleeping`, store wake-up tick, remove from ready queue. In timer handler, walk sleepers and wake any whose time has come.
  - **Verify:** `sleep(1000)` actually sleeps for ~1 second.
  - **Notes:**

## 8.3 Synchronization primitives

- [ ] **Study locks at single-CPU level**
  - **Why:** Even single-CPU kernels need to protect against IRQ-vs-task races.
  - **Study:** Why you can't just `cli` for everything. Spinlocks with IRQ disable/restore.
  - **Verify:** You can describe a race between a task and an IRQ handler touching the same list.
  - **Notes:**

- [ ] **Implement an IRQ-safe spinlock**
  - **What:** `acquire()` saves the RFLAGS interrupt bit, disables IRQs, takes the lock. `release()` releases and restores.
  - **Verify:** Wrap your ready queue operations in the lock. Stress test with many tasks.
  - **Notes:**

- [ ] **Implement a semaphore and a mutex**
  - **What:** Built on top of the spinlock + wait queues. Mutex sleeps the task instead of spinning.
  - **Verify:** Producer/consumer test with bounded buffer works without lost or duplicated items.
  - **Notes:**

## Phase 8 Milestone

You have a real multitasking kernel. Dozens of tasks can run; some sleep; some block on locks. The screen and serial both reflect this concurrency.

## Phase 8 Debug Checkpoint

- [ ] Add a `ps` debug command listing all tasks, states, CPU time used.
- [ ] Add stack-canary checks to detect stack overflow in a task.
- [ ] Run a stress test: 100 tasks doing random sleep+work+yield. Confirm no crash for 10 minutes.
- [ ] Write up: "Step-by-step what happens inside `contextSwitch` for the first switch from task A to task B."

---
