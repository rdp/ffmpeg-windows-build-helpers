#!/usr/bin/env bash
# ffmpeg windows cross compile helper extra script, see github repo README
# Copyright (C) 2023 FREE WING,Y.Sakamoto, the script is under the GPLv3, but output FFmpeg's executables aren't
# set -x

echo "This is Patch for WSL Ubuntu 2023/10/20"

echo "2023/05/05 no member named 'vbv_bufsize'"
# https://github.com/FFmpeg/FFmpeg/commit/1c6fd7d756afe0f8b7df14dbf7a95df275f8f5ee
# avcodec/libsvtav1: replace vbv_bufsize with maximum_buffer_size_ms
# patch git cherry-pick 1c6fd7d
# https://bugs.launchpad.net/ubuntu/+source/ffmpeg/+bug/2024487
# ffmpeg 5.1.3u1 fails to compile with svt-av1 1.5.0
# libavcodec/libsvtav1.c: In function 'config_enc_params':
# libavcodec/libsvtav1.c:182:10: error: 'EbSvtAv1EncConfiguration' has no member named 'vbv_bufsize'
#   182 |     param->vbv_bufsize              = avctx->rc_buffer_size;
#       |          ^~
# libavcodec/libsvtav1.c:299:34: error: 'EbSvtAv1EncConfiguration' has no member named 'vbv_bufsize'
#   299 |     avctx->rc_buffer_size = param->vbv_bufsize;
#       |                                  ^~
# make: *** [ffbuild/common.mak:81: libavcodec/libsvtav1.o] Error 1
sed -i -e "s/  cd \$output_dir/  cd \$output_dir\n    git cherry-pick 1c6fd7d/g" cross_compile_ffmpeg.sh

