#!/bin/bash

set -e
set -x

eval "${MATRIX_EVAL}"
ulimit -c unlimited -S

if [[ "${TRAVIS_OS_NAME}" == "linux"]]; then
    ccache --show-stats
fi

