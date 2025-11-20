/* app_stm32l4.c
 *
 * Test bare-metal boot-led-on application
 *
 * Copyright (C) 2020 wolfSSL Inc.
 *
 * This file is part of wolfBoot.
 *
 * wolfBoot is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * wolfBoot is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1335, USA
 */


#include "led.h"
#include "hal.h"
#include "wolfboot/wolfboot.h"
#include "target.h"


static void delay(volatile uint32_t t) {
    while (t--)
    {
        __asm__ volatile("nop");
    }
}

void main(void)
{
    hal_init();
    for (;;) {
        led_on();  delay(8000000);
        led_off(); delay(8000000);
        led_off(); delay(8000000);
    }
}

