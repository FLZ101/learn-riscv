#!/bin/bash

set -e

# sudo yum install autoconf automake python3 libmpc-devel mpfr-devel gmp-devel gawk  bison flex texinfo patchutils gcc gcc-c++ zlib-devel expat-devel
# sudo yum install expect
[[ -e riscv-gnu-toolchain ]] || git clone https://github.com/riscv/riscv-gnu-toolchain
pushd riscv-gnu-toolchain
git checkout 2023.11.08
sed -i -e 's@https://gcc.gnu.org/git/gcc.git@https://github.com/gcc-mirror/gcc.git@' .gitmodules
make clean
./configure --prefix=$HOME/opt/riscv-32 --disable-multilib --with-arch=rv32ima
# make newlib
make linux
popd

pushd app/hello
bash build-32.sh
popd

