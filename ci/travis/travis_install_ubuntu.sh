#!/usr/bin/env bash

set -e
set -x

sudo apt-get update -qq
sudo apt-get install -y -qq \
    gdb binutils ccache cmake flex bison ninja-build

sudo apt-get install -y -qq g++-4.9