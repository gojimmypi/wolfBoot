# wolfboot/cmake/visualgdb_config.cmake
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

# See wolfboot/cmake/config_defaults.cmake

# Ensure this file is only included and initialized once
if(CMAKE_VERSION VERSION_LESS 3.10)
    # Fallback path for older CMake
    if(DEFINED VISUALGDB_CONFIG_CMAKE_INCLUDED)
        return()
    endif()
else()
    include_guard(GLOBAL)
endif()

# VisualGDB toolchains are installed automatically with the product
# or can be found at: https://gnutoolchains.com/download/

if(DETECT_VISUALGDB)
    message(STATUS "Begin VisualGDB detection...")
    # TODO needs to be more generic, perhaps in presets?

    if("${HAL_BASE}" STREQUAL "")
        # VisualDGB files can be used from Windows:
        if(IS_DIRECTORY  "C:/Users/${CURRENT_USER}/AppData/Local/VisualGDB")
            set(LIB_STM32L4_WINDOWS "C:/Users/${CURRENT_USER}/AppData/Local/VisualGDB/EmbeddedBSPs/arm-eabi/com.sysprogs.arm.stm32/STM32L4xxxx")
            if(IS_DIRECTORY "${LIB_STM32L4_WINDOWS}")
                set(FOUND_HAL_BASE true)
                message(STATUS "LIB_STM32L4_WINDOWS found: ${LIB_STM32L4_WINDOWS}")
                set_and_echo_dir(HAL_BASE "${LIB_STM32L4_WINDOWS}")
            endif()
        endif()

        # VisualDGB files can also be used from WSL:
        if(IS_DIRECTORY  "/mnt/c/Users/${CURRENT_USER}/AppData/Local/VisualGDB")
            set(LIB_STM32L4_WSL "/mnt/c/Users/${CURRENT_USER}/AppData/Local/VisualGDB/EmbeddedBSPs/arm-eabi/com.sysprogs.arm.stm32/STM32L4xxxx")
            if(IS_DIRECTORY "${LIB_STM32L4_WSL}")
                set(FOUND_HAL_BASE true)
                message(STATUS "LIB_STM32L4_WSL found: ${LIB_STM32L4_WSL}")
                set_and_echo_dir(HAL_BASE "${LIB_STM32L4_WSL}")
            endif()
        endif()

        if(HAL_BASE STREQUAL "")
            message(STATUS "VisualGDB detection could not set HAL_BASE")
        else()
            # VisualGDB
            set_and_echo_dir(HAL_DRV          "${HAL_BASE}/STM32L4xx_HAL_Driver")
            set_and_echo_dir(HAL_CMSIS_DEV    "${HAL_BASE}/CMSIS_HAL/Device/ST/STM32L4xx/Include")
            set_and_echo_dir(HAL_CMSIS_CORE   "${HAL_BASE}/CMSIS_HAL/Include")
            # In visualGDB, the samples are in the parent from the HAL_BASE
            set_and_echo_dir(HAL_TEMPLATE_INC "${HAL_BASE}/../VendorSamples/L4/Projects/B-L475E-IOT01A/Templates/Inc")
        endif()
    else()
        message(STATUS "Skipped VisualGDB, found HAL_BASE=${HAL_BASE}")
    endif()

    message(STATUS "Completed VisualGDB detection.")
endif() # if visualgdb_config.cmake

set(VISUALGDB_CONFIG_CMAKE_INCLUDED TRUE)
