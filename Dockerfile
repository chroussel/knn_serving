FROM ubuntu:18.04

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update -y -q && \
    apt-get install -y -q --no-install-recommends \
    ca-certificates \
    ccache \
    g++ \
    gcc \
    git \
    ninja-build \
    pkg-config \
    tzdata \
    wget \
    cmake \
    openssl \
    libssl-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV CC=gcc \
    GXX=g++ \
    MAKE=make \
    CMAKE=cmake \
    OS=ubuntu \
    DIST_DIR=/build/dist

CMD [ "/knn/ci/build_script_cpp.sh" ]