@echo off
setlocal
set "inst=C:\VS\BuildTools"


winget install --id Microsoft.VisualStudio.2022.BuildTools ^
  --silent ^
  --location "%inst%" ^
  --override "--installPath \"%inst%\" --quiet --wait --norestart --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.VC.CMake.Project --add Microsoft.VisualStudio.Component.Windows10SDK.19041 --includeRecommended"

echo "To Un-install:"
echo "winget uninstall --id Microsoft.VisualStudio.2022.BuildTools"
