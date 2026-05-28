/*
 * KERNEL_VMA defines the base virtual address where the kernel will execute.
 * In 64-bit x86, we use the upper half (0xFFFFFFFF80000000+) to reserve
 * the lower half for user-space programs.
 */
KERNEL_VMA = 0xFFFFFFFF80000000;

/*
 * ENTRY(symbol) sets the entry point of the executable.
 * The linker will ensure that _start is the first instruction executed.
 * This must match the symbol exported from Zig code.
 */
ENTRY(_start);

/*
 * SECTIONS block defines how input sections are organized into output sections
 * and where they will be placed in virtual memory.
 */
SECTIONS
{
  /*
   * The location counter (`.`) tracks the current position in virtual memory.
   * Setting it to KERNEL_VMA means all subsequent sections start at the high-half address.
   */
  . = KERNEL_VMA;

  /*
   * .text section: contains executable code.
   * 
   * The colon separates the output section name from its properties.
   * AT(...) specifies the physical address where the bootloader should load this section.
   * ADDR(.text) gets the virtual address; subtracting KERNEL_VMA converts it to physical.
   * This lets Limine load at low memory (e.g., 0x100000) while the CPU executes at the virtual address.
   */
  .text : AT(ADDR(.text) - KERNEL_VMA)
  {
    /*
     * _code is a symbol marking the start of the .text section.
     * You can reference this in Zig to know where code begins.
     */
    _code = .;

    /*
     * *(.text) collects all .text input sections from all compiled object files.
     * The wildcard (*) means "from any input file".
     */
    *(.text)

    /*
     * *(.rodata*) collects read-only data (strings, constants).
     * The asterisk pattern matches .rodata, .rodata.str1.1, etc.
     * Placing it here keeps immutable data near code for cache locality.
     */
    *(.rodata*)

    /*
     * ALIGN(4096) pads the current location to the next 4K boundary.
     * This ensures the next section starts on a page boundary,
     * allowing independent page-level permission control.
     */
    . = ALIGN(4096);
  }

  /*
   * .data section: contains initialized global/static variables.
   * 
   * Same pattern as .text: virtual address on the left, physical on the right via AT(...).
   * The bootloader loads this data; the kernel's _start code may relocate it or set up BSS.
   */
  .data : AT(ADDR(.data) - KERNEL_VMA)
  {
    /*
     * _data marks the start of initialized data.
     * Useful for knowing where to copy data during kernel initialization.
     */
    _data = .;

    /*
     * *(.data) collects all initialized data sections.
     */
    *(.data)

    /*
     * Align to the next page boundary so .bss can have independent permissions.
     */
    . = ALIGN(4096);
  }

  /*
   * .bss section: uninitialized data (will be zeroed by the kernel).
   * 
   * Note: .bss data is NOT stored in the ELF file itself (to save space).
   * The ELF header records its size; the kernel must zero it at runtime.
   */
  .bss : AT(ADDR(.bss) - KERNEL_VMA)
  {
    /*
     * _bss marks the start of uninitialized data.
     * Used by kernel startup code to know where to begin zeroing.
     */
    _bss = .;

    /*
     * *(.bss) collects all uninitialized data sections.
     */
    *(.bss)

    /*
     * *(COMMON) collects symbols that haven't been assigned to a section.
     * This is needed when compiling with certain flags; including it ensures
     * no symbols are accidentally dropped.
     */
    *(COMMON)

    /*
     * Align to the next page boundary.
     * This ensures .bss doesn't spill into whatever follows (if anything).
     */
    . = ALIGN(4096);
  }

  /*
   * _end is a symbol marking the end of all kernel sections.
   * Useful for knowing the total size of the kernel in memory.
   */
  _end = .;
}
