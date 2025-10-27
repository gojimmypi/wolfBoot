cls

setlocal enabledelayedexpansion

type tools\scripts\gen_vs.bat


rem 1) Nuke the VS binary dir cache
if exist "IDE\VisualStudio" (
    rmdir /s /q "IDE\VisualStudio" || (echo [ERROR] Failed to remove "IDE\VisualStudio". Exit code: !errorlevel!
                                       exit /b !errorlevel!
                                      )
)

if exist "build-stm32h7" (
    rmdir /s /q "build-stm32h7" || (echo [ERROR] Failed to remove "build-stm32h7". Exit code: !errorlevel!
                                       exit /b !errorlevel!
                                      )
)



rem Ensure we are in 64 bit mode:
call "%ProgramFiles%\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvarsall.bat" x64

rem 2) Fresh host-only configure (no ARM toolchain)
rem -A x64
rem   -D SIGN=ED25519

cmake -S . -B IDE\VisualStudio ^
  -G "Visual Studio 17 2022" ^
  -D WOLFBOOT_TARGET=sim ^
  -A x64 ^
  -D HASH=SHA256 ^
  -D SIGN=ECC256 ^
  -D DELTA_UPDATES=yes ^
  -D BUILD_TEST_APPS=OFF ^
  -D BUILD_IMAGE=OFF ^
  -D USE_64BIT_LIBS=ON


rem 3) Build the host tools
:: cmake --build IDE\VisualStudio --config Debug --target sign_host

cmake --build IDE\VisualStudio --config Debug --target keytools

:: cmake --build IDE\VisualStudio --config Debug --target wolfcrypt

echo""
echo "Find .lib files:"
dir *.lib /s

echo""
 echo "Find compile_commands.json file:"
dir compile_commands.json /s

cd IDE\VisualStudio

fsutil file createnew test.bin 1024

.\keygen.exe --ed25519 -g wolfboot_signing_private_key.der -keystoreDir .

.\sign.exe   --ed25519 --sha256 .\test.bin .\wolfboot_signing_private_key.der 1

cd ..\..\

rem 4) Open the solution
REM  start "" .\IDE\VisualStudio\wolfBoot.sln

type gen_vs.log

