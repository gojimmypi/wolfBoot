# My TODO Status

TODO:

- wolfBootKeygenTool VS project does not generate src/keystore.c
- Invalid argument '--help' for keygen

Some interim notes on progress in various environments:

## CMake Dev Status:

|Status | Environment               | Test With
|-------| ------------------------- | --------
|  ✅   | VS 2022                   | Right-Click on [CMakeLists.txt](./CMakeLists.txt), Build
|  ✅   | WSL                       | [./tools/scripts/cmake_test.sh](./tools/scripts/cmake_test.sh)
|  ✅   | Mac                       | [test-build-cmake-mac.yml](./github/workflows/test-build-cmake-mac.yml)
|  ✅   | WSL dot-config mode       | [test-build-cmake-dot-config.yml](./github/workflows/test-build-cmake-dot-config.yml)
|  ❌   | DOS dev prompt, dot-config |
|  ✅   | VS Code, Dev Prompt       | Click "build" on bottom toolbar ribbon
|  ✅   | VS Code, x64 Dev Prompt   | Click "build" on bottom toolbar ribbon
|  ✅   | DOS Prompt, Dev Prompt    | [.\tools\scripts\cmake_dev_prompt_test.bat](./tools/scripts/cmake_dev_prompt_test.bat)
|  ✅   | PowerShell, Dev Prompt    | [.\tools\scripts\cmake_dev_prompt_test.bat](./tools/scripts/cmake_dev_prompt_test.bat)
|  ❌   | DOS Prompt, direct launch | [.\tools\scripts\cmake_test.bat](./tools/scripts/cmake_test.bat) (needs toolchain path)
|  ❌   | PowerShell, direct launch | [.\tools\scripts\cmake_test.bat](./tools/scripts/cmake_test.bat) (needs toolchain path)
|  ❌   | VS Code, direct launch    | Click "build"

## Make Dev Status:

|Status | Environment               | Test With
|-------| ------------------------- | --------
|   ?   | VS 2022                   | N/A (?)
|  ✅   | WSL                       | `./tools/scripts/wolfboot_cmake_full_build.sh --target stm32l4`
|  ⚠️   | Mac                       | [test-build-cmake-mac.yml](./github/workflows/test-build-cmake-mac.yml)
|   ?   | VS Code, Dev Prompt       | N/A (?)
|  ❌   | DOS Prompt, Dev Prompt    |
|  ❌   | PowerShell, Dev Prompt    |
|  ❌   | DOS Prompt, direct launch |
|  ❌   | PowerShell, direct launch |
|   ?   | VS Code, direct launch    | N/A (?)
