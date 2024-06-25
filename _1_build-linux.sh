#!/bin/bash

set -e

# sudo dnf install bc
if [[ ! -e linux-5.10.199 ]] ; then
	wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.10.199.tar.xz
	tar xvf linux-5.10.199.tar.xz
fi
cd linux-5.10.199
export PATH=~/opt/riscv/bin:$PATH
make ARCH=riscv CROSS_COMPILE=riscv64-unknown-linux-gnu- defconfig
make ARCH=riscv CROSS_COMPILE=riscv64-unknown-linux-gnu- -j 4

ls -l arch/riscv/boot/Image

