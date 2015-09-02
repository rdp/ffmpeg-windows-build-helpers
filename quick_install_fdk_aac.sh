#!/bin/bash
set -x
# based on the script install-ffmpeg from svnpenn/a/install-ffmpeg.sh (givin' credit where it's due :)
# uses an (assumed installed via package) cross compiler to compile ffmpeg with fdk-aac
# TODO try under linux...

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

host=i686-w64-mingw32
prefix=$(pwd)/sandbox/win32/quick_install/install_root
export PKG_CONFIG_PATH="$prefix/lib/pkgconfig" # let ffmpeg find our dependencies [currently not working :| ]

mkdir -p sandbox/win32/quick_install
cd sandbox/win32/quick_install

# fdk-aac
if [[ ! -f $prefix/lib/libfdk-aac.a ]]; then
  git clone --depth 1 git://github.com/mstorsjo/fdk-aac
  cd fdk-aac
    git pull
    ./autogen.sh
    ./configure --host=$host --prefix=$prefix --enable-static --disable-shared
    make -j5 install
  cd ..
fi

# x264
if [[ ! -f $prefix/lib/libx264.a ]]; then
  git clone --depth 1 http://repo.or.cz/r/x264.git
  cd x264
    git pull
    # --enable-static       library is built by default but not installed
    # --enable-win32thread  avoid installing pthread
    ./configure --host=$host --enable-static --enable-win32thread --cross-prefix=$host- --prefix=$prefix
    make -j5 install
  cd ..
fi

# and ffmpeg
git clone --depth 1 https://github.com/FFmpeg/FFmpeg.git ffmpeg
cd ffmpeg
  # not ready for this since we don't reconfigure: git pull
  # rm **/*.a # attempt force a rebuild...
  if [[ ! -f config.mak ]]; then
     echo $PKG_CONFIG_PATH "was pkg config path"
    ./configure --enable-gpl --enable-libx264 --enable-nonfree \
    --enable-libfdk-aac --arch=x86 --target-os=mingw32 \
    --cross-prefix=$host- --extra-ldflags=-L${prefix}/lib --extra-cflags=-I${prefix}/include
    # TODO should be able to use pkg-config not need these extra-xxx params :(
  fi
  make -j5 install && echo "created ffmpeg.exe in $(pwd)!"
  
cd ..
