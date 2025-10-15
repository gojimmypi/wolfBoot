rmdir /s /q build-stm32l4

cmake --preset stm32l4


:: cmake --build --preset windows-stm32l4 --parallel 4 -v

cmake --build --preset stm32l4
