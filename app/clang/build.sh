#!/bin/bash

set -e

ROOT=$(pwd)/../..
export PATH=$ROOT/llvm-project/build/bin:$PATH

TOOLCHAIN=$HOME/opt/riscv

FLAGS="-g -target riscv64-unknown-linux-gnu --sysroot=$TOOLCHAIN/sysroot --gcc-toolchain=$TOOLCHAIN"
clang --version
clang $FLAGS -o hello-c.exe hello.c
clang $FLAGS -o hello-c-static.exe -static hello.c
clang++ $FLAGS -o hello-cpp.exe hello.cpp
clang++ $FLAGS -o hello-cpp-static.exe hello.cpp
