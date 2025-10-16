# wolfboot Visual Studio

Users of Visual Studio can open the `WOLFBOOT_ROOT` directory without the need for a project file.

Visual Studio is "cmake-aware" and recognizes the [CMakePresets.json](../../CMakePresets.json)

See the [cmake/config_defaults.cmake](../../cmake/config_defaults.cmake) file. Of particular interest
are some environment configuration settings, in particular the `DETECT_VISUALGDB`:

```cmake
# Environments are detected in this order:
set(DETECT_VISUALGDB true)
set(DETECT_CUBEIDE true)
set(DETECT_VS2022 true)

# Enable HAL download only implemented for TMS devices at this time.
# See [WOLFBOOT_ROOT]/cmake/stm32_hal_download.cmake
# and [WOLFBOOT_ROOT]/cmake/downloads/stm32_hal_download.cmake
set(ENABLE_HAL_DOWNLOAD true)
set(FOUND_HAL_BASE false)

# optionally use .config files; See CMakePresets.json instead
set(USE_DOT_CONFIG false)
```


For more details, see the [cmake/README](../../cmake/README.md) file.
