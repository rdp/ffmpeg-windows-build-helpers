FROM nvidia/cuda:8.0-devel-ubuntu16.04
LABEL maintainer "Changjiang Yang"

RUN apt-get update && apt-get install -y --no-install-recommends \
        subversion \
        curl \
        texinfo \
        g++ \
        bison \
        flex \
        cvs \
        yasm \
        automake \
        libtool \
        autoconf \
        gcc \
        cmake \
        git \
        make \
        pkg-config \
        zlib1g-dev \
        mercurial \
        unzip \
        pax \
        nasm \
        gperf \
        autogen \
        bzip2 \
        p7zip-full \
        wget \
        libnuma1 \
        libnuma-dev \
        ca-certificates \
        ed

ENV LIBRARY_PATH $LIBRARY_PATH/usr/local/cuda/lib64

RUN git clone https://github.com/yangcha/ffmpeg-windows-build-helpers.git && \
        cd ffmpeg-windows-build-helpers && \
        git checkout tags/n3.4 && \
        ./cross_compile_ffmpeg.sh --compiler-flavors=win64 --ffmpeg-git-checkout-version=n3.4

