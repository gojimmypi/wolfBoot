# wolfboot/cmake/stm32_hal_download.cmake
#
# Copyright (C) 2022 wolfSSL Inc.
#
# This file is part of wolfBoot.
#
# wolfBoot is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# wolfBoot is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1335, USA
#

# If not found:
#   1) The CubeIDE
#   2) VisualGDB/EmbeddedBSPs/arm-eabi/com.sysprogs.arm.stm32
#   3) User-specified
#
# ... then download HAL files as needed:

# Ensure this file is only included and initialized once
if(CMAKE_VERSION VERSION_LESS 3.10)
    # Fallback path for older CMake, and anything else that wants to detect is loaded
    if(DEFINED STM32_HAL_DOWNLOAD_CMAKE_INCLUDED)
        return()
    endif()
else()
    include_guard(GLOBAL)
endif()


if(ENABLE_HAL_DOWNLOAD) # Entire file wrapper

if(NOT FUNCTIONS_CMAKE_INCLUDED)
    include(cmake/functions.cmake)
endif()

# WOLFBOOT_TARGET is expected to be all lower case, e.g. "stm32l4"
if(WOLFBOOT_TARGET MATCHES "^stm32")
    if(FOUND_HAL_BASE)
        message(STATUS "stm32_hal_download.cmake skipped, already found STM32 HAL lib.")
    else()
        set(_in "${WOLFBOOT_TARGET}")
        if(_in MATCHES "^stm32")
            string(SUBSTRING "${_in}" 5 -1 WOLFBOOT_TARGET_FAMILY)   #  => "l4"
        else()
            message(FATAL_ERROR "Expected value to start with stm32")
        endif()

        if("${ST_HAL_TAG}" STREQUAL "")
            set(ST_HAL_TAG "main")
        endif()
        if("${ST_CMSIS_TAG}" STREQUAL "")
            set(ST_CMSIS_TAG "main")
        endif()
        if("${ST_CMSIS_CORE_TAG}" STREQUAL "")
            set(ST_CMSIS_CORE_TAG "main")
        endif()

        include(FetchContent)
        # TIP: Always pin a real tag/commit; avoid main/master.

        # Make behavior explicit & chatty while debugging
        set(FETCHCONTENT_QUIET OFF)
        set(FETCHCONTENT_BASE_DIR "${CMAKE_BINARY_DIR}/_deps")

        # HAL driver
        message(STATUS "Fetching https://github.com/STMicroelectronics/${WOLFBOOT_TARGET}xx_hal_driver.git")
        FetchContent_Declare(st_hal
          GIT_REPOSITORY https://github.com/STMicroelectronics/${WOLFBOOT_TARGET}xx_hal_driver.git
          # Pick a tag you want to lock to; a value MUST be provided
          GIT_TAG        "${ST_HAL_TAG}" # see CMakePresets.json, device-specific
          GIT_SHALLOW    TRUE
          GIT_PROGRESS   FALSE
        )

        # CMSIS device headers for L4
        message(STATUS "Fetching https://github.com/STMicroelectronics/cmsis_device_${WOLFBOOT_TARGET_FAMILY}.git")
        FetchContent_Declare(cmsis_dev
          GIT_REPOSITORY https://github.com/STMicroelectronics/cmsis_device_${WOLFBOOT_TARGET_FAMILY}.git
          GIT_TAG        "${ST_CMSIS_TAG}" # ee CMakePresets.json, device-family-specific
          GIT_SHALLOW    TRUE
          GIT_PROGRESS   FALSE
        )

        # CMSIS Core headers
        message(STATUS "Fetching https://github.com/ARM-software/CMSIS_5.git")
        FetchContent_Declare(cmsis_core
          GIT_REPOSITORY https://github.com/ARM-software/CMSIS_5.git
          GIT_TAG        "${ST_CMSIS_CORE_TAG}"
          GIT_SHALLOW    TRUE
          GIT_PROGRESS   FALSE
        )

        FetchContent_MakeAvailable(st_hal cmsis_dev cmsis_core)

        # Map to the include structures of the fetched repos
        message("stm32_hal_download.cmake setting hal directories:")
        set_and_echo_dir(HAL_BASE       "${st_hal_SOURCE_DIR}")
        set_and_echo_dir(HAL_DRV        "${st_hal_SOURCE_DIR}")                                   # Inc/, Src/
        set_and_echo_dir(HAL_CMSIS_DEV  "${cmsis_dev_SOURCE_DIR}/Include")                        # device
        set_and_echo_dir(HAL_CMSIS_CORE "${cmsis_core_SOURCE_DIR}/CMSIS/Core/Include")            # core
    endif()
endif()

endif() #ENABLE_HAL_DOWNLOAD

set(STM32_HAL_DOWNLOAD_CMAKE_INCLUDED true)
