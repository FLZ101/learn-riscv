#!/bin/bash

set -e

wd=$(pwd)

copy_so()
{
    SYSROOT=~/opt/riscv/sysroot
    ROOT=.

    # find $SYSROOT -name '*.so' -or -name '*.so.*' -or -name 'ld*'

    for x in {/lib/ld-linux-riscv64-lp64d.so.1,/usr/bin/ld.so,/usr/lib64/lp64d/libc.so,/lib64/lp64d/libc.so.6,/lib/libstdc++.so,/lib/libstdc++.so.6,/lib/libstdc++.so.6.0.32,/lib64/lp64d/libstdc++.so,/lib64/lp64d/libstdc++.so.6,/lib64/lp64d/libstdc++.so.6.0.32,/usr/lib64/lp64d/libm.so,/lib64/lp64d/libm.so.6,/lib/libgcc_s.so,/lib/libgcc_s.so.1,/lib64/lp64d/libgcc_s.so.1,/lib64/lp64d/libgcc_s.so} ; do
        echo "-> $x"
        sudo mkdir -p $(dirname $ROOT$x)
        sudo cp $SYSROOT$x $ROOT$x
    done
}

# sudo dnf install e2fsprogs

create_image()
{
    dd if=/dev/zero of=root.bin bs=1M count=64
    mkfs.ext2 -F root.bin

    mkdir -p mnt
    sudo mount -o loop root.bin mnt
    cd mnt
    sudo cp -r $wd/busybox/_install/* .
    sudo mkdir -p app bin etc/init.d dev lib proc sbin tmp usr/{sbin,bin,lib}

    copy_so

    cd ..
    sudo umount mnt
}

[[ -e root.bin ]] || create_image

# sudo dnf install qemu-system-riscv

update_image()
{
    mkdir -p mnt
    sudo mount -o loop root.bin mnt
    cd mnt

    sudo rm -rf app
    sudo cp -r $wd/app .
    sudo mv app/rcS etc/init.d
    sudo chmod +x etc/init.d/rcS

    cd ..
    sudo umount mnt
}

update_image

qemu-system-riscv64 -nographic -machine virt -kernel linux-5.10.199/arch/riscv/boot/Image -append "root=/dev/vda rw console=ttyS0" -drive file=root.bin,format=raw,id=hd0 -device virtio-blk-device,drive=hd0
    # Ctrl-A X to quit

