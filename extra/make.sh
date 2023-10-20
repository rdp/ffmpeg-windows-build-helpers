#!/usr/bin/env bash
# ffmpeg windows cross compile helper extra script, see github repo README
# Copyright (C) 2023 FREE WING,Y.Sakamoto, the script is under the GPLv3, but output FFmpeg's executables aren't
# set -x

WIN_VER=""
WIN_CMD_EXE=/mnt/c/Windows/System32/cmd.exe
if [ -e $WIN_CMD_EXE ]; then
  sudo sh -c "echo 1 > /proc/sys/fs/binfmt_misc/WSLInterop"

  $WIN_CMD_EXE /C "VER" | grep "Version 11"
  if [ $? = 0 ]; then
    WIN_VER="11"
  fi

  $WIN_CMD_EXE /C "VER" | grep "Version 10"
  if [ $? = 0 ]; then
    WIN_VER="10"
  fi
fi

if [ -z "$WIN_VER" ]; then
  echo "Can't detect Windows Version"
  exit 1
fi

echo "FFmpeg for Windows $WIN_VER"
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

if [ "$WIN_VER" = "10" ]; then
  echo "Windows 10 Ubuntu 20.04 Trouble patch"
  bash ./extra/wsl_win10_ubuntu_2004_patch.sh

  echo "Windows 10 Ubuntu 20.04 Trouble patch"
  bash ./extra/disable_git_sslverify.sh
fi

echo $'\a'
bash ./extra/build.sh
echo $'\a'

