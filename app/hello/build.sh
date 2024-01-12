#!/bin/bash

set -e

export PATH=~/opt/riscv/bin:$PATH

riscv64-unknown-linux-gnu-gcc -o hello-c.exe hello.c
riscv64-unknown-linux-gnu-gcc -o hello-c-static.exe -static hello.c
riscv64-unknown-linux-gnu-g++ -o hello-cpp.exe hello.cpp
riscv64-unknown-linux-gnu-g++ -o hello-cpp-static.exe hello.cpp
