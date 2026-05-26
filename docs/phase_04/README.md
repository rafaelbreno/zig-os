# Phase 4 — Hardware Interrupts: Timer, Keyboard, and Time Itself

**Goal of this phase:** Your kernel can react to the outside world. You can type. Time passes.

## 4.1 The legacy PIC (start here, then upgrade)

- [ ] **Study the 8259 PIC**
  - **Why:** The PIC routes hardware IRQs (timer, keyboard, etc.) to the CPU. Real systems use the APIC, but the PIC is simpler — start here, switch to APIC in Phase 4.4.
  - **Study:** PIC initialization (the 4 ICW bytes). IRQ-to-vector mapping. Why default vectors conflict with CPU exceptions.
  - **What:** Read OSDev Wiki: "8259 PIC".
  - **Verify:** You can list which IRQ goes to which device (IRQ0 = PIT, IRQ1 = keyboard).
  - **Notes:**

- [ ] **Remap the PIC**
  - **Why:** Default IRQ vectors (8-15) collide with CPU exceptions. Move them to 32-47.
  - **What:** Send ICW1-4 to ports `0x20/0x21` (master) and `0xA0/0xA1` (slave). Mask all IRQs initially.
  - **Verify:** Print PIC mask registers — all bits set (all masked).
  - **Notes:**

- [ ] **Wire IRQ handlers into the IDT**
  - **What:** For vectors 32-47, install handlers that call your dispatcher and then send EOI to the PIC.
  - **Verify:** Code path compiles; no IRQs unmasked yet.
  - **Notes:**

## 4.2 The PIT (your first ticking clock)

- [ ] **Study the 8253/8254 PIT**
  - **Why:** The PIT is the simplest way to get a periodic timer. Configure once, fires forever.
  - **Study:** PIT modes (especially mode 2 and mode 3), how to compute the divisor for a target frequency.
  - **What:** Read OSDev Wiki: "Programmable Interval Timer".
  - **Verify:** You can compute the divisor for 100 Hz (~11932).
  - **Notes:**

- [ ] **Configure the PIT for 100 Hz**
  - **Why:** Start slow. 1000 Hz can be too fast for early debugging.
  - **What:** Write to PIT ports (`0x40-0x43`) to set mode 3 at 100 Hz.
  - **Verify:** Code runs without faulting.
  - **Notes:**

- [ ] **Install a PIT handler**
  - **What:** On IRQ0, increment a `ticks` counter. Log `ticks` every 100 ticks.
  - **Verify:** Unmask IRQ0 on the PIC. Enable interrupts (`sti`). You see "ticks: 100" once per second on serial.
  - **Notes:**

## 4.3 The keyboard

- [ ] **Study the PS/2 keyboard**
  - **Why:** QEMU emulates a PS/2 keyboard regardless of your host. Scancodes come in via port `0x60`.
  - **Study:** PS/2 controller, scancode set 1 vs 2, make/break codes.
  - **What:** Read OSDev Wiki: "PS/2 Keyboard".
  - **Verify:** You can describe what happens when you press and release the `A` key.
  - **Notes:**

- [ ] **Install a keyboard handler**
  - **What:** On IRQ1, read port `0x60`, log the raw scancode.
  - **Verify:** Type in QEMU — raw scancodes log to serial.
  - **Notes:**

- [ ] **Build a scancode-to-ASCII map**
  - **What:** Create a lookup table for scancode set 1, lowercase only.
  - **Verify:** Pressing keys prints letters to the console.
  - **Notes:**

- [ ] **Add modifier state**
  - **What:** Track shift, ctrl, alt press/release. Handle uppercase, basic symbols.
  - **Verify:** Shift+A produces `A`, not `a`.
  - **Notes:**

- [ ] **Build a keyboard event ring buffer**
  - **Why:** You don't want your IRQ handler doing heavy work. It posts events to a buffer; consumers drain it later.
  - **What:** Implement a fixed-size circular buffer of `KeyEvent`. IRQ enqueues; a `pollKey()` API dequeues.
  - **Verify:** Buffer doesn't drop keys under fast typing.
  - **Notes:**

## 4.4 Upgrade: LAPIC and IOAPIC

> Don't skip this. Multitasking, SMP, and modern timers all require the APIC.

- [ ] **Study the LAPIC and IOAPIC**
  - **Why:** PIC is single-CPU and legacy. APIC is per-CPU and is what real systems use.
  - **Study:** LAPIC registers, IOAPIC redirection entries, MSI basics, the role of ACPI in finding them.
  - **What:** Read OSDev Wiki: "APIC".
  - **Verify:** You can explain the difference between LAPIC and IOAPIC.
  - **Notes:**

- [ ] **Find the LAPIC base**
  - **Why:** ACPI's MADT table tells you where the LAPIC and IOAPICs are mapped.
  - **Study:** ACPI RSDP/XSDT/MADT tables. (Limine provides the RSDP address.)
  - **What:** Walk ACPI tables, find MADT, parse LAPIC and IOAPIC entries.
  - **Verify:** Log the LAPIC base address.
  - **Notes:**

- [ ] **Disable the PIC, enable the LAPIC**
  - **What:** Mask all IRQs on both PICs. Enable LAPIC via its spurious interrupt vector register.
  - **Verify:** PIT interrupts stop (until you redirect via IOAPIC).
  - **Notes:**

- [ ] **Route keyboard IRQ through the IOAPIC**
  - **What:** Program the IOAPIC redirection entry for IRQ1 → vector 33 → your LAPIC.
  - **Verify:** Typing works again, now via APIC.
  - **Notes:**

- [ ] **Set up the LAPIC timer**
  - **Why:** Replaces the PIT for scheduling. Per-CPU, much higher resolution.
  - **Study:** LAPIC timer modes (one-shot, periodic, TSC-deadline). Calibrating against the PIT or HPET.
  - **What:** Calibrate the LAPIC timer using the PIT for a known interval, then set it to periodic mode at 1000 Hz.
  - **Verify:** Your `ticks` counter now advances via the LAPIC timer.
  - **Notes:**

## Phase 4 Milestone

Your kernel is "alive" — time passes, keys are received, and you've upgraded from legacy PIC to APIC. You can type at a prompt.

## Phase 4 Debug Checkpoint

- [ ] Add a `uptime` log line printed every 5 seconds. Confirm steady cadence.
- [ ] Print every IRQ as it fires (toggle with a flag for noise control).
- [ ] Use QEMU's `-d int` to compare interrupt deliveries against your logs.
- [ ] Write up: "The path of one keystroke: from QEMU's PS/2 model to my ring buffer."

---
