#!/bin/bash

# Specify the executable shell checker you want to use:
MY_SHELLCHECK="shellcheck"

# Check if the executable is available in the PATH
if command -v "$MY_SHELLCHECK" >/dev/null 2>&1; then
    # Run your command here
    shellcheck "$0" || exit 1
else
    echo "$MY_SHELLCHECK is not installed. Please install it if changes to this script have been made."
fi

if [ $# -gt 0 ]; then
    THIS_OPERATION="$1"
    if [ "$THIS_OPERATION" = "--CLEAN" ]; then
        echo "Clean..."
        rm -rf ./build
        exit 0
    fi

    if [ "$THIS_OPERATION" = "--target" ]; then
        TARGET="$2"
        echo "Set target: $TARGET"
    fi

fi

if [ "$TARGET" = "" ]; then
    echo "Please specify a target"
    exit 1
fi

cmake --preset linux-"$TARGET"
cmake --build --preset linux-"$TARGET" -j

# Reminder: Manual build
# mkdir -p build
# cd build
# cmake -DWOLFBOOT_TARGET=stm32h7 -DBUILD_TEST_APPS=yes -DWOLFBOOT_PARTITION_BOOT_ADDRESS=0x8020000 -DWOLFBOOT_SECTOR_SIZE=0x20000 -DWOLFBOOT_PARTITION_SIZE=0xD0000 -DWOLFBOOT_PARTITION_UPDATE_ADDRESS=0x80F0000 -DWOLFBOOT_PARTITION_SWAP_ADDRESS=0x81C0000 ..
# make
