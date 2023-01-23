#!/usr/bin/env bash
# ffmpeg windows cross compile helper extra script, see github repo README
# Copyright (C) 2023 FREE WING,Y.Sakamoto, the script is under the GPLv3, but output FFmpeg's executables aren't
# set -x

echo "This is Patch for Git clone from code.videolan.org"
# fatal: unable to access 'https://code.videolan.org/videolan/x264.git/': server certificate verification failed. CAfile: none CRLfile: none

echo "Disable Git server certificate verification"
git config --global http.sslverify false

