cmake_minimum_required(VERSION 3.20)

set(WOLFBOOT_TARGET "stm32l4")

message(STATUS "Begin app CMakeLists.txt for $WOLFBOOT_TARGET")

if(WOLFBOOT_TARGET STREQUAL "stm32l4")
    add_compile_definitions(STM32L475xx)
endif()

message(STATUS "Begin App CMakeLists.txt")
# If you do not pass a toolchain on the command line, default to wolfBoot's
# arm-none-eabi toolchain file.
if(USE_WOLFBOOT)
    if(NOT CMAKE_TOOLCHAIN_FILE)
        set(CMAKE_TOOLCHAIN_FILE
            "${CMAKE_CURRENT_SOURCE_DIR}/wolfBoot/cmake/toolchain_arm-none-eabi.cmake"
            CACHE FILEPATH "Toolchain file for ARM GCC" FORCE
        )
    endif()
endif()

project(wolfboot_blinky C)

# Path to your wolfBoot submodule
set(WOLFBOOT_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/wolfBoot")
message(STATUS "WOLFBOOT_ROOT:${WOLFBOOT_ROOT}")

# Optional: build wolfBoot as a sub-project (adjust if your wolfBoot CMake
# layout is different, or remove if you just want the headers/tools).
if(USE_WOLFBOOT)
    if(EXISTS "${WOLFBOOT_ROOT}/CMakeLists.txt")
        add_subdirectory("${WOLFBOOT_ROOT}" "${CMAKE_BINARY_DIR}/wolfboot_build" EXCLUDE_FROM_ALL)
    endif()
endif()

# Application firmware target
if(USE_WOLFBOOT)
    add_executable(app.elf
        # with wolfBoot, the app is exciting: blinky!
        app/startup_stm32l4.c
        ${WOLFBOOT_ROOT}/hal/stm32l4.c
        ${WOLFBOOT_ROOT}/test-app/led.c
        app/main.c
    )

    # Includes: local app headers + wolfBoot headers
    target_include_directories(app.elf PRIVATE
        "${CMAKE_CURRENT_SOURCE_DIR}/app"
        "${CMAKE_CURRENT_SOURCE_DIR}/app/include"
        "${WOLFBOOT_ROOT}/include"
        "${WOLFBOOT_ROOT}/hal"
    )

else()
    add_executable(app.elf
        # without wolfBoot, the app is boring: no blinky
        app/main.c
    )

    # Includes: local app headers only
    target_include_directories(app.elf PRIVATE
        "${CMAKE_CURRENT_SOURCE_DIR}/app"
        "${CMAKE_CURRENT_SOURCE_DIR}/app/include"
    )
endif()

# Match your source: #ifdef TARGET_stm32l4
target_compile_definitions(app.elf PRIVATE TARGET_stm32l4)

# Let the toolchain or you decide the CPU flags; if you want hard-coded flags,
# you can uncomment and tweak these:
# target_compile_options(app.elf PRIVATE
#     -mcpu=cortex-m4
#     -mthumb
#     -ffunction-sections
#     -fdata-sections
# )
# target_link_options(app.elf PRIVATE
#     -mcpu=cortex-m4
#     -mthumb
#     -Wl,--gc-sections
# )

# Binary and signed-binary paths
set(APP_BIN         "${CMAKE_CURRENT_BINARY_DIR}/app.bin")
set(APP_SIGNED_BIN  "${CMAKE_CURRENT_BINARY_DIR}/app_signed.bin")

# Convert ELF to raw binary
add_custom_command(
    TARGET app.elf POST_BUILD
    COMMAND ${CMAKE_OBJCOPY} -O binary $<TARGET_FILE:app.elf> "${APP_BIN}"
    COMMENT "Converting app.elf to app.bin"
)

set(LINKER_SCRIPT "${CMAKE_CURRENT_SOURCE_DIR}/cmake/stm32l4.ld")

target_link_options(app.elf PRIVATE
    -T${LINKER_SCRIPT}
    -mcpu=cortex-m4
    -mthumb
    -Wl,--gc-sections
)

target_compile_options(app.elf PRIVATE
    -mcpu=cortex-m4
    -mthumb
    -ffunction-sections
    -fdata-sections
)

# You need to point these to your real wolfBoot signing script and key.
# They are intentionally left empty to avoid guessing paths.
set(WOLFBOOT_SIGN_SCRIPT "" CACHE FILEPATH "Path to wolfBoot signing script (for example, sign.py)")
set(WOLFBOOT_SIGN_KEY    "" CACHE FILEPATH "Path to application signing private key")

# Find Python to run the signing script
find_package(Python3 COMPONENTS Interpreter REQUIRED)

# Target that produces a signed image, depending on app.elf/app.bin
if(USE_WOLFBOOT)
    add_custom_target(app_signed ALL
        DEPENDS app.elf
        COMMAND "${Python3_EXECUTABLE}" "${WOLFBOOT_SIGN_SCRIPT}"
            --in "${APP_BIN}"
            --out "${APP_SIGNED_BIN}"
            --key "${WOLFBOOT_SIGN_KEY}"
            # Add any other arguments your sign script needs, for example:
            # --target stm32l4
        COMMENT "Signing application binary for wolfBoot"
        VERBATIM
    )
endif()

# Helpful status messages
message(STATUS "WOLFBOOT_ROOT          = ${WOLFBOOT_ROOT}")
message(STATUS "CMAKE_TOOLCHAIN_FILE   = ${CMAKE_TOOLCHAIN_FILE}")
if(USE_WOLFBOOT)
    message(STATUS "WOLFBOOT_SIGN_SCRIPT   = ${WOLFBOOT_SIGN_SCRIPT}")
    message(STATUS "WOLFBOOT_SIGN_KEY      = ${WOLFBOOT_SIGN_KEY}")
    message(STATUS "Signed firmware output = ${APP_SIGNED_BIN}")
endif()
message(STATUS "Unsigned firmware bin  = ${APP_BIN}")
message(STATUS "End App CMakeLists.txt")
