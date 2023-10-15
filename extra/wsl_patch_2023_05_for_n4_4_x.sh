#!/usr/bin/env bash
# ffmpeg windows cross compile helper extra script, see github repo README
# Copyright (C) 2023 FREE WING,Y.Sakamoto, the script is under the GPLv3, but output FFmpeg's executables aren't
# set -x

echo "This is Patch for WSL Ubuntu 2023/05/05"

echo "2023/05/05 no member named 'compressed_ten_bit_format'"
# libavcodec/libsvtav1.c:124:51: error: 'EbSvtAv1EncConfiguration' has no member named 'compressed_ten_bit_format'
# 124 |         (config->encoder_bit_depth > 8) && (config->compressed_ten_bit_format == 0) ? 1 : 0;
sed -i -e "s/SVT-AV1\.git$/SVT-AV1.git SVT-AV1_git v1.4.1/g" cross_compile_ffmpeg.sh

