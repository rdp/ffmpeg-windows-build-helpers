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
pwd="$pwd/sandbox_ffmpeg_build"

intro() {
  echo "##################### Welcome ######################
  Welcome to the ffmpeg cross-compile builder-helper script.
  Downloads and builds will be installed to directories within $pwd.
  If this is not ok, then exit now, and cd to the directory where you'd
  like them installed, then run this script again."

  yes_no_sel "Is ./sandbox_ffmpeg_build ok [y/n]?"
  if [[ "$user_input" = "n" ]]; then
    exit 1;
  fi
  mkdir -p "$pwd"
  cd "$pwd"
}

install_cross_compiler() {
  if [ -f "mingw-w64-i686/compiler.done" ]; then
   echo "MinGW-w64 compiler already installed..."
   return
  fi
  read -p 'First we will download and compile a gcc cross-compiler (MinGW-w64).
  You will be prompted with a few questions as it installs (it takes quite awhile).
  Enter to continue:'

  wget http://zeranoe.com/scripts/mingw_w64_build/mingw-w64-build-3.0.6 -O mingw-w64-build-3.0.6
  chmod u+x mingw-w64-build-3.0.6
  ./mingw-w64-build-3.0.6 || exit 1
  touch mingw-w64-i686/compiler.done
  clear
  echo "Ok, done building MinGW-w64 cross-compiler..."
}

do_git_checkout() {
  repo_url="$1"
  to_dir="$2"
  shift
  if [ ! -d $to_dir ]; then
    echo "Downloading (via git clone) $to_dir"
    # prevent partial checkouts by renaming it only after success
    git clone $repo_url $to_dir.tmp || exit 1
    mv $to_dir.tmp $to_dir
    echo "done downloading $to_dir"
  else
    cd $to_dir
    echo "Updating to latest $to_dir version..."
    git pull
    cd ..
  fi
}


do_configure() {
  configure_options="$1"
  pwd2=`pwd`
  english_name=`basename $pwd2`
  touch_name=`echo -- $configure_options | tr '[/\-\. ]' '_'` # sanitize
  if [ ! -f "$touch_name" ]; then
    echo "configuring $english_name as $configure_options"
    ./configure $configure_options || exit 1
    touch -- "$touch_name"
  else
    echo "already configured $english_name" 
  fi
  echo "making $english_name"
  make || exit 1
}

build_x264() {
  do_git_checkout "http://repo.or.cz/r/x264.git" "x264"
  cd x264
  do_configure "--host=i686-w64-mingw32 --enable-static --cross-prefix=../mingw-w64-i686/bin/i686-w64-mingw32- --prefix=../mingw-w64-i686/i686-w64-mingw32 --enable-win32thread"
  make
  make install
  cd ..
}

build_lame() {
  if [ ! -f lame-3.99.5/unpacked.successfully ]; then
   wget http://sourceforge.net/projects/lame/files/lame/3.99/lame-3.99.5.tar.gz/download -O lame-3.99.5.tar.gz
   tar -xzf lame-3.99.5.tar.gz || exit 1
   touch lame-3.99.5/unpacked.successfully
  fi
  cd lame-3.99.5
  do_configure "--host=i686-w64-mingw32 --prefix=$pwd/mingw-w64-i686/i686-w64-mingw32 --enable-static --disable-shared"
  make
  make install 
  cd ..
}

build_ffmpeg() {
  do_git_checkout https://github.com/FFmpeg/FFmpeg.git ffmpeg_git
  cd ffmpeg_git
  do_configure "--enable-memalign-hack --enable-gpl --enable-libx264 --enable-avisynth --arch=x86 --target-os=mingw32  --cross-prefix=../mingw-w64-i686/bin/i686-w64-mingw32- --pkg-config=pkg-config --enable-libmp3lame"
  make
  cd ..
  echo 'you can find binaries in ffmpeg_git/ff*.exe, for instance ffmpeg_git/ffmpeg.exe'
}

intro # always run the intro, since it adjust paths
install_cross_compiler
build_x264
build_lame
build_ffmpeg
cd ..
echo 'done with ffmpeg cross compiler script'
