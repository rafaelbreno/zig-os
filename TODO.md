# Building a 64-bit x86_64 Operating System in Zig 0.16.0

## A Progressive Roadmap from Zero to a Working OS

> [!IMPORTANT]
> **How to use this roadmap**
>
> Each task follows the same structure:
> - **Why** — the concept behind it and what to go study
> - **What** — the concrete action to take
> - **Verify** — how to *see* it working (no working in the dark)
> - **Notes** — a blank space for you to write your own documentation as you go
>
> Every phase ends with a **Milestone** (a visible, demonstrable result) and a **Debug Checkpoint** (tools and techniques to inspect what's happening). Don't skip the debug checkpoints — they are how you keep your sanity.
>
> Study pointers are intentionally short. The roadmap tells you *what* to learn and *why you need it*, not the full theory. Use OSDev Wiki, Intel SDM Vol. 3, and the Zig source as your study companions.

---

## Cross-Cutting Practices

These aren't a phase — they're habits to keep from Phase 0 onward.

- [ ] **Commit often**, with messages describing *what changed and why it worked* (or didn't).
- [ ] **Keep a `docs/` folder** with one Markdown file per phase. Use the "Notes" spaces in this roadmap as the seed.
- [ ] **Re-run earlier milestones often.** Phase 8 can subtly break Phase 6; catch regressions early.
- [ ] **Use `zig build test`** for everything testable in userland (parsers, allocators, data structures).
- [ ] **Don't optimize until you measure.** Naive algorithms are fine for years.
- [ ] **Read other people's code.** Sortix, SerenityOS, Theseus, Hubris, Redox, the Linux 0.01 source. Steal ideas, never steal code (license).
- [ ] **Keep a "weird behavior" log.** Every QEMU quirk, every Intel SDM footnote that bit you. Future-you will thank you.

---

## Suggested Documentation Template (for your own notes)

For each phase, create `docs/phase_NN/README.md`:

```markdown
# Phase NN — <title>

## What I built
<one paragraph>

## What I learned (concepts)
- Concept 1: <my explanation, not copy-pasted>
- Concept 2: ...

## What surprised me
<things that didn't match the docs, or that took me hours to figure out>

## What I'd do differently
<honest postmortem>

## Verification evidence
<screenshots, serial logs, gdb sessions>

## Open questions
<things I deferred — return to these later>
```

Treat this roadmap as a scaffold for *your* documentation. The point isn't to finish the checkboxes — it's to be able to teach someone else what you learned at each step.
