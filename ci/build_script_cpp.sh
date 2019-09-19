#!/usr/bin/env bash

set -e
set -x

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

(
    cd build
    $CMAKE $DIR/.. \
        ${CMAKE_ARGS}
    $MAKE -j 4
)
