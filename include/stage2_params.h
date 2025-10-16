/* stage2_params.h
 *
 * Copyright (C) 2025 wolfSSL Inc.
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
#ifndef STAGE1_H
#define STAGE1_H

#include <stdint.h>

struct stage2_parameter {
#if WOLFBOOT_FSP
    uint32_t hobList;
    uint32_t page_table;
    uint32_t tolum;
#ifdef WOLFBOOT_TPM_SEAL
    uint32_t tpm_policy;
    uint16_t tpm_policy_size;
#endif
#endif
} __attribute__((packed));

#define DUMMY_IDT_DESC_SIZE 4
struct stage2_ptr_holder {
    struct stage2_parameter *ptr;
    uint8_t dummy_idt[DUMMY_IDT_DESC_SIZE];
} __attribute__((packed));

struct stage2_parameter *stage2_get_parameters(void);
void stage2_set_parameters(struct stage2_parameter *p, struct stage2_ptr_holder *holder);
void stage2_copy_parameter(struct stage2_parameter *p);

#if defined(WOLFBOOT_TPM_SEAL)
int stage2_get_tpm_policy(const uint8_t **policy, uint16_t *policy_size);
#endif /* defined(WOLFBOOT_TPM_SEAL) */

#endif /* STAGE1_H */
