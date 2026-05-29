/*
 * KERNEL_VADDR_BASE is the base of the higher-half virtual address space.
 * The kernel lives in the upper half (0xFFFFFFFF80000000+), leaving the
 * lower half free for future user-space programs. This value is used as the
 * offset for converting virtual addresses back to physical ones via AT().
 */
KERNEL_VADDR_BASE = 0xFFFFFFFF80000000;

/*
 * KERNEL_VADDR_TEXT is where the kernel's first section actually starts.
 * It sits 1 MiB above the base, so the corresponding physical load address
 * lands at 0x100000 (1 MiB) — the classic, safe spot for a kernel image,
 * clear of the low-memory regions reserved by the firmware/BIOS.
 */
KERNEL_VADDR_TEXT = 0xFFFFFFFF80100000;

/*
 * ENTRY(symbol) sets the entry point of the executable.
 * The linker records _start as the first instruction to run.
 * This must match the symbol exported from Zig code.
 */
ENTRY(_start);

/*
 * SECTIONS defines how input sections are organized into output sections
 * and where each one is placed in virtual memory.
 */
SECTIONS
{
  /*
   * The location counter (`.`) tracks the current virtual address.
   * Starting it at KERNEL_VADDR_TEXT means the first section (.text)
   * begins at 0xFFFFFFFF80100000.
   */
  . = KERNEL_VADDR_TEXT;

  /*
   * .text section: executable code (plus read-only data).
   *
   * ALIGN(4K) forces this section to start on a 4 KiB page boundary.
   * AT(...) sets the *physical* load address: the bootloader loads the bytes
   * there, while the CPU executes them at the *virtual* address on the left.
   * ADDR(.text) is the virtual address; subtracting KERNEL_VADDR_BASE yields
   * the physical address (0xFFFFFFFF80100000 - 0xFFFFFFFF80000000 = 0x100000).
   */
  .text ALIGN(4K) : AT(ADDR(.text) - KERNEL_VADDR_BASE)
  {
    /* Collect all .text input sections from every object file. */
    *(.text)

    /* Read-only data (strings, constants) lives with the code. */
    *(.rodata*)
  }

  /*
   * .data section: initialized global/static variables.
   * Same virtual/physical split pattern as .text via AT(...).
   */
  .data ALIGN(4K) : AT(ADDR(.data) - KERNEL_VADDR_BASE)
  {
    *(.data)
  }

  /*
   * .bss section: uninitialized data, zeroed at runtime.
   * Not stored in the ELF file itself (only its size is recorded).
   * COMMON holds symbols not assigned to a specific section.
   */
  .bss ALIGN(4K) : AT(ADDR(.bss) - KERNEL_VADDR_BASE)
  {
    *(COMMON)
    *(.bss)
  }

  /*
   * /DISCARD/ throws away sections we don't want in the final image.
   * .eh_frame / .eh_frame_hdr are exception-unwind tables we don't use,
   * and .note / .comment are metadata that only bloat the binary.
   * Discarding them keeps the program headers clean (3 LOAD segments).
   */
  /DISCARD/ :
  {
    *(.eh_frame)
    *(.eh_frame_hdr)
    *(.note .note.*)
    *(.comment)
  }
}
