#!/bin/bash

# Settings
# WOLFBOOT_TARGET=stm32g0
WOLFBOOT_TARGET=stm32l4

# For clarify regarding local app and wolfBoot example:
MY_TARGET=$WOLFBOOT_TARGET

# 1 to download and build wolfBoot, 0 to skip
BUILD_WOLFBOOT=1

# 1 to sign, 0 to just compile
SIGN_APP=1

# 1 to flasg, 0 to skip
FLASH_APP=0

# 1 to clean, 0 to use prior Build
CLEAN_APP=0

# Specify the executable shell checker you want to use:
MY_SHELLCHECK="shellcheck"

# Check if the executable is available in the PATH
if command -v "$MY_SHELLCHECK" >/dev/null 2>&1; then
    # Run your command here
    shellcheck "$0" || exit 1
else
    echo "$MY_SHELLCHECK is not installed. Please install it if changes to this script have been made."
fi

# Where are we?
ROOT_DIR=$(cd "$(dirname "$0")" && pwd)



check_wolfboot_file() {
    local file_path="$1"
    local description="$2"

    if [ -f "$file_path" ]; then
        echo "Found:     $description $file_path"
    else
        echo "Not found: $description $file_path"
    fi
} # check_file


if [ "${BUILD_WOLFBOOT}" = "1" ]; then
    echo "--------------------------------------------------------------------------"
    echo "wolfBoot"
    echo "--------------------------------------------------------------------------"
    # TODO currently gojimmypi dev specific
    if [ ! -d "${ROOT_DIR}/wolfBoot" ]; then
        echo "cloning wolfBoot into ./wolfBoot..."
        git clone https://github.com/gojimmypi/wolfBoot.git "${ROOT_DIR}/wolfBoot"
        (
            cd "${ROOT_DIR}/wolfBoot" || exit 1
            # TODO currently gojimmypi dev specific
            git checkout dev
            git submodule update --init
        )
    else
        echo "found local wolfBoot"
    fi

    # wolfBoot tools
    echo "Clean and build wolfBoot tools for ${WOLFBOOT_TARGET}"
    echo "pushd ${ROOT_DIR}/wolfBoot"
    pushd "${ROOT_DIR}/wolfBoot" || exit 1
        # Optionally Clean and start fresh
        if [ "${CLEAN_APP}" = "1" ]; then
            echo "Clean..."
            ./tools/scripts/wolfboot_build.sh --CLEAN  ${WOLFBOOT_TARGET}
        else
            echo "Clean skipped"
        fi
        echo "Build  --target ${WOLFBOOT_TARGET}"
        ./tools/scripts/wolfboot_build.sh --target ${WOLFBOOT_TARGET}

        # Optionally flash a sample
        # ./tools/scripts/wolfboot_build.sh --flash  ${WOLFBOOT_TARGET}

        check_wolfboot_file "./build-${WOLFBOOT_TARGET}/wolfboot_signing_private_key.der" "private key file:  "
        check_wolfboot_file "./build-${WOLFBOOT_TARGET}/keystore.der"                     "keystore der file: "
        check_wolfboot_file "./build-${WOLFBOOT_TARGET}/keystore.c"                       "keystore source:   "
        echo "wolfBoot done."
    popd || exit 1
else
    echo "skipped wolfBoot build"
fi

echo "--------------------------------------------------------------------------"
echo "Example App CMake Build"
echo "--------------------------------------------------------------------------"
# The current example app assumes wolfBoot is already available in the current directory
# TODO conditionally check in the app if using wolfBoot (e.g. "wolfboot/wolfboot.h")
# TODO allow WOLFBOOT_ROOT environment variable to point at wolfBoot anywhere.
BUILD_DIR="${ROOT_DIR}/build-$MY_TARGET"
rm -rf   "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"
cmake --build --preset "$MY_TARGET" "${BUILD_DIR}"

echo "Current directory: $(pwd)"

# Recommended: explicitly pass the toolchain to wolfBoot as needed
echo "Toolchain:"
ls "${ROOT_DIR}/wolfBoot/cmake/toolchain_arm-none-eabi.cmake"

SIGN_SCRIPT="${ROOT_DIR}/wolfBoot/tools/keytools/sign.py"
SIGN_KEY="${ROOT_DIR}/wolfBoot/build-${WOLFBOOT_TARGET}/wolfboot_signing_private_key.der"

if [ "${SIGN_APP}" = "1" ]; then
    echo "--------------------------------------------------------------------------"
    echo "Example App CMake Configure (signed)"
    echo "--------------------------------------------------------------------------"
    cmake -S "${ROOT_DIR}"  \
          -B "${BUILD_DIR}" \
          -DCMAKE_TOOLCHAIN_FILE="${ROOT_DIR}/cmake/toolchain_arm-none-eabi.cmake" \
          -DWOLFBOOT_TARGET=${WOLFBOOT_TARGET}    \
          -DWOLFBOOT_SECTOR_SIZE=256              \
          -DWOLFBOOT_SIGN_SCRIPT="${SIGN_SCRIPT}" \
          -DWOLFBOOT_SIGN_KEY="${SIGN_KEY}"
else
    echo "--------------------------------------------------------------------------"
    echo "Example App CMake Configure (not signed)"
    echo "--------------------------------------------------------------------------"
    cmake -S "${ROOT_DIR}"  \
          -B "${BUILD_DIR}" \
          -DCMAKE_TOOLCHAIN_FILE="${ROOT_DIR}/cmake/toolchain_arm-none-eabi.cmake"
fi

if [ "${FLASH_APP}" = "1" ]; then
    echo "--------------------------------------------------------------------------"
    echo Flash
    echo "--------------------------------------------------------------------------"
    "${ROOT_DIR}/wolfBoot/tools/scripts/wolfboot_build.sh" --flash-unsigned ${WOLFBOOT_TARGET}
fi
