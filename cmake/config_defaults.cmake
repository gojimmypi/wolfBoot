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
#---------------------------------------------------------------------------------------------
set(DETECT_VISUALGDB true)
set(DETECT_MINGW     true)
set(DETECT_CUBEIDE   true)
set(DETECT_VS2022    true)
set(DETECT_LLVM      true)
#---------------------------------------------------------------------------------------------

# Enable HAL download only implemented for TMS devices at this time.
# See [WOLFBOOT_ROOT]/cmake/stm32_hal_download.cmake
# and [WOLFBOOT_ROOT]/cmake/downloads/stm32_hal_download.cmake
set(ENABLE_HAL_DOWNLOAD true)
set(FOUND_HAL_BASE      false)

# optionally use .config files; See CMakePresets.json instead
set(USE_DOT_CONFIG      false)

# Init
SET(HOST_CC_HINT_DIRECTORIES "")

include(cmake/current_user.cmake)
get_current_user(CURRENT_USER)
message(STATUS "Current user detected: ${CURRENT_USER}")


# Requires CMake 3.19 (or newer for string(JSON); --format=json is available on recent CMake (youÃ¢â‚¬â„¢re on 3.31).
function(preset_exists name out_var)
    # Use the same cmake that is running this configure
    set(_cmake "${CMAKE_COMMAND}")

    # Be explicit about the source dir (important in some IDE invocations)
    execute_process(
        COMMAND "${_cmake}" -S "${CMAKE_SOURCE_DIR}" --list-presets=configure --format=json
        OUTPUT_VARIABLE _json
        ERROR_VARIABLE  _err
        RESULT_VARIABLE _rc
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_STRIP_TRAILING_WHITESPACE
    )
    message(STATUS "list-presets rc=${_rc}")
    if(_rc)
        message(STATUS "list-presets stderr: ${_err}")
    endif()
    set(_found OFF)
    if(_rc EQUAL 0 AND _json)
        # Parse JSON: get length and scan for matching .name
        string(JSON _len LENGTH "${_json}" presets)
        if(_len GREATER 0)
            math(EXPR _last "${_len} - 1")
            foreach(i RANGE 0 ${_last})
                string(JSON _nm GET "${_json}" presets ${i} name)
                if(_nm STREQUAL "${name}")
                    set(_found ON)
                    break()
                endif()
            endforeach()
        endif()
    endif()
    set(${out_var} ${_found} PARENT_SCOPE)
endfunction()


if(NOT EXISTS "${CMAKE_SOURCE_DIR}/CMakePresets.json")
    message(WARNING "No CMakePresets.json found at ${CMAKE_SOURCE_DIR}")
endif()
set(_has_var "HAS_${WOLFBOOT_TARGET}")
preset_exists("${WOLFBOOT_TARGET}" HAS_${WOLFBOOT_TARGET})
message(STATUS "Has preset ${WOLFBOOT_TARGET}: ${${_has_var}}")
#---------------------------------------------------------------------------------------------
# There are different configuration modes:
#
#   - Using CMake Presets. (preferred, use cacheVariables from CMakePresets.json, optional CMakeUserPresets.json)
#   - Using a .config file. See load_dot_config()
#   - Command-line options; can also be used to supplement above configurations.
#---------------------------------------------------------------------------------------------

# Where should configuration values come from?
#   dot     : parse .config via load_dot_config()
#   preset  : use cacheVariables from CMakePresets.json
if( EXISTS "./.config")
    message(STATUS "Found a .config file, will parse")
    set(WOLFBOOT_CONFIG_MODE "dot" CACHE STRING "Config source: dot or preset")
    set_property(CACHE WOLFBOOT_CONFIG_MODE PROPERTY STRINGS dot preset)
else()
    message(STATUS "No .config file found.")
endif()

if(WOLFBOOT_CONFIG_MODE STREQUAL "dot")
    message(STATUS "Config mode: dot (.config cache)")
    include(cmake/load_dot_config.cmake)
    message(STATUS "Loading config from: ${CMAKE_SOURCE_DIR}")
    load_dot_config("${CMAKE_SOURCE_DIR}/.config")

elseif(WOLFBOOT_CONFIG_MODE STREQUAL "preset")
    message(STATUS "Config mode: preset (using cacheVariables; skipping .config)")

else()
    message(STATUS "Not using .config nor CMakePresets.json for WOLFBOOT_CONFIG_MODE.")
endif()



# The ST CubeIDE location is searched in cmake/cube_ide_config.cmake
# Want to specify your specific STCubeIDE? Uncomment and set it here:
#   set(STM32CUBEIDE_DIR "/your/path")
if(NOT WOLFBOOT_HAS_BASE_PRESET AND (NOT "${WOLFBOOT_CONFIG_MODE}" STREQUAL "dot"))
    message(STATUS "See preset for wolfBoot target: ${WOLFBOOT_TARGET}")
    message(STATUS "-- WOLFBOOT_HAS_BASE_PRESET not found. All presets must inherit base config.")
endif()

# set(ARM_GCC_BIN "")
if (CMAKE_HOST_WIN32)
    # Optional: derive MSVC bin dirs from environment (if a VS Dev Prompt was used)
    set(_VC_HINTS "")
    if(DEFINED ENV{VCToolsInstallDir})
        message(STATUS "Found VCToolsInstallDir=$ENV{VCToolsInstallDir}")
        message(STATUS "Appending _VC_HINTS")
        list(APPEND _VC_HINTS
                    "$ENV{VCToolsInstallDir}/bin/Hostx64/x64"
                    "$ENV{VCToolsInstallDir}/bin/Hostx64/x86"
                    "$ENV{VCToolsInstallDir}/bin/Hostx86/x64"
                    "$ENV{VCToolsInstallDir}/bin/Hostx86/x86")
    endif()

    # Visual Studio Hints
    if(DETECT_VISUALGDB AND DETECT_MINGW)
        message(STATUS "Appending VisualGDB Hints")
        list(APPEND HOST_CC_HINT_DIRECTORIES
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
        )
    endif()

    # Visual Studio hints
    if(DETECT_VS2022)
        message(STATUS "Appending Visual Studio 2022 Hints")
        list(APPEND HOST_CC_HINT_DIRECTORIES
                    # Environment-derived VS bin dirs if present
                    ${_VC_HINTS}

                    # Visual Studio 2022 (all editions)
                    "C:/Program Files/Microsoft Visual Studio/2022/Enterprise/VC/Tools/MSVC/bin/Hostx64/x64"
                    "C:/Program Files/Microsoft Visual Studio/2022/Professional/VC/Tools/MSVC/bin/Hostx64/x64"
                    "C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Tools/MSVC/bin/Hostx64/x64"
                    "C:/Program Files (x86)/Microsoft Visual Studio/2022/Enterprise/VC/Tools/MSVC/bin/Hostx64/x64"
                    "C:/Program Files (x86)/Microsoft Visual Studio/2022/Professional/VC/Tools/MSVC/bin/Hostx64/x64"
                    "C:/Program Files (x86)/Microsoft Visual Studio/2022/Community/VC/Tools/MSVC/bin/Hostx64/x64"
        )
    endif()

    # LLVM Hints
    if(DETECT_LLVM)
        message(STATUS "Appending LLVM Hints")
        list(APPEND HOST_CC_HINT_DIRECTORIES
                    # LLVM
                    "C:/Program Files/LLVM/bin"

                    # TODO code?
        )
    endif()

    # Prefer environment if available (works from VS Dev Prompt / VS CMake)
    if (CMAKE_HOST_WIN32 AND DEFINED ENV{VCINSTALLDIR} AND DEFINED ENV{VCToolsVersion})
        file(TO_CMAKE_PATH "$ENV{VCINSTALLDIR}" _VCINSTALLDIR)
        set(_VCTOOLS "$_VCINSTALLDIR/Tools/MSVC/$ENV{VCToolsVersion}")
        list(APPEND HOST_CC_HINT_DIRECTORIES
                    "${_VCTOOLS}/bin/Hostx64/x64"
                    "${_VCTOOLS}/bin/Hostx64/x86"
                    "${_VCTOOLS}/bin/Hostx86/x64"
                    "${_VCTOOLS}/bin/Hostx86/x86"
        )
    endif()

    if (CMAKE_HOST_WIN32)
        set(_VSWHERE "C:/Program Files (x86)/Microsoft Visual Studio/Installer/vswhere.exe")
        if (EXISTS "${_VSWHERE}")
            execute_process(COMMAND "${_VSWHERE}" -latest -requires Microsoft.Component.MSBuild -property installationPath
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
                message(STATUS "Found edition: ${_ed}")
                file(GLOB _msvc LIST_DIRECTORIES TRUE "${_ed}/VC/Tools/MSVC/*")
                list(SORT _msvc COMPARE NATURAL ORDER DESCENDING)
                foreach(_ver ${_msvc})
                    message(STATUS "Appending Visual Studio Version ${_ver} hint files")
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
