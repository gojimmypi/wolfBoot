/* Keystore file for wolfBoot, automatically generated. Do not edit.  */
/*
 * This file has been generated and contains the public keys
 * used by wolfBoot to verify the updates.
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
#elif defined(__CCRX__) || defined(WOLFBOOT_RENESAS_RSIP) || defined(WOLFBOOT_RENESAS_TSIP) || defined(WOLFBOOT_RENESAS_SCEPROTECT)
#define KEYSTORE_SECTION /* Renesas RX */
#elif defined(TARGET_x86_64_efi)
#define KEYSTORE_SECTION
#elif defined(_MSC_VER)
/* Create a RW data section named .keystore  ! */
#pragma section(".keystore", read, write)
#define KEYSTORE_SECTION __declspec(allocate(".keystore"))
#else
#define KEYSTORE_SECTION __attribute__((section (".keystore")))
#endif

#define NUM_PUBKEYS 1
const KEYSTORE_SECTION struct keystore_slot PubKeys[NUM_PUBKEYS] = {

    /* Key associated to file 'C:/workspace/wolfBoot-gojimmypi/IDE/VisualStudio/wolfboot_signing_private_key.der' */
    {
        .slot_id = 0,
        .key_type = AUTH_KEY_ECC256,
        .part_id_mask = 0xFFFFFFFF,
        .pubkey_size = 64,
        .pubkey = {
            
            0x93, 0x1a, 0x43, 0x43, 0x38, 0x2c, 0x50, 0x8c,
            0x8f, 0x24, 0x3a, 0xac, 0x19, 0xb5, 0xc6, 0x83,
            0xac, 0x1f, 0x46, 0x25, 0x4b, 0x4c, 0x33, 0x45,
            0xde, 0xc3, 0xca, 0x3d, 0x7e, 0x53, 0x9a, 0x12,
            0xe2, 0x09, 0x57, 0x0d, 0x3f, 0x76, 0x2f, 0x6f,
            0x2f, 0x4b, 0x81, 0xf9, 0x24, 0x97, 0x26, 0xea,
            0x1b, 0x3d, 0x68, 0x67, 0xb3, 0xc8, 0xa0, 0x9f,
            0xf3, 0xc7, 0x71, 0x5f, 0xf6, 0x6d, 0x4d, 0xe8


        },
    },


};

int keystore_num_pubkeys(void)
{
    return NUM_PUBKEYS;
}

uint8_t *keystore_get_buffer(int id)
{
    (void)id;
    if (id >= keystore_num_pubkeys())
        return (uint8_t *)0;
    return (uint8_t *)PubKeys[id].pubkey;
}

int keystore_get_size(int id)
{
    (void)id;
    if (id >= keystore_num_pubkeys())
        return -1;
    return (int)PubKeys[id].pubkey_size;
}

uint32_t keystore_get_mask(int id)
{
    if (id >= keystore_num_pubkeys())
        return 0;
    return PubKeys[id].part_id_mask;
}

uint32_t keystore_get_key_type(int id)
{
    return PubKeys[id].key_type;
}

#endif /* Keystore public key size check */
#endif /* WOLFBOOT_NO_SIGN */
