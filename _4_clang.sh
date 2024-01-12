#!/bin/bash

set -e

[[ -e llvm-project ]] || git clone https://github.com/llvm/llvm-project.git
cd llvm-project
git checkout llvmorg-15.0.7

# rm -rf build

cmake -G Ninja \
    -DCMAKE_BUILD_TYPE=Debug \
    -DLLVM_TARGETS_TO_BUILD="RISCV" \
    -DLLVM_ENABLE_PROJECTS="clang;lld" \
    -DLLVM_PARALLEL_LINK_JOBS=1 \
    -B build -S llvm -Wno-dev
# cmake --build build -j 8
cmake --build build -j 1
