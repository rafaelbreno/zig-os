# Phase 11 — ELF Loader and a Real User Program

**Goal of this phase:** Stop hand-crafting user code. Compile a separate Zig program, put it on the filesystem, and run it from your shell.

- [ ] **Study ELF loading**
  - **Why:** You parsed your kernel ELF in your head; now do it programmatically for user programs.
  - **Study:** Program headers, `PT_LOAD` segments, `p_vaddr`, `p_memsz`, `p_filesz`, the `.bss` zero-fill behavior.
  - **Verify:** You can list the steps to load a static ELF.
  - **Notes:**

- [ ] **Compile a user program**
  - **What:** Create a separate Zig project targeting `x86_64-freestanding-none` for your "userland ABI". It calls only your syscalls.
  - **Verify:** Produces a static ELF.
  - **Notes:**

- [ ] **Write the ELF loader**
  - **What:** Read ELF from VFS, map `PT_LOAD` segments to user pages, copy data, zero `.bss`, set entry point.
  - **Verify:** Load and run a "hello world" user program via syscall.
  - **Notes:**

- [ ] **Add `sys_exec` and `sys_fork` (or `sys_spawn`)**
  - **Why:** Real OSes can launch processes from user code.
  - **Study:** Tradeoffs between fork/exec vs posix_spawn vs your own design.
  - **What:** Implement at least `sys_spawn(path, argv, envp)`.
  - **Verify:** Shell program launches other programs.
  - **Notes:**

- [ ] **Add `sys_wait`**
  - **What:** Block parent until child exits; reap exit status.
  - **Verify:** Shell shows child's exit code.
  - **Notes:**

## Phase 11 Milestone

You can write a Zig program, drop it in the disk image, and run it from a shell prompt inside your OS.

## Phase 11 Debug Checkpoint

- [ ] Crash your user program deliberately (null deref, syscall with bad args). Confirm only that program dies.
- [ ] Write up: "What does my kernel do between `sys_spawn("/bin/hello")` and the first instruction of `hello`?"

---
