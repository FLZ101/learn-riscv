#!/bin/bash

set -e

NAME=demo_throw_2
EXE=$NAME.exe
# dnf install libstdc++-static
# -S
g++ -g -static-libstdc++ -save-temps -fverbose-asm -o $EXE $NAME.cpp
objdump -d $EXE >$NAME.s.txt
readelf -w $EXE >$NAME.w.txt

