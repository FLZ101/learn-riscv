#!/bin/bash

set -e

ROOT=$(pwd)/../..
$ROOT/llvm-project/build/bin/llvm-mc -triple=riscv64 --assemble --filetype=asm -o b.s.s b.s
