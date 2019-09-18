#!/usr/bin/env bash

set -e
set -x

mkdir build
(
    cd build
    cmake ..
    make -j 4
)