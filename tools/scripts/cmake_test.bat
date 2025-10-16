::!/cmd/batch

:: We must start in /tools/scripts, but build two directories up: from wolfBoot root
cd ../../

rmdir /s /q build-stm32l4

cmake --preset stm32l4


:: cmake --build --preset stm32l4 --parallel 4 -v

cmake --build --preset stm32l4


rmdir /s /q build-stm32l4
