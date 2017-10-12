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

RUN git clone https://github.com/yangcha/ffmpeg-windows-build-helpers.git && \
        cd ffmpeg-windows-build-helpers && \
        ./cross_compile_ffmpeg.sh --compiler-flavors=win64

