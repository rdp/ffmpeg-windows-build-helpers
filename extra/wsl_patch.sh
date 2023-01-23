#!/usr/bin/env bash
# ffmpeg windows cross compile helper extra script, see github repo README
# Copyright (C) 2023 FREE WING,Y.Sakamoto, the script is under the GPLv3, but output FFmpeg's executables aren't
# set -x

echo "This is Patch for WSL Ubuntu"

echo "Disable Tesseract OCR function"
# ERROR: tesseract not found using pkg-config
# Disable Tesseract OCR function
sed -i -e "s/ build_libtesseract/ # build_libtesseract/g" cross_compile_ffmpeg.sh
sed -i -e "s/--enable-libtesseract//g" cross_compile_ffmpeg.sh

echo "Windows WSL 'binfmt'"
if [ -f /proc/sys/fs/binfmt_misc/WSLInterop ]; then
  echo "Windows WSL Disable 'binfmt'"
  sudo bash -c 'echo 0 > /proc/sys/fs/binfmt_misc/WSLInterop'
fi

echo "Update Package Index file"
sudo apt-get update -q

echo "Install missing Packages"

# Debian
sudo apt-get install wget -y -q

# Debian: lensfun ModureNotFoundError: No module named 'setuptools'
# Ubuntu: lensfun_git from setuptools import setup
sudo apt-get install python3-setuptools -y -q

echo "Install necessary Packages"
sudo apt-get install subversion ragel curl texinfo g++ ed bison flex cvs yasm automake libtool autoconf gcc cmake git make pkg-config zlib1g-dev unzip pax nasm gperf autogen bzip2 autoconf-archive p7zip-full meson clang -y -q
sudo apt-get install libtool-bin ed -y -q
sudo apt-get install python3-distutils -y -q
sudo apt-get install python-is-python3 -y -q

echo "Next Execute './extra/build.sh'"

