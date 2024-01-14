#!/bin/bash

set -e

NAME=demo_throw_1
EXE=$NAME.exe
g++ -g -o $EXE $NAME.cpp
objdump -d $EXE >$NAME.s.txt
readelf -w $EXE >$NAME.w.txt
