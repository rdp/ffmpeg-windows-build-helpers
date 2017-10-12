FROM ubuntu:16.04
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
        ca-certificates \
        ed

RUN git clone https://github.com/rdp/ffmpeg-windows-build-helpers.git && \
        cd ffmpeg-windows-build-helpers && \
        ./cross_compile_ffmpeg.sh --compiler-flavors=win64

