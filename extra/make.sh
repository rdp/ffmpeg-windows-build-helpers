#!/usr/bin/env bash
# ffmpeg windows cross compile helper extra script, see github repo README
# Copyright (C) 2023 FREE WING,Y.Sakamoto, the script is under the GPLv3, but output FFmpeg's executables aren't
# set -x

echo "FFmpeg for Windows 11"
echo "Make file for WSL Ubuntu"

# WSL Debian
# if [ -f /etc/debian_version ]; then
#   echo "Not Support Windows 10 WSL Debian"
#   echo "Please use Ubuntu"
#   exit 1
# fi

# Windows 10 WSL Debian 9.5
grep -E "^9" /etc/debian_version && echo "Not Support Windows 10 WSL Debian 9.x" && echo "Please use Ubuntu or Windows 11"

bash ./extra/wsl_patch.sh

echo $'\a'
bash ./extra/build.sh
echo $'\a'

