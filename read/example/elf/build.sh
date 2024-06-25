#!/bin/bash

set -e

export PATH=~/opt/riscv/bin:$PATH

riscv64-unknown-linux-gnu-gcc -S a.c
# riscv64-unknown-linux-gnu-gcc -c -save-temps a.c
riscv64-unknown-linux-gnu-gcc -c a.c

riscv64-unknown-linux-gnu-gcc -c b.c
# riscv64-unknown-linux-gnu-gcc -static -c b.c

riscv64-unknown-linux-gnu-gcc -o b.exe a.o b.o
# riscv64-unknown-linux-gnu-gcc -static -o b.exe a.o b.o

# riscv64-unknown-linux-gnu-objdump -t a.o
# riscv64-unknown-linux-gnu-objdump -r a.o
# riscv64-unknown-linux-gnu-objdump -d a.o

riscv64-unknown-linux-gnu-objdump -r b.o

# riscv64-unknown-linux-gnu-objdump -t b.exe
