/* app/startup_stm32l4.c - minimal startup for STM32L4 */

#include <stdint.h>

/* Symbols from the linker script */
extern uint32_t _estack;
extern uint32_t _sidata;
extern uint32_t _sdata;
extern uint32_t _edata;
extern uint32_t _sbss;
extern uint32_t _ebss;

/* main() from your app */
int main(void);

/* Handler prototypes */
void Reset_Handler(void);
void Default_Handler(void);

/* Weak aliases for interrupts */
void NMI_Handler(void)                __attribute__((weak, alias("Default_Handler")));
void HardFault_Handler(void)          __attribute__((weak, alias("Default_Handler")));
void MemManage_Handler(void)          __attribute__((weak, alias("Default_Handler")));
void BusFault_Handler(void)           __attribute__((weak, alias("Default_Handler")));
void UsageFault_Handler(void)         __attribute__((weak, alias("Default_Handler")));
void SVC_Handler(void)                __attribute__((weak, alias("Default_Handler")));
void DebugMon_Handler(void)           __attribute__((weak, alias("Default_Handler")));
void PendSV_Handler(void)             __attribute__((weak, alias("Default_Handler")));
void SysTick_Handler(void)            __attribute__((weak, alias("Default_Handler")));

/* Vector table in .isr_vector section */
__attribute__((section(".isr_vector")))
void (* const g_pfnVectors[])(void) =
{
    (void (*)(void))(&_estack),   /* Initial stack pointer */
    Reset_Handler,                /* Reset handler */
    NMI_Handler,                  /* NMI */
    HardFault_Handler,            /* Hard fault */
    MemManage_Handler,            /* Memory management fault */
    BusFault_Handler,             /* Bus fault */
    UsageFault_Handler,           /* Usage fault */
    0, 0, 0, 0,                   /* Reserved */
    SVC_Handler,                  /* SVCall */
    DebugMon_Handler,             /* Debug monitor */
    0,                            /* Reserved */
    PendSV_Handler,               /* PendSV */
    SysTick_Handler               /* SysTick */
    /* Add more IRQs as needed */
};

static void init_data_bss(void)
{
    uint32_t* src;
    uint32_t* dst;

    /* Copy .data from flash to RAM */
    src = &_sidata;
    dst = &_sdata;
    while (dst < &_edata)
    {
        *dst++ = *src++;
    }

    /* Zero .bss */
    dst = &_sbss;
    while (dst < &_ebss)
    {
        *dst++ = 0U;
    }
}

void Reset_Handler(void)
{
    init_data_bss();

    /* Optional: SystemInit(); if you have CMSIS system_stm32l4xx.c */

    (void)main();

    /* If main ever returns, loop forever */
    for (;;)
    {
    }
}

void Default_Handler(void)
{
    for (;;)
    {
    }
}
