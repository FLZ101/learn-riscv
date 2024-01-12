#!/bin/bash

set -e

pushd app/clang
bash build.sh
popd
