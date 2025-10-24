cls

setlocal enabledelayedexpansion

type tools\scripts\gen_vs.bat

rem 1) Nuke the VS binary dir cache
if exist "IDE\VisualStudio" (
    rmdir /s /q "IDE\VisualStudio" || (echo [ERROR] Failed to remove "IDE\VisualStudio". Exit code: !errorlevel!
                                       exit /b !errorlevel!
                                      )
)

rem 2) Fresh host-only configure (no ARM toolchain)
cmake -S . -B IDE\VisualStudio ^
  -G "Visual Studio 17 2022" -A x64 ^
  -D WOLFBOOT_TARGET=sim ^
  -D BUILD_TEST_APPS=OFF ^
  -D BUILD_IMAGE=OFF ^
  -D CMAKE_TOOLCHAIN_FILE:FILEPATH=

rem 3) Build the host tools
cmake --build IDE\VisualStudio --config Debug --target keytools

:: cmake --build IDE\VisualStudio --config Debug --target wolfcrypt

dir *.lib /s


cd IDE\VisualStudio

fsutil file createnew test.bin 1024

.\keygen.exe --ed25519 -g wolfboot_signing_private_key.der -keystoreDir .

.\sign.exe   .\test.bin .\wolfboot_signing_private_key.der 1 --ed25519 --sha256


rem 4) Open the solution
:: start "" IDE\VisualStudio\wolfBoot.sln

