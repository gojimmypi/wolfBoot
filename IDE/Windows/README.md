# wolfboot for Windows

A variety of Windows-based solutions exist. Here are notes for a no-IDE build on Windows from a DOS prompt.

See also:

- [VS Code](../VSCode/README.md)
- [CMake docs](../../CMake.md)
- [Compile docs](../../compile.md)
- [Windows docs](../../Windows.md)
- [Other docs](../../README.md)

# Example

See the [`[WOLFBOOT_ROOT]/tools/scripts/cmake_test.bat`](../../tools/scripts/cmake_test.bat) using cmake:

```dos
rmdir /s /q build-stm32l4

cmake --preset stm32l4
cmake --build --preset stm32l4
```

## Install MSVC Toolchain

Powershell:

```ps
# Pick your install directory
$inst = "C:\VS\BuildTools"

# Install MSVC, MSBuild, and Windows SDK into that directory
winget install --id Microsoft.VisualStudio.2022.BuildTools `
  --silent `
  --location "$inst" `
  --override "--installPath `"$inst`" --quiet --wait --norestart `
             --add Microsoft.VisualStudio.Workload.VCTools `
             --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
             --add Microsoft.VisualStudio.Component.VC.CMake.Project `
             --add Microsoft.VisualStudio.Component.Windows10SDK.19041 `
             --includeRecommended"
```

DOS:

```
:: Pick your install directory
set "inst=C:\VS\BuildTools"

:: Install MSVC toolchain, MSBuild, CMake support, and Windows 10 SDK
winget install --id Microsoft.VisualStudio.2022.BuildTools ^
  --silent ^
  --location "%inst%" ^
  --override "--installPath \"%inst%\" --quiet --wait --norestart ^
             --add Microsoft.VisualStudio.Workload.VCTools ^
             --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 ^
             --add Microsoft.VisualStudio.Component.VC.CMake.Project ^
             --add Microsoft.VisualStudio.Component.Windows10SDK.19041 ^
             --includeRecommended"

```

## Troubleshooting

#### cannot access the file

This error is typically caused by anti-virus software locking a file during build.

Consider excluding the build directory or executable from anti-virus scan.

```test
build-stm32l4\bin-assemble.exe - The process cannot access the file because it is being used by another process.
```
