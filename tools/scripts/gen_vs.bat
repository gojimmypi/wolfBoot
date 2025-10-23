cls

type tools\scripts\gen_vs.bat

rem 1) Nuke the VS binary dir cache
rmdir /s /q IDE\VisualStudio 2>nul

rem 2) Fresh host-only configure (no ARM toolchain)
cmake -S . -B IDE\VisualStudio ^
  -G "Visual Studio 17 2022" -A x64 ^
  -D WOLFBOOT_TARGET=sim ^
  -D BUILD_TEST_APPS=OFF ^
  -D BUILD_IMAGE=OFF ^
  -D CMAKE_TOOLCHAIN_FILE:FILEPATH=

rem 3) Build the host tools
cmake --build IDE\VisualStudio --config Debug --target keytools

cmake --build IDE\VisualStudio --config Debug --target wolfcrypt

dir *.lib /s

rem 4) Open the solution
start "" IDE\VisualStudio\wolfBoot.sln

