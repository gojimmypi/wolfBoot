#!/bin/bash

#      matrix:
#        math:
#          - "SPMATH=1 WOLFBOOT_SMALL_STACK=0"
#          - "SPMATH=1 WOLFBOOT_SMALL_STACK=1"
#          - "SPMATHALL=1 WOLFBOOT_SMALL_STACK=0"
#          - "SPMATHALL=1 WOLFBOOT_SMALL_STACK=1"
#          - "SPMATH=0 SPMATHALL=0 WOLFBOOT_SMALL_STACK=0"
#          - "SPMATH=0 SPMATHALL=0 WOLFBOOT_SMALL_STACK=1"
#        asym: [ed25519, ecc256, ecc384, ecc521, rsa2048, rsa3072, rsa4096, ed448]
#        hash: [sha256, sha384, sha3]
#        # See https://github.com/wolfSSL/wolfBoot/issues/614 regarding exclusions:
#        exclude:
#          - math: "SPMATH=1 WOLFBOOT_SMALL_STACK=1"
#          - math: "SPMATHALL=1 WOLFBOOT_SMALL_STACK=1"

# Specify the executable shell checker you want to use:
MY_SHELLCHECK="shellcheck"

# Check if the executable is available in the PATH
if command -v "$MY_SHELLCHECK" >/dev/null 2>&1; then
    # Run your command here
    shellcheck "$0" || exit 1
else
    echo "$MY_SHELLCHECK is not installed. Please install it if changes to this script have been made."
fi

set -euo pipefail

# Success
# ASYM=ed25519
# HASH=sha256

# Failure
ASYM=ecc256
HASH=sha3

MATH=()
MATH=(SPMATH=1 WOLFBOOT_SMALL_STACK=1)


# Sample build
build_once() {
    # Convert asym and hash to upper case, optionally add additional param
    echo "run: make -j                          test-lib SIGN=${ASYM^^} HASH=${HASH^^} ${MATH[*]} $*"
               make -j   test-lib SIGN=${ASYM^^} HASH=${HASH^^} "${MATH[@]}" "$@"
}

echo "Clean ..."
make keysclean && make -C tools/keytools clean && rm -f include/target.h
echo ""

# Keytools
echo "make keytools..."
make keytools
./tools/keytools/keygen --${ASYM}  -g wolfboot_signing_private_key.der
echo ""

# Sign
echo "Sign ..."
echo "Test" > test.bin
echo "./tools/keytools/sign --${ASYM}  --${HASH}  test.bin wolfboot_signing_private_key.der 1"
      ./tools/keytools/sign --${ASYM}  --${HASH}  test.bin wolfboot_signing_private_key.der 1
echo ""

echo "Build ..."
if build_once >build.out 2>build.err; then
    cat build.out
    cat build.err
    echo "Success on first attempt (no huge stack)."
else
    if grep -Fq 'If this is OK, please compile with WOLFBOOT_HUGE_STACK=1' build.err; then
        echo "Retrying with WOLFBOOT_HUGE_STACK=1 due to stack requirement."
        grep -Fn 'If this is OK, please compile with WOLFBOOT_HUGE_STACK=1' build.err || true
        build_once WOLFBOOT_HUGE_STACK=1
    else
        echo "Build failed for another reason:"
        cat build.err
        exit 1
    fi
fi


./test-lib test_v1_signed.bin
./test-lib test_v1_signed.bin 2>&1 | grep "Firmware Valid"
