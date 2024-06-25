#!/bin/bash

set -e

llvm_dir=$(pwd)/llvm-project/build-r
llvm_dir=$(pwd)/llvm-project/build-r-stage2
$llvm_dir/bin/clang --version
if [[ ! -e build-r ]] ; then
	mkdir build-r && cd build-r
	cmake -DCMAKE_C_COMPILER=$llvm_dir/bin/clang \
        -C../test-suite/cmake/caches/ReleaseLTO-g.cmake  \
        ../test-suite
	cd ..
fi
cd build-r
cmake --build . --verbose
$llvm_dir/bin/llvm-lit -v -j 1 -o results.json .
