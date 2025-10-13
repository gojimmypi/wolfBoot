# wolfboot/cmake/cube_ide_config.cmake
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

# See also https://www.st.com/resource/en/application_note/an5952-how-to-use-cmake-in-stm32cubeide-stmicroelectronics.pdf

# Usage:
#   set(STM32CUBEIDE_DIR "C:/ST/STM32CubeIDE_1.15.0" CACHE PATH "Hint to STM32CubeIDE root")
#   find_package(STM32CubeIDE REQUIRED)
#   message(STATUS "STM32CubeIDE: ${STM32CUBEIDE_EXECUTABLE} (root: ${STM32CUBEIDE_ROOT}, ver: ${STM32CUBEIDE_VERSION})")

include_guard(GLOBAL)
message(STATUS "Begin cube_ide_config.cmake")
unset(STM32CUBEIDE_ROOT       CACHE)
unset(STM32CUBEIDE_FOUND      CACHE)
unset(STM32CUBEIDE_VERSION    CACHE)
unset(STM32CUBEIDE_EXECUTABLE CACHE)

function(_stm32cubeide_set_from_exec PARAM_EXE)
    if(NOT EXISTS "${PARAM_EXE}")
        return()
    endif()
    set(STM32CUBEIDE_EXECUTABLE "${PARAM_EXE}" PARENT_SCOPE)
    # Root: up two dirs works for Linux default; handle macOS bundle separately below.
    get_filename_component(_dir "${PARAM_EXE}" DIRECTORY)
    if(CMAKE_HOST_APPLE AND _dir MATCHES "\\.app/Contents/MacOS$")
        get_filename_component(_root "${_dir}/../.." REALPATH)
    else()
        get_filename_component(_root "${_dir}/.." REALPATH)
    endif()

    message(STATUS "Found STM32CUBEIDE_ROOT=${_root}")
    set(STM32CUBEIDE_ROOT "${_root}" PARENT_SCOPE)

    # Version extract from directory names like STM32CubeIDE_1.15.0
    file(TO_CMAKE_PATH "${_root}" _root_norm)
    get_filename_component(_leaf "${_root_norm}" NAME)  # e.g. "STM32CubeIDE_1.14.1"

    set(_ver "")
    set(_mark "STM32CubeIDE_")
    string(FIND "${_leaf}" "${_mark}" _pos)
    if(NOT _pos EQUAL -1)
        string(LENGTH "${_mark}" _mlen)
        math(EXPR _start "${_pos} + ${_mlen}")
        string(SUBSTRING "${_leaf}" ${_start} -1 _ver_raw)
        string(STRIP "${_ver_raw}" _ver)
    endif()

    if(_ver) # e.g. "1.14.1"
        # set both locally and in parent scope for immediate logging + export
        set(STM32CUBEIDE_VERSION "${_ver}")
        set(STM32CUBEIDE_VERSION "${_ver}" PARENT_SCOPE)
        message(NOTICE "Found STM32CUBEIDE_VERSION=${_ver}")
    else()
        message(VERBOSE "Could not derive version (leaf='${_leaf}', root='${_root_norm}')")
    endif()
endfunction()

# 1) Hints from environment or cache
set(_HINTS "")
if(DEFINED ENV{STM32CUBEIDE_DIR})
    message(STATUS "Found env STM32CUBEIDE_DIR=$ENV{STM32CUBEIDE_DIR}")
    list(APPEND _HINTS "$ENV{STM32CUBEIDE_DIR}")
endif()

if(DEFINED STM32CUBEIDE_DIR)
    message(STATUS "Found STM32CUBEIDE_DIR=${STM32CUBEIDE_DIR}")
    list(APPEND _HINTS "${STM32CUBEIDE_DIR}")
endif()

if(DEFINED ENV{STM32CUBEIDE_ROOT})
    message(STATUS "Found env STM32CUBEIDE_ROOT=$ENV{STM32CUBEIDE_ROOT}")
    list(APPEND _HINTS "$ENV{STM32CUBEIDE_ROOT}")
endif()

if(DEFINED STM32CUBEIDE_ROOT)
    message(STATUS "Found STM32CUBEIDE_ROOT=${STM32CUBEIDE_ROOT}")
    list(APPEND _HINTS "${STM32CUBEIDE_ROOT}")
endif()

foreach(h ${_HINTS})
    message(STATUS "Looking for STM32CubeIDE.exe in ${h}")
    if(CMAKE_HOST_WIN32)
        if(EXISTS "${h}/STM32CubeIDE.exe")
            _stm32cubeide_set_from_exec("${h}/STM32CubeIDE.exe")
        endif()
    elseif(CMAKE_HOST_APPLE)
        if(EXISTS "${h}/STM32CubeIDE.app/Contents/MacOS/STM32CubeIDE")
            _stm32cubeide_set_from_exec("${h}/STM32CubeIDE.app/Contents/MacOS/STM32CubeIDE")
        elseif(EXISTS "${h}/Contents/MacOS/STM32CubeIDE")
            _stm32cubeide_set_from_exec("${h}/Contents/MacOS/STM32CubeIDE")
        endif()
    else()
        if(EXISTS "${h}/stm32cubeide")
            _stm32cubeide_set_from_exec("${h}/stm32cubeide")
        endif()
    endif()
endforeach()

# 2) PATH search
if(NOT STM32CUBEIDE_EXECUTABLE)
    if(CMAKE_HOST_WIN32)
        find_program(_CUBE_EXE NAMES "STM32CubeIDE.exe")
    elseif(CMAKE_HOST_APPLE OR CMAKE_HOST_UNIX)
        find_program(_CUBE_EXE NAMES "stm32cubeide")
    endif()
    if(_CUBE_EXE)
        _stm32cubeide_set_from_exec("${_CUBE_EXE}")
    endif()
endif()

# 3) OS-specific probing
if(NOT STM32CUBEIDE_EXECUTABLE)
    if(CMAKE_HOST_WIN32)
        # Try Registry: uninstall entries often expose InstallLocation
        # 64-bit and 32-bit views
        foreach(_HK
               "HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall"
               "HKLM\\SOFTWARE\\WOW6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall")
            execute_process(COMMAND reg query ${_HK} /f STM32CubeIDE /s
                            OUTPUT_VARIABLE _reg
                            ERROR_VARIABLE _reg_err
                            RESULT_VARIABLE _reg_rc)
            if(_reg_rc EQUAL 0 AND _reg MATCHES "InstallLocation\\s+REG_SZ\\s+([^\r\n]+)")
                string(REGEX REPLACE ".*InstallLocation\\s+REG_SZ\\s+([^\r\n]+).*" "\\1" _loc "${_reg}")
                string(REPLACE "\\" "/" _loc "${_loc}")
                if(EXISTS "${_loc}/STM32CubeIDE.exe")
                    _stm32cubeide_set_from_exec("${_loc}/STM32CubeIDE.exe")
                endif()
            endif()
        endforeach()

        # Common default roots
        if(NOT STM32CUBEIDE_EXECUTABLE)
            file(GLOB _candidates
                      "C:/ST/STM32CubeIDE_*"
                      "C:/Program Files/STMicroelectronics/STM32CubeIDE*"
                      "C:/Program Files (x86)/STMicroelectronics/STM32CubeIDE*")

            if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.7")
                list(SORT _candidates COMPARE NATURAL ORDER DESCENDING)
            else()
                list(SORT _candidates)
                list(REVERSE _candidates)
            endif()

            foreach(_this_c ${_candidates})
                message(STATUS "Looking at ${_this_c}")
                if(EXISTS "${_this_c}/STM32CubeIDE.exe")
                    message(STATUS "Found ${_this_c}/STM32CubeIDE.exe")
                    _stm32cubeide_set_from_exec("${_this_c}/STM32CubeIDE.exe")
                    break()
                endif()

                if(EXISTS "${_this_c}/STM32CubeIDE/STM32CubeIDE.exe")
                    message(STATUS "Found ${_this_c}/STM32CubeIDE/STM32CubeIDE.exe")
                    _stm32cubeide_set_from_exec("${_this_c}/STM32CubeIDE/STM32CubeIDE.exe")
                    break()
                endif()
            endforeach()
        endif()

    elseif(CMAKE_HOST_APPLE)
        # Standard Applications folder
        if(EXISTS "/Applications/STM32CubeIDE.app/Contents/MacOS/STM32CubeIDE")
            _stm32cubeide_set_from_exec("/Applications/STM32CubeIDE.app/Contents/MacOS/STM32CubeIDE")
        else()
            # Fall back: scan *.app names
            file(GLOB _apps "/Applications/STM32CubeIDE*.app")
            list(SORT _apps DESC)
            foreach(app ${_apps})
                if(EXISTS "${app}/Contents/MacOS/STM32CubeIDE")
                    _stm32cubeide_set_from_exec("${app}/Contents/MacOS/STM32CubeIDE")
                    break()
                endif()
            endforeach()

            # Spotlight as last resort
            if(NOT STM32CUBEIDE_EXECUTABLE)
                execute_process(COMMAND mdfind "kMDItemCFBundleIdentifier == com.st.stm32cubeide"
                                OUTPUT_VARIABLE _mdfind RESULT_VARIABLE _mdrc)
                if(_mdrc EQUAL 0 AND _mdfind)
                    string(REGEX MATCH ".*\\.app" _app "${_mdfind}")
                    if(_app AND EXISTS "${_app}/Contents/MacOS/STM32CubeIDE")
                        _stm32cubeide_set_from_exec("${_app}/Contents/MacOS/STM32CubeIDE")
                    endif()
                endif()
            endif()
        endif()

    else() # Linux
        # Desktop file -> Exec path
        if(EXISTS "/usr/share/applications/stm32cubeide.desktop")
            file(READ "/usr/share/applications/stm32cubeide.desktop" _desk)
            string(REGEX MATCH "Exec=([^ \n\r]+)" _m "${_desk}")
            if(_m)
                string(REGEX REPLACE "Exec=([^ \n\r]+).*" "\\1" _exec "${_desk}")
                # Resolve symlink if any
                execute_process(COMMAND bash -lc "readlink -f \"${_exec}\"" OUTPUT_VARIABLE _rl RESULT_VARIABLE _rc)
                if(_rc EQUAL 0)
                    string(STRIP "${_rl}" _rls)
                    if(EXISTS "${_rls}")
                        _stm32cubeide_set_from_exec("${_rls}")
                    endif()
                elseif(EXISTS "${_exec}")
                    _stm32cubeide_set_from_exec("${_exec}")
                endif()
            endif()
        endif()

        # Typical install roots under /opt
        if(NOT STM32CUBEIDE_EXECUTABLE)
            file(GLOB _candidates "/opt/st/stm32cubeide_*")
            list(SORT _candidates DESC)
            foreach(c ${_candidates})
                if(EXISTS "${c}/stm32cubeide")
                    _stm32cubeide_set_from_exec("${c}/stm32cubeide")
                    break()
                endif()
            endforeach()
        endif()
    endif() # Windows or Mac else Linux
endif() # !STM32CUBEIDE_EXECUTABLE


include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(STM32CubeIDE
                                  REQUIRED_VARS STM32CUBEIDE_EXECUTABLE STM32CUBEIDE_ROOT
                                  FAIL_MESSAGE "STM32CubeIDE not found. Set STM32CUBEIDE_DIR or add it to PATH."
)

if(STM32CUBEIDE_EXECUTABLE)
    message(STATUS "Found STM32 CubeIDE: ${STM32CUBEIDE_EXECUTABLE}")
    set(STM32CUBEIDE_FOUND TRUE)
else()
    message(STATUS "Not found: STM32 CubeIDE")
endif()

mark_as_advanced(STM32CUBEIDE_EXECUTABLE STM32CUBEIDE_ROOT STM32CUBEIDE_VERSION)
message(STATUS "End cube_ide_config.cmake")
