#!/bin/bash

# wolfboot_build.sh
#
#   ./tools/scripts/wolfboot_build.sh --CLEAN --target [your target]
#   ./tools/scripts/wolfboot_build.sh --target [your target]
#   ./tools/scripts/wolfboot_build.sh --flash [your target]
#
# Options:
#   Set WOLFBOOT_CLEAN_STRICT=1 to error is any other build directories found
#
# Reminder for WSL:
# git update-index --chmod=+x wolfboot_build.sh
# git commit -m "Make wolfboot_build.sh executable"
# git push

# Specify the executable shell checker you want to use:
MY_SHELLCHECK="shellcheck"

# Check if the executable is available in the PATH
if command -v "$MY_SHELLCHECK" >/dev/null 2>&1; then
    # Run your command here
    shellcheck "$0" || exit 1
else
    echo "$MY_SHELLCHECK is not installed. Please install it if changes to this script have been made."
fi

# Begin common dir init, for /tools/scripts
# Resolve this script's absolute path and its directories
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_PATH="${SCRIPT_DIR}/$(basename -- "${BASH_SOURCE[0]}")"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"

# Normalize to physical paths (no symlinks, no trailing slashes)
# SCRIPT_DIR_P="$(cd -- "$SCRIPT_DIR" && pwd -P)"
REPO_ROOT_P="$(cd -- "$REPO_ROOT" && pwd -P)"
CALLER_CWD_P="$(pwd -P)"   # where the user ran the script from

# Print only if caller's cwd is neither REPO_ROOT nor REPO_ROOT/scripts
case "$CALLER_CWD_P" in
    "$REPO_ROOT_P" | "$REPO_ROOT_P"/scripts)
        : # silent
        ;;
    *)
        echo "Script paths:"
        echo "-- SCRIPT_PATH =$SCRIPT_PATH"
        echo "-- SCRIPT_DIR  =$SCRIPT_DIR"
        echo "-- REPO_ROOT   =$REPO_ROOT"
        ;;
esac

# Always work from the repo root, regardless of where the script was invoked
cd -- "$REPO_ROOT_P" || { printf 'Failed to cd to: %s\n' "$REPO_ROOT_P" >&2; exit 1; }
echo "Starting $0 from $(pwd -P)"

# End common dir init

 if [ $# -gt 0 ]; then
    THIS_OPERATION="$1"

    TARGET="$2"
    if [ "$TARGET" = "" ]; then
        echo "No target specified"
    fi

    if [ "$THIS_OPERATION" = "--CLEAN" ]; then
        if [ "$TARGET" = "" ]; then
            echo "Clean... (build)"
            rm -rf ./build
            if [ -e ./build ]; then
                echo "ERROR: ./build still exists after rm -rf" >&2
                exit 1
            fi
        else
            echo "Clean... (build-$TARGET)"
            rm -rf "./build-$TARGET"
            if [ -e "./build-$TARGET" ]; then
                echo "ERROR: ./build-$TARGET still exists after rm -rf" >&2
                exit 1
            fi
        fi

        # Any other build directories?
        # Warn if others remain, but don't fail unless strict is requested
        shopt -s nullglob
        others=()
        for d in build-*; do
            # skip generic build dir (if any) and the one we just removed
            [ "$d" = "build" ] && continue
            [ "$d" = "build-$TARGET" ] && continue
            others+=("$d")
        done

        if ((${#others[@]})); then
            printf 'Note: Found %d other build directory target(s):\n' "${#others[@]}"
            printf '%s\n' "${others[@]}"
            if [ -n "$WOLFBOOT_CLEAN_STRICT" ]; then
                echo "Failing because WOLFBOOT_CLEAN_STRICT is set."
                exit 1
            fi
        else
            echo 'Success: No other build-[target] directories found.'
        fi
        exit 0
    fi

    if [ "$THIS_OPERATION" = "--target" ]; then
        TARGET="$2"
        echo "Set target: $TARGET"
    fi

    if [ "$THIS_OPERATION" = "--stlink-upgrade" ]; then
        echo "ST-Link upgrade!"
        CLI="/mnt/c/Program Files/STMicroelectronics/STM32Cube/STM32CubeProgrammer/bin/STLinkUpgrade.exe"
        if [ ! -f "$CLI" ]; then
            echo "CLI=$CLI"
            echo "STLinkUpgrade.exe not found, exiting"
            exit 2
        fi

        # Run STLinkUpgrade.exe
        "$CLI"
        status=$?
        if [ "$status" -eq 0 ]; then
            echo "OK: command succeeded"
        else
            echo "Failed: command exited with status $status"
        fi
        exit "$status"
    fi

    if [ "$THIS_OPERATION" = "--flash" ]; then
        echo "Flash Target=$TARGET"
        CLI="/mnt/c/Program Files/STMicroelectronics/STM32Cube/STM32CubeProgrammer/bin/STM32_Programmer_CLI.exe"
        if [ ! -f "$CLI" ]; then
            echo "CLI=$CLI"
            echo "STM32_Programmer_CLI.exe not found, exiting"
            exit 2
        fi

        WOLFBOOT_BIN="build-$TARGET/test-app/wolfboot_$TARGET.bin"
        echo Checking "WOLFBOOT_BIN=$WOLFBOOT_BIN"
        if [ ! -f "$WOLFBOOT_BIN" ]; then
            echo "Missing: $WOLFBOOT_BIN  (build first: cmake --build --preset \"$TARGET\")"
            exit 2
        fi
        IMAGE_WOLFBOOT=$(wslpath -w "$WOLFBOOT_BIN")
        "$CLI" -c port=SWD mode=UR freq=400 -w "$IMAGE_WOLFBOOT" 0x08000000 -v

        SIGNED="build-$TARGET/test-app/image_v1_signed.bin"
        echo "Checking SIGNED=$SIGNED"
        if [ ! -f "$SIGNED" ]; then
            echo "Missing: $SIGNED  (try: cmake --build --preset \"$TARGET\" --target test-app)"
            exit 2
        fi

        BOOT_ADDR=0x0800A000    # your wolfBoot BOOT address
        IMAGE_SIGNED=$(wslpath -w "$SIGNED")
        echo "IMAGE_SIGNED=$IMAGE_SIGNED"

        # SWD via ST-LINK (Windows handles the USB)
        "$CLI" -c port=SWD mode=UR freq=400 -w "$IMAGE_SIGNED" "$BOOT_ADDR" -v -hardRst
        status=$?
        if [ "$status" -eq 0 ]; then
            echo "OK: command succeeded"
        else
            echo "Failed: command exited with status $status"
        fi
        exit "$status"
    fi
fi

if [ "$TARGET" = "" ]; then
    echo "Please specify a target."
    echo ""
    echo "  $0 --target [your target]"
    echo ""
    cmake -S . -B build --list-presets=configure
    exit 1
fi

echo "cmake --preset  $TARGET"
      cmake --preset "$TARGET"

echo "cmake --build --preset  $TARGET  -j"
      cmake --build --preset "$TARGET" -j

# Reminder: Manual build
# mkdir -p build
# cd build
# cmake -DWOLFBOOT_TARGET=stm32h7 -DBUILD_TEST_APPS=yes -DWOLFBOOT_PARTITION_BOOT_ADDRESS=0x8020000 -DWOLFBOOT_SECTOR_SIZE=0x20000 -DWOLFBOOT_PARTITION_SIZE=0xD0000 -DWOLFBOOT_PARTITION_UPDATE_ADDRESS=0x80F0000 -DWOLFBOOT_PARTITION_SWAP_ADDRESS=0x81C0000 ..
# make
