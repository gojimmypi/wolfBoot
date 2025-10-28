@echo off
setlocal

REM Desired install directory
set "inst=C:\VS\BuildTools"

REM Clean previous install directory if present (optional)
if exist "%inst%" (
  echo Deleting prior install dir: %inst%
  rmdir /s /q "%inst%"
)

REM Path to response file for override args
set "argsfile=C:\VS\install_args.txt"

REM Ensure parent folder exists
if not exist "C:\VS" mkdir "C:\VS"

REM Create override args file (one argument per line)
> "%argsfile%" (
  echo --installPath %inst%
  echo --quiet
  echo --wait
  echo --norestart
  echo --add Microsoft.VisualStudio.Workload.VCTools
  echo --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64
  echo --add Microsoft.VisualStudio.Component.VC.CMake.Project
  echo --add Microsoft.VisualStudio.Component.Windows10SDK.19041
  echo --includeRecommended
  echo --log %inst%\vsinstall.log
)

REM Run winget install with override via response file
echo Installing Visual Studio Build Tools to %inst% ...
winget install -e --id Microsoft.VisualStudio.2022.BuildTools --override "@%argsfile%"

REM Check success
if %ERRORLEVEL% neq 0 (
  echo.
  echo *** ERROR: winget install failed with exit code %ERRORLEVEL% ***
  echo See log at %inst%\vsinstall.log (or %argsfile%)
  exit /b %ERRORLEVEL%
)

echo.
echo Installation requested. Verifying installed path...
"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -products Microsoft.VisualStudio.Product.BuildTools -property installationPath

echo.
echo Done. Launch the Developer Tools with:
echo     "%inst%\Common7\Tools\VsDevCmd.bat"
endlocal
