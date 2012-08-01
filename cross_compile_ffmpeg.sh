#!/usr/bin/env bash
################################################################################
# ffmpeg windows cross compile helper/downloader script
################################################################################
# Copyright (C) 2012 Roger Pack
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along with
# this program.  If not, see <http://www.gnu.org/licenses/>.
#
# The GNU General Public License can be found in the LICENSE file.

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
  Downloads and builds will be installed to directories within $pwd
  If this is not ok, then exit now, and cd to the directory where you'd
  like them installed, then run this script again."

  yes_no_sel "Is ./sandbox_ffmpeg_build ok [y/n]?"
  if [[ "$user_input" = "n" ]]; then
    exit 1;
  fi
  mkdir -p "$pwd"
  cd "$pwd"
  yes_no_sel "Would you like to include non-free (non GPL compatible) libraries, like certain high quality aac encoders
The resultant binary will not be distributable, but might be useful for in-house use. Include non-free [y/n]?"
  non_free="$user_input" # save it away
  yes_no_sel "Would you like to compile with -march=native, which can get a few percent speedup
but also makes it so you cannot distribute the binary to machines of other architecture/cpu 
(also note that you should only enable this if compiling on a VM on the same box you intend to target, otherwise
it makes no sense)  Use march=native? [y/n]?" 
  if [[ "$user_input" = "y" ]]; then
    CFLAGS="$CFLAGS -march=native -pipe"
  else
    CFLAGS="$CFLAGS -pipe"
  fi
}

install_cross_compiler() {
  PATH="$PATH:$pwd/mingw-w64-i686/bin:$pwd/mingw-w64-x86_64/bin" # a few need/want it in the path... set it early before potentially returning early
  if [[ -f "mingw-w64-i686/compiler.done" || -f "mingw-w64-x86_64/compiler.done" ]]; then
   echo "MinGW-w64 compiler of some type already installed, not re-installing..."
   return
  fi
  read -p 'First we will download and compile a gcc cross-compiler (MinGW-w64).
  You will be prompted with a few questions as it installs (it takes quite awhile).
  Enter to continue:'

  wget http://zeranoe.com/scripts/mingw_w64_build/mingw-w64-build-3.0.6 -O mingw-w64-build-3.0.6
  chmod u+x mingw-w64-build-3.0.6
  ./mingw-w64-build-3.0.6 --mingw-w64-ver=2.0.4 --clean-build || exit 1
  if [ -d mingw-w64-x86_64 ]; then
    touch mingw-w64-x86_64/compiler.done
  fi
  if [ -d mingw-w64-i686 ]; then
    touch mingw-w64-i686/compiler.done
  fi
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
  touch_name=`echo -- $configure_options $CFLAGS | /usr/bin/env md5sum` # sanitize, disallow too long of length
  touch_name="already_configured_$touch_name" # add something so we can delete it easily
  if [ ! -f "$touch_name" ]; then
    echo "configuring $english_name as $configure_options"
    rm -f already_configured* # any old configuration options, since they'll be out of date after the next configure
    rm -f already_ran_make
    ./configure $configure_options || exit 1
    touch -- "$touch_name"
    make clean # just in case
  else
    echo "already configured $english_name" 
  fi
}

do_make_install() {
  if [ ! -f already_ran_make ]; then
    make || exit 1
    make install || exit 1
    touch already_ran_make
  fi
}

build_x264() {
  do_git_checkout "http://repo.or.cz/r/x264.git" "x264"
  cd x264
  do_configure "--host=$host_target --enable-static --cross-prefix=$cross_prefix --prefix=$mingw_w64_x86_64_prefix --enable-win32thread"
  rm already_ran_make # just in case the git checkout did something
  do_make_install
  cd ..
}

download_and_unpack_file() {
  url="$1"
  output_name="$2"
  output_dir="$3"
  if [ ! -f "$output_dir/unpacked.successfully" ]; then
    wget "$url" -O "$output_name" || exit 1
    tar -xzf "$output_name" || exit 1
    touch "$output_dir/unpacked.successfully"
    rm "$output_name"
  fi
}

generic_download_and_install() {
  local url="$1"
  local english_name="$2" 
  local url_filename="$2.tar.gz"
  local extra_configure_options="$3"
  download_and_unpack_file $url $url_filename $english_name
  cd $english_name
  do_configure "--host=$host_target --prefix=$mingw_w64_x86_64_prefix --disable-shared --enable-static $extra_configure_options"
  do_make_install
  cd ..
}

build_fdk_aac() {
  generic_download_and_install http://sourceforge.net/projects/opencore-amr/files/fdk-aac/fdk-aac-0.1.0.tar.gz/download fdk-aac-0.1.0
}

build_vo_aacenc() {
  generic_download_and_install http://sourceforge.net/projects/opencore-amr/files/vo-aacenc/vo-aacenc-0.1.2.tar.gz/download vo-aacenc-0.1.2
}

build_sdl() {
  generic_download_and_install http://www.libsdl.org/release/SDL-1.2.15.tar.gz SDL-1.2.15
  # apparently ffmpeg expects prefix-sdl-config not sdl-config...
  local prefix=`basename $cross_prefix`
  local bin_dir=`dirname $cross_prefix`
  mkdir temp
  cd temp # so paths will work out right
  echo "copying" "$bin_dir/sdl-config" "$bin_dir/$(echo $prefix)sdl-config"
  cp "$bin_dir/sdl-config" "$bin_dir/$prefixsdl-config"
  cd ..
  rmdir temp
}

build_faac() {
  generic_download_and_install http://downloads.sourceforge.net/faac/faac-1.28.tar.gz faac-1.28 "--with-mp4v2=no"
}

build_lame() {
  generic_download_and_install http://sourceforge.net/projects/lame/files/lame/3.99/lame-3.99.5.tar.gz/download lame-3.99.5
}

build_ffmpeg() {
  do_git_checkout https://github.com/FFmpeg/FFmpeg.git ffmpeg_git
  cd ffmpeg_git
  config_options="--enable-memalign-hack --arch=$ffmpeg_arch --enable-gpl --enable-libx264 --enable-avisynth --target-os=mingw32  --cross-prefix=$cross_prefix --pkg-config=pkg-config --enable-libmp3lame --enable-version3 --enable-libvo-aacenc"
  if [[ "$non_free" = "y" ]]; then
    config_options="$config_options --enable-nonfree --enable-libfdk-aac" # --enable-libfaac -- faac too poor quality and becomes the default -- add it in and uncomment the build_faac line to include it
  else
    config_options="$config_options"
  fi
  do_configure "$config_options"
  rm -f *.exe # just in case some library dependency was updated, force it to re-link
  make || exit 1
  local pwd=`pwd`
  echo "you will find binaries in $pwd/ff{mpeg,probe,play}*.exe"
  cd ..
}

intro # remember to always run the intro, since it adjust pwd
install_cross_compiler # always run this, too, since it adjust the PATH

build_all() {
  build_sdl
  build_x264
  build_lame
  build_vo_aacenc
  if [[ "$non_free" = "y" ]]; then
    build_fdk_aac
  #  build_faac # unused for now, see comment above
  fi
  build_ffmpeg
}

if [ -d "mingw-w64-i686" ]; then # they installed a 32-bit compiler
  mingw_w64_x86_64_prefix="$pwd/mingw-w64-i686"
  host_target='i686-w64-mingw32'
  cross_prefix='../../mingw-w64-i686/bin/i686-w64-mingw32-'
  ffmpeg_arch='x86'
  mkdir -p win32
  cd win32
  build_all
  cd ..
fi

if [ -d "mingw-w64-x86_64" ]; then # they installed a 64-bit compiler
  mingw_w64_x86_64_prefix="$pwd/mingw-w64-x86_64"
  host_target='x86_64-w64-mingw32'
  cross_prefix='../../mingw-w64-x86_64/bin/x86_64-w64-mingw32-'
  ffmpeg_arch='x86_64'
  mkdir -p x86_64
  cd x86_64
  build_all
  cd ..
fi

cd ..
echo 'done with ffmpeg cross compiler script'
