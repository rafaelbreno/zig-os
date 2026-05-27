# Phase 12 — A Real Shell and the User Experience

**Goal of this phase:** You have a usable interactive system.

- [ ] **Move the keyboard handling into user space**
  - **What:** Add `sys_read` from `/dev/kbd` (or stdin). The kernel exposes the keyboard event queue as a file.
  - **Verify:** User program reads keystrokes via standard `read`.
  - **Notes:**

- [ ] **Build a TTY layer**
  - **What:** Line editing, canonical mode, echo on/off, basic cursor control.
  - **Verify:** Typing into the shell shows characters; backspace works; enter submits.
  - **Notes:**

- [ ] **Write a shell as a user program**
  - **What:** Reads lines, tokenizes, looks up `/bin/<cmd>`, spawns, waits.
  - **Verify:** `ls`, `cat`, `echo`, `pwd` work as separate binaries.
  - **Notes:**

- [ ] **Add pipes**
  - **Why:** The killer feature of unix.
  - **What:** `sys_pipe(fds: [2]i32)`. In-kernel buffer with reader/writer file descriptors.
  - **Verify:** `ls | cat` shows the listing.
  - **Notes:**

- [ ] **Add basic redirection**
  - **What:** Parse `>` and `<` in the shell; `sys_dup2` to wire FDs before exec.
  - **Verify:** `echo hi > /file && cat /file` prints `hi`.
  - **Notes:**

## Phase 12 Milestone

You have a working unix-like shell on your own OS. You can pipe `ls | cat`. This is the moment to take a video for your future self.

## Phase 12 Debug Checkpoint

- [ ] Run a 10-command session entirely in your shell. Note every bug; fix them.
- [ ] Write up: "From keypress to the prompt re-appearing — every layer involved."
