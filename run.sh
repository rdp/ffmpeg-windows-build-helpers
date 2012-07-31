#!/usr/bin/env bash

yes_no_sel () {
unset user_input
local question="$1"
shift
while [[ "$user_input" != [YyNn] ]]; do
  echo -n "$question"
  read user_input
  if [[ "$user_input" != [YyNn] ]]; then
    clear; echo 'Your selection was not vaild, please try again.'; echo
  fi
done
# downcase it
user_input=`echo $user_input | tr '[A-Z]' '[a-z]'`
}

pwd=`pwd`

intro () {
  echo "##################### Welcome ######################
  Welcome to the ffmpeg cross-compile builder-helper script.
  Downloads and builds will be installed to directories within $pwd.
  If this is not ok, then exit now, and cd to the directory where you'd
  like them installed, then run this script again."

  yes_no_sel "Is using $pwd as your scratch directory ok [y/n]?"
  if [[ "$user_input" = "n" ]]; then
    exit 1;
  fi
}

install_cross_compiler() {
  if [ -f "mingw-w64-i686/compiler.done" ]; then
   echo "compiler already installed..."
   return
  fi
  read -p 'First we will download and compile a gcc cross-compiler (MinGW-w64).
  You will be prompted with a few questions as it installs (it takes quite awhile).
  Enter to continue:'

  wget http://zeranoe.com/scripts/mingw_w64_build/mingw-w64-build-3.0.6 -O mingw-w64-build-3.0.6
  chmod u+x mingw-w64-build-3.0.6
  ./mingw-w64-build-3.0.6 || exit 1
  clear
  echo "Ok, done building MinGW-w64 cross-compiler..."
  touch mingw-w64-i686/compiler.done
}

build_x264() {
  


}



build_ffmpeg() {

if [ ! -d "ffmpeg_git" ]; then
  echo "Downloading FFmpeg..."
  git clone https://github.com/FFmpeg/FFmpeg.git ffmpeg_git.tmp || (echo "need git installed? try $ sudo apt-get install git" && exit 1)
  mv ffmpeg_git.tmp ffmpeg_git
  cd ffmpeg_git
else
  cd ffmpeg_git
  echo "Updating to latest FFmpeg version..."
  git pull
fi

# be able to not reconfigure if settings haven't changed
configure_options="--enable-memalign-hack --enable-avisynth --arch=x86   --target-os=mingw32    --cross-prefix=i686-w64-mingw32-  --pkg-config=pkg-config"

if [ ! -f "$configure_options" ]; then
  echo "configuring FFmpeg..."
  ./configure $configure_options 
  touch "$configure_options"
fi
echo "making FFmpeg"
make
cd ..
echo 'done -- you can find your binaries in ffmpeg_git/*.exe'
}

intro
install_cross_compiler
build_ffmpeg
