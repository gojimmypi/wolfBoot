/* unit-keystore.c
 *
 * example keystore used for image.c unit tests
 *
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
#include <stdint.h>
#include "wolfboot/wolfboot.h"
#include "keystore.h"
#ifdef WOLFBOOT_NO_SIGN
	#define NUM_PUBKEYS 0
#else

#if !defined(KEYSTORE_ANY) && (KEYSTORE_PUBKEY_SIZE != KEYSTORE_PUBKEY_SIZE_ECC256)
	#error Key algorithm mismatch. Remove old keys via 'make keysclean'
#else

#if defined(__APPLE__) && defined(__MACH__)
#define KEYSTORE_SECTION __attribute__((section ("__KEYSTORE,__keystore")))
#elif defined(_MSC_VER)
/* Create a RW data section named .keystore */
#pragma section(".keystore", read, write)
#define KEYSTORE_SECTION __declspec(allocate(".keystore"))
#else
#define KEYSTORE_SECTION __attribute__((section (".keystore")))
#endif

#define NUM_PUBKEYS 1
const KEYSTORE_SECTION struct keystore_slot PubKeys[NUM_PUBKEYS] = {

	/* Key associated to file 'wolfboot_signing_private_key.der' */
	{
		.slot_id = 0,
		.key_type = AUTH_KEY_ECC256,
		.part_id_mask = 0xFFFFFFFF,
		.pubkey_size = KEYSTORE_PUBKEY_SIZE_ECC256,
		.pubkey = {

			0xc5, 0x7d, 0xbf, 0xfb, 0x23, 0x79, 0xba, 0xb6,
			0x31, 0x8f, 0x7b, 0x8d, 0xfe, 0xc9, 0x5d, 0x46,
			0xf5, 0x95, 0xb4, 0xa8, 0xbd, 0x45, 0xb7, 0x46,
			0xf3, 0x6c, 0x1b, 0x86, 0x28, 0x7b, 0x23, 0xd1,
			0x83, 0xf3, 0x27, 0x5c, 0x08, 0x1f, 0x9d, 0x9e,
			0x6c, 0xca, 0xee, 0xb3, 0x0d, 0x5c, 0x01, 0xb2,
			0xc5, 0x98, 0xf3, 0x85, 0x6c, 0xdd, 0x42, 0x54,
			0xef, 0x44, 0x94, 0x59, 0xf3, 0x08, 0x3d, 0xcd
		},
	},


};

int keystore_num_pubkeys(void)
{
    return NUM_PUBKEYS;
}

uint8_t *keystore_get_buffer(int id)
{
    if (id >= keystore_num_pubkeys())
        return (uint8_t *)0;
    return (uint8_t *)PubKeys[id].pubkey;
}

int keystore_get_size(int id)
{
    if (id >= keystore_num_pubkeys())
        return -1;
    return (int)PubKeys[id].pubkey_size;
}

uint32_t keystore_get_mask(int id)
{
    if (id >= keystore_num_pubkeys())
        return -1;
    return (int)PubKeys[id].part_id_mask;
}

uint32_t keystore_get_key_type(int id)
{
   return PubKeys[id].key_type;
}

#endif /* Keystore public key size check */
#endif /* WOLFBOOT_NO_SIGN */
