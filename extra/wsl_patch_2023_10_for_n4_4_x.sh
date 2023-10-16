#!/usr/bin/env bash
# ffmpeg windows cross compile helper extra script, see github repo README
# Copyright (C) 2023 FREE WING,Y.Sakamoto, the script is under the GPLv3, but output FFmpeg's executables aren't
# set -x

echo "This is Patch for WSL Ubuntu 2023/10/15"

echo "2023/10/15 Disable libaribcaption --enable-libaribcaption"
# Because FFmpeg 4.4.x doesn't have this option
# #693 --enable-libaribcaption #694
# https://github.com/rdp/ffmpeg-windows-build-helpers/pull/694
# config_options+=" --enable-libaribcaption" # libaribcatption (MIT licensed)
sed -i -e "s/--enable-libaribcaption//g" cross_compile_ffmpeg.sh
sed -i -e "s/  build_libaribcaption/  # build_libaribcaption/g" cross_compile_ffmpeg.sh

# echo "2023/10/15 Disable nvenc --enable-nvenc --enable-nvdec"
# Because 2023/10/06 latest master as 75f032b n12.1.14.1 Cause ERROR: nvenc requested but not found
#  and I have no NVIDIA graphics card
# config_options+=" --enable-nvenc --enable-nvdec" # don't work OS X
# sed -i -e "s/--enable-nvenc --enable-nvdec//g" cross_compile_ffmpeg.sh

echo "2023/10/15 nvenc nv-codec-headers n12.0.16.1"
# https://github.com/FFmpeg/nv-codec-headers/releases/tag/n12.0.16.1
# Because 2023/10/06 latest master as 75f032b n12.1.14.1 Cause ERROR: nvenc requested but not found
# https://github.com/FFmpeg/nv-codec-headers/commit/75f032b24263c2b684b9921755cafc1c08e41b9d
# Because 2023/10/06 n12.1.14.0 Cause error: 'NV_ENC_PARAMS_RC_VBR_MINQP' undeclared here
# https://github.com/FFmpeg/nv-codec-headers/releases/tag/n12.1.14.0
sed -i -e "s/nv-codec-headers\.git$/nv-codec-headers.git nv-codec-headers_git n12.0.16.1/g" cross_compile_ffmpeg.sh

