#!/bin/bash

set -e

# sudo dnf install ncurses-devel
[[ -e busybox ]] || git clone https://git.busybox.net/busybox
cd busybox
git checkout 1_32_1
export PATH=~/opt/riscv/bin:$PATH
CROSS_COMPILE=riscv64-unknown-linux-gnu- make defconfig
CROSS_COMPILE=riscv64-unknown-linux-gnu- make menuconfig
    # Settings / Build Options / Build static library
CROSS_COMPILE=riscv64-unknown-linux-gnu- make -j 4
CROSS_COMPILE=riscv64-unknown-linux-gnu- make install

ls _install

