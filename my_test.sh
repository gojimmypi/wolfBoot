#!/bin/bash

echo "Remove prior build directories..."
rm -rf ./build-stm32l4

echo "cmake --preset stm32l4"
      cmake --preset stm32l4

echo "cmake --build --preset stm32l4"
      cmake --build --preset stm32l4
