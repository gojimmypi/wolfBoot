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

unset(STM32CUBEIDE_ROOT       CACHE)
unset(STM32CUBEIDE_FOUND      CACHE)
unset(STM32CUBEIDE_VERSION    CACHE)
unset(STM32CUBEIDE_EXECUTABLE CACHE)

function(_stm32cubeide_set_from_exec EXE)
    if(NOT EXISTS "${EXE}")
        return()
    endif()
    set(STM32CUBEIDE_EXECUTABLE "${EXE}" PARENT_SCOPE)
    # Root: up two dirs works for Linux default; handle macOS bundle separately below.
    get_filename_component(_dir "${EXE}" DIRECTORY)
    if(CMAKE_HOST_APPLE AND _dir MATCHES "\\.app/Contents/MacOS$")
        get_filename_component(_root "${_dir}/../.." REALPATH)
    else()
        get_filename_component(_root "${_dir}/.." REALPATH)
    endif()
    set(STM32CUBEIDE_ROOT "${_root}" PARENT_SCOPE)

    # Version heuristic from directory names like STM32CubeIDE_1.15.0
    string(REGEX MATCH "STM32[Cc]ubeIDE[_-]([0-9]+\\.[0-9]+\\.[0-9]+)" _m "${_root}")
    if(_m)
        string(REGEX REPLACE ".*STM32[Cc]ubeIDE[_-]([0-9]+\\.[0-9]+\\.[0-9]+).*" "\\1" _ver "${_root}")
        set(STM32CUBEIDE_VERSION "${_ver}" PARENT_SCOPE)
    endif()
endfunction()

# 1) Hints from environment or cache
set(_HINTS "")
if(DEFINED ENV{STM32CUBEIDE_DIR})
    list(APPEND _HINTS "$ENV{STM32CUBEIDE_DIR}")
endif()

if(DEFINED STM32CUBEIDE_DIR)
    list(APPEND _HINTS "${STM32CUBEIDE_DIR}")
endif()

if(DEFINED ENV{STM32CUBEIDE_ROOT})
    list(APPEND _HINTS "$ENV{STM32CUBEIDE_ROOT}")
endif()

if(DEFINED STM32CUBEIDE_ROOT)
    list(APPEND _HINTS "${STM32CUBEIDE_ROOT}")
endif()

foreach(h ${_HINTS})
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
        find_program(_EXE NAMES STM32CubeIDE.exe)
    elseif(CMAKE_HOST_APPLE OR CMAKE_HOST_UNIX)
        find_program(_EXE NAMES stm32cubeide)
    endif()
    if(_EXE)
        _stm32cubeide_set_from_exec("${_EXE}")
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
            list(SORT _candidates)
            foreach(c ${_candidates})
                if(EXISTS "${c}/STM32CubeIDE.exe")
                    _stm32cubeide_set_from_exec("${c}/STM32CubeIDE.exe")
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
    set(STM32CUBEIDE_FOUND TRUE)
endif()

mark_as_advanced(STM32CUBEIDE_EXECUTABLE STM32CUBEIDE_ROOT STM32CUBEIDE_VERSION)
