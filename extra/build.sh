#!/usr/bin/env bash
# ffmpeg windows cross compile helper extra script, see github repo README
# Copyright (C) 2023 FREE WING,Y.Sakamoto, the script is under the GPLv3, but output FFmpeg's executables aren't
# set -x

FFMPEG_VER="n4.4.4"
if [ -n "$1" ]; then
  FFMPEG_VER="$1"
fi

echo "FFmpeg $FFMPEG_VER for Windows"

if [ ! "$FFMPEG_VER" = "master" ]; then

  if [ ! "${FFMPEG_VER:0:4}" = "n6.1" ]; then
    echo "Windows WSL patch require: n4.x, n5.x, n6.0"
    bash ./extra/wsl_patch_2023_05_for_n4_4_x.sh
  fi

  if [ "${FFMPEG_VER:0:3}" = "n5." ]; then
    if [ ! "${FFMPEG_VER:0:4}" = "n5.0" ]; then
      echo "Windows WSL patch require: n5.1, n5.2"
      bash ./extra/wsl_patch_2023_10_for_n5_x_x.sh
    fi
  fi

  echo "Windows WSL patch require: n4.x, n5.x, n6.x"
  bash ./extra/wsl_patch_2023_10_for_n4_4_x.sh
fi

echo "Default: --build-ffmpeg-static=y --build-intel-qsv=y --build-amd-amf=y"
echo "Add Args: --disable-nonfree=n --ffmpeg-git-checkout-version=$FFMPEG_VER"

# --compiler-flavors=multi,win32,win64
time ./cross_compile_ffmpeg.sh --disable-nonfree=n --compiler-flavors=win64 --ffmpeg-git-checkout-version=$FFMPEG_VER

