/* cmake/stm32l4.ld - simple STM32L4 app linker script for bare metal */

MEMORY
{
    /* Adjust LENGTH to your exact device (this is 1 MB for STM32L475) */
    FLASH (rx)  : ORIGIN = 0x08000000, LENGTH = 0x00100000
    RAM   (rwx) : ORIGIN = 0x20000000, LENGTH = 0x00018000
}

/* Initial stack pointer used by the vector table */
_estack = ORIGIN(RAM) + LENGTH(RAM);

SECTIONS
{
    /* Vector table at start of flash */
    .isr_vector :
    {
        KEEP(*(.isr_vector))
    } > FLASH

    .text :
    {
        _start_text = .;
        *(.text*)
        *(.rodata*)
        . = ALIGN(4);
        _end_text = .;
    } > FLASH

    .ARM.extab :
    {
        *(.ARM.extab*)
    } > FLASH

    .ARM.exidx :
    {
        *(.ARM.exidx*)
    } > FLASH

    /* Initialized data: load from flash, run in RAM */
    .data : AT (ADDR(.text) + SIZEOF(.text))
    {
        _sidata = LOADADDR(.data);  /* LMA (flash) for .data */
        _sdata  = .;                /* VMA start in RAM */
        *(.data*)
        . = ALIGN(4);
        _edata  = .;                /* VMA end in RAM */
    } > RAM

    /* Zero-initialized data in RAM */
    .bss (NOLOAD) :
    {
        _sbss = .;
        __bss_start__ = .;
        *(.bss*)
        *(COMMON)
        . = ALIGN(4);
        _ebss = .;
        __bss_end__ = .;
        _end = .;
    } > RAM

    . = ALIGN(4);
}
