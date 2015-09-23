#!/bin/bash
# based on the script install-ffmpeg from svnpenn/a/install-ffmpeg.sh (givin' credit where it's due :)
# uses an (assumed installed via package) cross compiler to compile ffmpeg with fdk-aac

check_missing_packages () {

  local check_packages=('pkg-config' 'make' 'git' 'autoconf' 'automake' 'yasm' 'i686-w64-mingw32-gcc' 'i686-w64-mingw32-g++' 'libtool')

  for package in "${check_packages[@]}"; do
    type -P "$package" >/dev/null || missing_packages=("$package" "${missing_packages[@]}")
  done

  if [[ -n "${missing_packages[@]}" ]]; then
    clear
    echo "Could not find the following execs: ${missing_packages[@]}"
    echo "on ubuntu: sudo apt-get install gcc-mingw-w64-i686 g++-mingw-w64-i686 yasm make automake autoconf git pkg-config libtool"
    echo 'Install the missing packages before running this script.'
    exit 1
  fi
}

check_missing_packages
set -x

host=i686-w64-mingw32
prefix=$(pwd)/sandbox/win32/quick_install/install_root
export PKG_CONFIG_PATH="$prefix/lib/pkgconfig" # let ffmpeg find our dependencies [currently not working :| ]

mkdir -p sandbox/win32/quick_install
cd sandbox/win32/quick_install

# fdk-aac
if [[ ! -f $prefix/lib/libfdk-aac.a ]]; then
  rm -rf fdk-aac
  git clone --depth 1 https://github.com/mstorsjo/fdk-aac.git || exit 1
  cd fdk-aac
    ./autogen.sh
    ./configure --host=$host --prefix=$prefix --enable-static --disable-shared
    make -j5 install
  cd ..
fi

# x264
if [[ ! -f $prefix/lib/libx264.a ]]; then
  rm -rf x264
  git clone --depth 1 http://repo.or.cz/r/x264.git || exit 1
  cd x264
    # --enable-static       library is built by default but not installed
    # --enable-win32thread  avoid installing pthread
    ./configure --host=$host --enable-static --enable-win32thread --cross-prefix=$host- --prefix=$prefix
    make -j5 install
  cd ..
fi

# and ffmpeg
if [[ ! -d ffmpeg_fdk_aac ]]; then
  rm -rf ffmpeg.tmp.git
  git clone --depth 1 https://github.com/FFmpeg/FFmpeg.git ffmpeg.tmp.git
  mv ffmpeg.tmp.git ffmpeg_fdk_aac
fi

cd ffmpeg_fdk_aac
  # not ready for this since we don't reconfigure after changes: # git pull
  if [[ ! -f config.mak ]]; then
    ./configure --enable-gpl --enable-libx264 --enable-nonfree \
      --enable-libfdk-aac --arch=x86 --target-os=mingw32 \
      --cross-prefix=$host- --pkg-config=pkg-config --prefix=$prefix/ffmpeg_static_fdk_aac
  fi
  rm **/*.a # attempt force a rebuild...
  make -j5 install && echo "created runnable ffmpeg.exe in $prefixs/ffmpeg_static/ffmpeg.exe!"
  
cd ..
