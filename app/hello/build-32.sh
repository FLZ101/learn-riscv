#!/bin/bash

set -e

export PATH=~/opt/riscv-32/bin:$PATH

riscv32-unknown-linux-gnu-gcc -o 32-hello-c.exe hello.c
riscv32-unknown-linux-gnu-gcc -o 32-hello-c-static.exe -static hello.c
riscv32-unknown-linux-gnu-g++ -o 32-hello-cpp.exe hello.cpp
riscv32-unknown-linux-gnu-g++ -o 32-hello-cpp-static.exe hello.cpp
