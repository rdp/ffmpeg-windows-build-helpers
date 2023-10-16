#!/usr/bin/env bash
# ffmpeg windows cross compile helper extra script, see github repo README
# Copyright (C) 2023 FREE WING,Y.Sakamoto, the script is under the GPLv3, but output FFmpeg's executables aren't
# set -x

echo "Copy FFmpeg execute files to Windows C:\ffmpeg_tmp directory"

ls -l ./sandbox/win64/ffmpeg_git_with_fdk_aac_n4.4.4/ff*.exe
ls -l ./sandbox/win64/x264/x*.exe
ls -l ./sandbox/win64/x265/8bit/x*.exe

mkdir /mnt/c/ffmpeg_tmp/
cp ./sandbox/win64/ffmpeg_git_with_fdk_aac_n4.4.4/ff*.exe /mnt/c/ffmpeg_tmp/
cp ./sandbox/win64/x264/x*.exe /mnt/c/ffmpeg_tmp/
cp ./sandbox/win64/x265/8bit/x*.exe /mnt/c/ffmpeg_tmp/
rm /mnt/c/ffmpeg_tmp/ff*_g.exe

ls -l /mnt/c/ffmpeg_tmp/

