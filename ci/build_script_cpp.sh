#!/usr/bin/env bash

set -e
set -x

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

(
    rm -rf $DIST_DIR
    cd build
    $CMAKE $DIR/.. \
        ${CMAKE_ARGS} \
        -DCMAKE_INSTALL_PREFIX=$DIST_DIR
    $MAKE -j 4
    $MAKE install
)

(
cd $DIST_DIR
tar czvf knn-service-$OS.tar.gz ./*
)
