#!/bin/sh
# based on the script install-ffmpeg from svnpenn/a ... gotta give attribution where it's from :)
host=i686-w64-mingw32
prefix=$(pwd)/sandbox/win32/quick_install/install_root
# automake > autoreconf > autogen.sh
# diffutils > cmp > configure
# libtool > autoreconf > autogen.sh
# make > make
# mingw64-x86_64-gcc-g++ > x86_64-w64-mingw32-g++
# yasm > x264
# apt-cyg install automake diffutils libtool make mingw64-x86_64-gcc-g++ yasm
# apt-cyg install --nodeps git

mkdir -p sandbox/win32/quick_install
cd sandbox/win32/quick_install

# fdk-aac
git clone --depth 1 git://github.com/mstorsjo/fdk-aac
cd fdk-aac
./autogen.sh
./configure --host=$host --prefix=$prefix
make -j5 install
cd -

# x264
git clone --depth 1 git://git.videolan.org/x264
cd x264
# --enable-static       library is built by default but not installed
# --enable-win32thread  avoid installing pthread
./configure --enable-static --enable-win32thread --cross-prefix=$host- \
--prefix=$prefix
make -j5 install
cd -

# ffmpeg
git clone --depth 1 git://source.ffmpeg.org/ffmpeg
cd ffmpeg
./configure --enable-gpl --enable-libx264 --enable-nonfree \
--enable-libfdk-aac --arch=x86_64 --target-os=mingw32 \
--extra-ldflags=-static --cross-prefix=$host-
make -j5 install && echo "created ffmpeg.exe in $(pwd)!"