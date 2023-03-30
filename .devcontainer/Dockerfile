FROM mcr.microsoft.com/devcontainers/base:debian
# Install install packages necessary for ffmpeg crosscompile build
RUN apt-get update && apt-get install -y \
    subversion ragel curl texinfo g++ ed bison flex cvs yasm \
    automake libtool autoconf gcc cmake git make pkg-config \
    zlib1g-dev unzip pax nasm gperf autogen bzip2 autoconf-archive \
    p7zip-full meson clang libtool-bin ed \
    python3-distutils python3-pip python-is-python3 \
    xorg-dev libgl1-mesa-dev libglu1-mesa-dev \
    v4l-utils libv4l-dev \
    libxcb-shm0-dev libxcb-shape0-dev libxcb-xfixes0-dev
