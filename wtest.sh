#!/bin/bash

cp config/examples/library.config .config
make clean
make keysclean
make -C tools/keytools clean

# This script generates a target.h file
# TODO why? Why in include directory?
if [ -f "include/target.h" ]; then
    echo "Found existing target.h, removing it"
    rm -f include/target.h
fi

ASYM=ecc256
HASH=sha256


# ok:
# MATH="SPMATH=0 SPMATHALL=0 WOLFBOOT_SMALL_STACK=1"
MATH="SPMATH=1 WOLFBOOT_SMALL_STACK=0"

# Fail:
# MATH="SPMATH=1 WOLFBOOT_SMALL_STACK=1"

export MAKE_SIGN="${ASYM^^}"
export MAKE_HASH="${HASH^^}"

make -j1 keytools SIGN=${MAKE_SIGN} HASH=${MAKE_HASH}

echo "Generate a new keystore"
./tools/keytools/keygen --${ASYM} -g wolfboot_signing_private_key.der

echo ""
echo "Looking for test.bin to sign ..."
if [ -f "test.bin" ]; then
    echo "Found existing test.bin"
else
    echo "Creating a new test.bin"
    echo "Test" > test.bin
fi

echo ""
echo "Generate sign test.bin"
./tools/keytools/sign --${ASYM} --${HASH} test.bin wolfboot_signing_private_key.der 1

echo ""
echo "Make test-lib"
make -j1 "test-lib" SIGN=${MAKE_SIGN} HASH=${MAKE_HASH} ${MATH}
if [ -f "include/target.h" ]; then
    echo "Found new include/target.h after make test-lib"
else
    echo "WARNING: Expected to find a new include/target.h after make test-lib"
fi

echo ""
echo "Run ./test-lib test_v1_signed.bin"
./test-lib test_v1_signed.bin
