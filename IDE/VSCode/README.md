# VS Code wolfBoot Project

## Requirements

### VS Code extensions

- CMake Tools (ms-vscode.cmake-tools)
- C/C++ (ms-vscode.cpptools)
- Cortex-Debug (marus25.cortex-debug)

### Build tools

#### WSL path:

cmake, ninja-build, gcc-arm-none-eabi, openocd

#### Windows path:

Windows path: CMake, Ninja, Arm GNU Toolchain, OpenOCD (or ST’s OpenOCD)

Install via PowerShell (will need to restart VSCode):

```ps
winget install --id Ninja-build.Ninja -e


# winget install -e --id Arm.GnuArmEmbeddedToolchain

winget install -e --id Arm.GnuArmEmbeddedToolchain --override "/S /D=C:\Tools\arm-gnu-toolchain-14.2.rel1"
# reopen VS / terminal so PATH refreshes

# Confirm
ninja --version

Get-Command arm-none-eabi-gcc
```

If already installed, uninstall:

```
winget uninstall -e --id Arm.GnuArmEmbeddedToolchain
```
