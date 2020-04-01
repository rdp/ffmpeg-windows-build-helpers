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
    echo ""
    echo "on ubuntu: sudo apt-get install gcc-mingw-w64-i686 g++-mingw-w64-i686 yasm make automake autoconf git pkg-config libtool-bin -y"
    echo 'Install the missing packages before running this script.'
    exit 1
  fi
}

check_missing_packages
set -x

host=i686-w64-mingw32
prefix=$(pwd)/sandbox_native/win32/quick_install/install_root
export PKG_CONFIG_PATH="$prefix/lib/pkgconfig" # let ffmpeg find our dependencies [currently not working :| ]

mkdir -p sandbox_native/win32/quick_install
cd sandbox_native/win32/quick_install

# x264
if [[ ! -f $prefix/lib/libx264.a ]]; then
  rm -rf x264
  git clone --depth 1 http://repo.or.cz/r/x264.git || exit 1
  cd x264
    # --enable-static       library is built by default but not installed
    # --enable-win32thread  avoid installing pthread
    ./configure --host=$host --enable-static --enable-win32thread --cross-prefix=$host- --prefix=$prefix
    make -j8
    make install
  cd ..
fi

# and ffmpeg
if [[ ! -d ffmpeg_simple ]]; then
  rm -rf ffmpeg.tmp.git
  git clone --depth 1 https://github.com/FFmpeg/FFmpeg.git ffmpeg.tmp.git
  mv ffmpeg.tmp.git ffmpeg_simple
fi

cd ffmpeg_simple
  # not ready for this since we don't reconfigure after changes: # git pull
  if [[ ! -f ffbuild/config.mak ]]; then
    ./configure --enable-gpl --enable-libx264 --enable-nonfree \
      --arch=x86 --target-os=mingw32 \
      --cross-prefix=$host- --pkg-config=pkg-config --prefix=$prefix/ffmpeg_static_fdk_aac
  fi
  rm **/*.a # attempt force a kind of rebuild...
  make -j8 && make install && echo "./sandbox_native/win32/quick_install/install_root/ffmpeg_static_fdk_aac/bin/ffmpeg.exe"
cd ..

