#!/usr/bin/env bash
# ffmpeg windows cross compile helper extra script, see github repo README
# Copyright (C) 2023 FREE WING,Y.Sakamoto, the script is under the GPLv3, but output FFmpeg's executables aren't
# set -x

echo "This is Patch for Windows 10 WSL Ubuntu 20.04"
echo "libsndfile fails to build on Ubuntu 20.04 with WSL #452"
echo "https://github.com/rdp/ffmpeg-windows-build-helpers/issues/452"

sudo dpkg -r --force-depends "libgc1c2" # remove old libgc

git clone https://github.com/ivmai/bdwgc --depth 1
cd bdwgc
./autogen.sh
./configure --prefix=/usr && make -j # its default is the wrong directory? huh?
sudo make install

