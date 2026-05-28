/*
 * KERNEL_VMA defines the base physical address where the kernel will load and execute.
 * We use 1MB (0x100000) for now, which is a standard low-memory kernel load address.
 * Later (Phase 6), we'll set up virtual memory to map this to the upper half.
 */
KERNEL_VMA = 1M;

/*
 * ENTRY(symbol) sets the entry point of the executable.
 * The linker will ensure that _start is the first instruction executed.
 * This must match the symbol exported from Zig code.
 */
ENTRY(_start);

/*
 * SECTIONS block defines how input sections are organized into output sections
 * and where they will be placed in memory.
 */
SECTIONS
{
  /*
   * The location counter (`.`) tracks the current position in memory.
   * Setting it to KERNEL_VMA means all subsequent sections start at 1MB.
   */
  . = KERNEL_VMA;

  /*
   * .text section: contains executable code.
   * 
   * For now, we don't use AT(...) because the virtual and physical addresses are the same.
   * When we add paging (Phase 6), we'll update this to separate them.
   */
  .text : ALIGN(4K)
  {
    /*
     * _code is a symbol marking the start of the .text section.
     * You can reference this in Zig to know where code begins.
     */
    _code = .;

    /*
     * *(.text) collects all .text input sections from all compiled object files.
     */
    *(.text)

    /*
     * *(.rodata*) collects read-only data (strings, constants).
     * Placing it with code keeps immutable data near executable code.
     */
    *(.rodata*)

    /*
     * ALIGN(4K) ensures the next section starts on a page boundary.
     * This will be important for page permission management.
     */
    . = ALIGN(4K);
  }

  /*
   * .data section: contains initialized global/static variables.
   */
  .data : ALIGN(4K)
  {
    /*
     * _data marks the start of initialized data.
     */
    _data = .;

    /*
     * *(.data) collects all initialized data sections.
     */
    *(.data)

    . = ALIGN(4K);
  }

  /*
   * .bss section: uninitialized data (will be zeroed by the kernel).
   * 
   * Note: .bss data is NOT stored in the ELF file its
