/* name of entry label */
ENTRY(_start)
 
SECTIONS {
  /* loading program with 1 MB */
	. = 1M;
 
	.text : ALIGN(4K) {
		KEEP(*(.multiboot))
		*(.text)
	}
 
	.rodata : ALIGN(4K) {
		*(.rodata)
	}
 
	.data : ALIGN(4K) {
		*(.data)
	}
 
	.bss : ALIGN(4K) {
		*(COMMON)
		*(.bss)
	}
}
