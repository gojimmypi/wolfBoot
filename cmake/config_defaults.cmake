# wolfboot/cmake/config_defaults.cmake
#
# Copyright (C) 2025 wolfSSL Inc.
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

# This is NOT a place for device-specific project settings. For that, see CMakePresets.json

# Ensure this file is only included and initialized once
if(CMAKE_VERSION VERSION_LESS 3.10)
    # Fallback path for older CMake
    if(DEFINED CONFIG_DEFAULTS_CMAKE_INCLUDED)
        return()
    endif()
else()
    include_guard(GLOBAL)
endif()



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

include(cmake/current_user.cmake)

get_current_user(CURRENT_USER)
message(STATUS "Current user detected: ${CURRENT_USER}")


# The ST CubeIDE location is searched in cmake/cube_ide_config.cmake
# Want to specify your specific STCubeIDE? Uncomment and set it here:
#   set(STM32CUBEIDE_DIR "/your/path")
if(NOT WOLFBOOT_HAS_BASE_PRESET AND (NOT "${WOLFBOOT_CONFIG_MODE}" STREQUAL "dot"))
    message(STATUS "See preset for wolfBoot target: ${WOLFBOOT_TARGET}")
    message(FATAL_ERROR "WOLFBOOT_HAS_BASE_PRESET not found. All presets must inherit base config.")
endif()

# set(ARM_GCC_BIN "")
if (CMAKE_HOST_WIN32)
    # Optional: derive MSVC bin dirs from environment (if a VS Dev Prompt was used)
    set(_VC_HINTS "")
    if(DEFINED ENV{VCToolsInstallDir})
    list(APPEND _VC_HINTS "$ENV{VCToolsInstallDir}/bin/Hostx64/x64"
                            "$ENV{VCToolsInstallDir}/bin/Hostx64/x86"
                            "$ENV{VCToolsInstallDir}/bin/Hostx86/x64"
                            "$ENV{VCToolsInstallDir}/bin/Hostx86/x86")
    endif()
    SET(HOST_CC_HINT_DIRECTORIES

        # Visual Studio 2022 (all editions)
        "C:/Program Files/Microsoft Visual Studio/2022/Enterprise/VC/Tools/MSVC/bin/Hostx64/x64"
        "C:/Program Files/Microsoft Visual Studio/2022/Professional/VC/Tools/MSVC/bin/Hostx64/x64"
        "C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Tools/MSVC/bin/Hostx64/x64"
        "C:/Program Files (x86)/Microsoft Visual Studio/2022/Enterprise/VC/Tools/MSVC/bin/Hostx64/x64"
        "C:/Program Files (x86)/Microsoft Visual Studio/2022/Professional/VC/Tools/MSVC/bin/Hostx64/x64"
        "C:/Program Files (x86)/Microsoft Visual Studio/2022/Community/VC/Tools/MSVC/bin/Hostx64/x64"

        # VisualGDB / SysGCC MinGW (common system-wide)
        "C:/SysGCC/mingw64/bin"
        "C:/SysGCC/MinGW64/bin"
        "C:/SysGCC/mingw32/bin"
        "C:/SysGCC/MinGW32/bin"

        # VisualGDB user-local toolchains
        "$ENV{LOCALAPPDATA}/VisualGDB/Toolchains/mingw64/bin"
        "$ENV{LOCALAPPDATA}/VisualGDB/Toolchains/MinGW64/bin"
        "$ENV{LOCALAPPDATA}/VisualGDB/Toolchains/mingw32/bin"
        "$ENV{LOCALAPPDATA}/VisualGDB/Toolchains/MinGW32/bin"

        # LLVM
        "C:/Program Files/LLVM/bin"

        # Environment-derived VS bin dirs if present
        ${_VC_HINTS}
    )

    # Prefer environment if available (works from VS Dev Prompt / VS CMake)
    if (CMAKE_HOST_WIN32 AND DEFINED ENV{VCINSTALLDIR} AND DEFINED ENV{VCToolsVersion})
      file(TO_CMAKE_PATH "$ENV{VCINSTALLDIR}" _VCINSTALLDIR)
      set(_VCTOOLS "$_VCINSTALLDIR/Tools/MSVC/$ENV{VCToolsVersion}")
      list(APPEND HOST_CC_HINT_DIRECTORIES
        "${_VCTOOLS}/bin/Hostx64/x64"
        "${_VCTOOLS}/bin/Hostx64/x86"
        "${_VCTOOLS}/bin/Hostx86/x64"
        "${_VCTOOLS}/bin/Hostx86/x86")
    endif()

    if (CMAKE_HOST_WIN32)
      set(_VSWHERE "C:/Program Files (x86)/Microsoft Visual Studio/Installer/vswhere.exe")
      if (EXISTS "${_VSWHERE}")
        execute_process(
          COMMAND "${_VSWHERE}" -latest -requires Microsoft.Component.MSBuild -property installationPath
          OUTPUT_VARIABLE _VS_PATH OUTPUT_STRIP_TRAILING_WHITESPACE
        )
        if (_VS_PATH)
          # Find all versioned MSVC toolsets under this install, pick highest (natural sort)
          file(GLOB _MSVC_DIRS LIST_DIRECTORIES TRUE "${_VS_PATH}/VC/Tools/MSVC/*")
          list(SORT _MSVC_DIRS COMPARE NATURAL ORDER DESCENDING)
          list(GET _MSVC_DIRS 0 _MSVC_TOOLS)
          list(APPEND HOST_CC_HINT_DIRECTORIES
            "${_MSVC_TOOLS}/bin/Hostx64/x64"
            "${_MSVC_TOOLS}/bin/Hostx64/x86"
            "${_MSVC_TOOLS}/bin/Hostx86/x64"
            "${_MSVC_TOOLS}/bin/Hostx86/x86")
        endif()
      endif()
    endif()

    if (CMAKE_HOST_WIN32)
      foreach(_root
        "C:/Program Files/Microsoft Visual Studio/2022"
        "C:/Program Files (x86)/Microsoft Visual Studio/2022")
        file(GLOB _editions LIST_DIRECTORIES TRUE "${_root}/*")  # Enterprise/Professional/Community
        foreach(_ed ${_editions})
          file(GLOB _msvc LIST_DIRECTORIES TRUE "${_ed}/VC/Tools/MSVC/*")
          list(SORT _msvc COMPARE NATURAL ORDER DESCENDING)
          foreach(_ver ${_msvc})
            list(APPEND HOST_CC_HINT_DIRECTORIES
              "${_ver}/bin/Hostx64/x64"
              "${_ver}/bin/Hostx64/x86"
              "${_ver}/bin/Hostx86/x64"
              "${_ver}/bin/Hostx86/x86")
          endforeach()
        endforeach()
      endforeach()
    endif()

    message(STATUS "HOST_CC_HINT_DIRECTORIES=${HOST_CC_HINT_DIRECTORIES}")

else()
    message(STATUS "HOST_CC_HINT_DIRECTORIES not set, assuming tools in path. See wolfboot/cmake/config_defaults.cmake")
    set(HOST_CC_HINT_DIRECTORIES "")
endif()

set(CONFIG_DEFAULTS_CMAKE_INCLUDED TRUE)
