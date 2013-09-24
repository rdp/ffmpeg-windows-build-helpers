#!/usr/bin/env bash
################################################################################
# ffmpeg windows cross compile helper/download script
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
user_input=$(echo $user_input | tr '[A-Z]' '[a-z]')
}

check_missing_packages () {
local check_packages=('curl' 'pkg-config' 'make' 'git' 'svn' 'cmake' 'gcc' 'autoconf' 'libtool' 'automake' 'yasm' 'cvs' 'flex' 'bison' 'makeinfo')
for package in "${check_packages[@]}"; do
  type -P "$package" >/dev/null || missing_packages=("$package" "${missing_packages[@]}")
done

if [[ -n "${missing_packages[@]}" ]]; then
  clear
  echo "Could not find the following execs: ${missing_packages[@]}"
  echo 'Install the missing packages before running this script.'
  exit 1
fi

local out=`cmake --version` # like cmake version 2.8.7
local version_have=`echo "$out" | cut -d " " -f 3`

function version { echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; }

if [[ $(version $version_have)  < $(version '2.8.10') ]]; then
  echo "your cmake version is too old $version_have wanted 2.8.10"
  exit 1
fi

if [[ ! -f /usr/include/zlib.h ]]; then
  echo "warning: you may need to install zlib development headers first [on ubuntu $ apt-get install zlib1g-dev]" # XXX do like configure does and attempt to compile and include zlib.h instead
  sleep 1
fi

out=`yasm --version`
yasm_version=`echo "$out" | cut -d " " -f 2` # like 1.1.0.112
if [[ $(version $yasm_version)  < $(version '1.2.0') ]]; then
  echo "your yasm version is too old $yasm_version wanted 1.2.0"
  exit 1
fi

}

cur_dir="$(pwd)/sandbox"
cpu_count="$(grep -c processor /proc/cpuinfo)" # linux
if [ -z "$cpu_count" ]; then
  cpu_count=`sysctl -n hw.ncpu | tr -d '\n'` # OS X
  if [ -z "$cpu_count" ]; then
    echo "warning, unable to determine cpu count, defaulting to 1"
    cpu_count=1 # boxes where we don't know how to determine cpu count [OS X for instance], default to just 1, instead of blank, which means infinite 
  fi
fi
original_cpu_count=$cpu_count # save it away for some that revert it temporarily

intro() {
  cat <<EOL
     ##################### Welcome ######################
  Welcome to the ffmpeg cross-compile builder-helper script.
  Downloads and builds will be installed to directories within $cur_dir
  If this is not ok, then exit now, and cd to the directory where you'd
  like them installed, then run this script again from there.  
  NB that once you build your compilers, you can no longer rename/move
  the sandbox directory, since it will have some hard coded paths in there.
  You can, of course, rebuild ffmpeg from within it, etc.
EOL
  if [[ $sandbox_ok != 'y' ]]; then
    yes_no_sel "Is ./sandbox ok (requires ~ 5GB space) [y/n]?"
    if [[ "$user_input" = "n" ]]; then
      exit 1
    fi
  fi
  mkdir -p "$cur_dir"
  cd "$cur_dir"
  if [[ $disable_nonfree = "y" ]]; then
    non_free="n"
  else
    if  [[ $disable_nonfree = "n" ]]; then
      non_free="y" 
    else
      yes_no_sel "Would you like to include non-free (non GPL compatible) libraries, like many aac encoders
The resultant binary will not be distributable, but might be useful for in-house use. Include non-free [y/n]?"
      non_free="$user_input" # save it away
    fi
  fi

  #yes_no_sel "Would you like to compile with -march=native, which can get a few percent speedup
#but also makes it so you cannot distribute the binary to machines of other architecture/cpu 
#(also note that you should only enable this if compiling on a VM on the same box you intend to target, otherwise
#it makes no sense)  Use march=native? THIS IS JUST EXPERIMENTAL AND DOES NOT WORK FULLY YET--choose n typically. [y/n]?" 
  #march_native="$user_input"
}

pick_compiler_flavors() {

while [[ "$build_choice" != [1-3] ]]; do
if [[ -n "${unknown_opts[@]}" ]]; then
  echo -n 'Unknown option(s)'
  for unknown_opt in "${unknown_opts[@]}"; do
    echo -n " '$unknown_opt'"
  done
  echo ', ignored.'; echo
fi
cat <<'EOF'
What version of MinGW-w64 would you like to build or update?
  1. Both Win32 and Win64
  2. Win32 (32-bit only)
  3. Win64 (64-bit only)
  4. Exit
EOF
echo -n 'Input your choice [1-5]: '
read build_choice
done
case "$build_choice" in
  1 ) build_choice=multi ;;
  2 ) build_choice=win32 ;;
  3 ) build_choice=win64 ;;
  4 ) exit 0 ;;
  * ) clear;  echo 'Your choice was not valid, please try again.'; echo ;;
esac
}

install_cross_compiler() {
  if [[ -f "mingw-w64-i686/compiler.done" || -f "mingw-w64-x86_64/compiler.done" ]]; then
   echo "MinGW-w64 compiler of some type or other already installed, not re-installing..."
   if [[ $rebuild_compilers != "y" ]]; then
     return # early exit, they already have some type of cross compiler built.
   fi
  fi

  if [[ -z $build_choice ]]; then
    pick_compiler_flavors
  fi
  curl https://raw.github.com/rdp/ffmpeg-windows-build-helpers/master/patches/mingw-w64-build-3.2.3.local -O  || exit 1
  chmod u+x mingw-w64-build-3.2.3.local
  unset CFLAGS
  # gcc 4.8.0 requires mingw-w64 > 2.0.8: http://gcc.gnu.org/bugzilla/show_bug.cgi?id=55706
  # so mingw-w64-ver=svn actually means 6172 for now [hard coded in it]
  nice ./mingw-w64-build-3.2.3.local --mingw-w64-ver=svn --clean-build --disable-shared --default-configure --cpu-count=$gcc_cpu_count --threads=pthreads-w32 --pthreads-w32-ver=2-9-1 --build-type=$build_choice || exit 1 # --disable-shared allows c++ to be distributed at all...which seemed necessary for some random dependency...
  export CFLAGS=$original_cflags # reset it
  if [ -d mingw-w64-x86_64 ]; then
    touch mingw-w64-x86_64/compiler.done
  fi
  if [ -d mingw-w64-i686 ]; then
    touch mingw-w64-i686/compiler.done
  fi
  clear
  echo "Ok, done building MinGW-w64 cross-compiler..."
}

setup_env() {
  export PKG_CONFIG_LIBDIR= # disable pkg-config from reverting back to and finding system installed packages [yikes]
}

do_svn_checkout() {
  repo_url="$1"
  to_dir="$2"
  desired_revision="$3"
  if [ ! -d $to_dir ]; then
    echo "svn checking out to $to_dir"
    if [[ -z "$desired_revision" ]]; then
      svn checkout $repo_url $to_dir.tmp || exit 1
    else
      svn checkout -r $desired_revision $repo_url $to_dir.tmp || exit 1
    fi
    mv $to_dir.tmp $to_dir
  else
    cd $to_dir
    echo "not svn Updating $to_dir since usually svn repo's aren't updated frequently enough..."
    # XXX accomodate for desired revision here if I ever uncomment the next line...
    # svn up
    cd ..
  fi
}

update_to_desired_branch_or_revision() {
  local to_dir="$1"
  local desired_branch="$2"
  if [ -n "$desired_branch" ]; then
   pushd $to_dir
   cd $to_dir
      echo "git checkout $desired_branch"
      git checkout "$desired_branch" || exit 1
      git merge "$desired_branch" || exit 1 # this would be if they want to checkout a revision number, not a branch...
   popd # in case it's a cd to ., don't want to cd to .. here...since sometimes we call it with a '.'
  fi
}

do_git_checkout() {
  local repo_url="$1"
  local to_dir="$2"
  local desired_branch="$3"
  if [ ! -d $to_dir ]; then
    echo "Downloading (via git clone) $to_dir"
    rm -rf $to_dir # just in case it was interrupted previously...
    # prevent partial checkouts by renaming it only after success
    git clone $repo_url $to_dir.tmp || exit 1
    mv $to_dir.tmp $to_dir
    echo "done downloading $to_dir"
    update_to_desired_branch_or_revision $to_dir $desired_branch
  else
    cd $to_dir
    echo "Updating to latest $to_dir version... $desired_branch"
    old_git_version=`git rev-parse HEAD`

    # if we're on a special branch, don't even bother doing a git pull, assume we're already there...
    if [[ -z $desired_branch ]]; then
      git pull # if you comment out, add a warning echo :)
    fi
    update_to_desired_branch_or_revision "." $desired_branch
    new_git_version=`git rev-parse HEAD`
    if [[ "$old_git_version" != "$new_git_version" ]]; then
     echo "got upstream changes, forcing re-configure."
     rm already*
    else
     echo "this pull got no new upstream changes, not forcing re-configure..."
    fi 
    cd ..
  fi
}

get_small_touchfile_name() { # have to call with assignment like a=$(get_small...)
  local beginning="$1"
  local extra_stuff="$2"
  local touch_name="${beginning}_$(echo -- $extra_stuff $CFLAGS | /usr/bin/env md5sum)" # make it smaller
  touch_name=$(echo $touch_name | sed "s/ //g") # md5sum introduces spaces, remove them
  echo $touch_name # bash cruddy return system LOL
} 

do_configure() {
  local configure_options="$1"
  local configure_name="$2"
  if [[ "$configure_name" = "" ]]; then
    configure_name="./configure"
  fi
  local cur_dir2=$(pwd)
  local english_name=$(basename $cur_dir2)
  local touch_name=$(get_small_touchfile_name already_configured "$configure_options $configure_name")
  if [ ! -f "$touch_name" ]; then
    make clean # just in case
    #make uninstall # does weird things when run under ffmpeg src
    if [ -f bootstrap.sh ]; then
      ./bootstrap.sh
    fi
    rm -f already_* # reset
    echo "configuring $english_name ($PWD) as $ PATH=$PATH $configure_name $configure_options"
    nice "$configure_name" $configure_options || exit 1
    touch -- "$touch_name"
    make clean # just in case
  else
    echo "already configured $(basename $cur_dir2)" 
  fi
}

do_make() {
  local extra_make_options="$1 -j $cpu_count"
  local cur_dir2=$(pwd)
  local touch_name=$(get_small_touchfile_name already_ran_make "$extra_make_options")

  if [ ! -f $touch_name ]; then
    echo
    echo "making $cur_dir2 as $ PATH=$PATH make $extra_make_options"
    echo
    nice make $extra_make_options || exit 1
    touch $touch_name
  else
    echo "already did make $(basename "$cur_dir2")"
  fi
}

do_make_install() {
  local extra_make_options="$1"
  do_make "$extra_make_options"
  local touch_name=$(get_small_touchfile_name already_ran_make_install "$extra_make_options")
  if [ ! -f $touch_name ]; then
    echo "make installing $cur_dir2 as $ PATH=$PATH make install $extra_make_options"
    nice make install $extra_make_options || exit 1
    touch $touch_name
  fi
}

build_x264() {
  do_git_checkout "http://repo.or.cz/r/x264.git" "x264" "origin/stable"
  cd x264
  # TODO remove the no-aggressive-loop ... should be unneeded now
  do_configure "--extra-cflags=-fno-aggressive-loop-optimizations --host=$host_target --enable-static --cross-prefix=$cross_prefix --prefix=$mingw_w64_x86_64_prefix --extra-cflags=-DPTW32_STATIC_LIB --enable-debug" # --enable-win32thread --enable-debug shouldn't hurt us since ffmpeg strips it anyway
# no-aggressive ref: https://ffmpeg.org/trac/ffmpeg/ticket/2310
  # TODO more march=native here?
  # rm -f already_ran_make # just in case the git checkout did something, re-make
  do_make_install
  cd ..
}


build_librtmp() {
  #  download_and_unpack_file http://rtmpdump.mplayerhq.hu/download/rtmpdump-2.3.tgz rtmpdump-2.3 # has some odd configure failure
  #  cd rtmpdump-2.3/librtmp

  do_git_checkout "http://repo.or.cz/r/rtmpdump.git" rtmpdump_git 883c33489403ed360a01d1a47ec76d476525b49e # trunk didn't build once...this one i sstable
  cd rtmpdump_git/librtmp
  do_make_install "CRYPTO=GNUTLS OPT=-O2 CROSS_COMPILE=$cross_prefix SHARED=no prefix=$mingw_w64_x86_64_prefix"
  #make install CRYPTO=GNUTLS OPT='-O2 -g' "CROSS_COMPILE=$cross_prefix" SHARED=no "prefix=$mingw_w64_x86_64_prefix" || exit 1
  sed -i 's/-lrtmp -lz/-lrtmp -lwinmm -lz/' "$PKG_CONFIG_PATH/librtmp.pc"
  cd ../..
}

build_qt() {
 # download_and_unpack_file http://download.qt-project.org/official_releases/qt/5.1/5.1.1/submodules/qtbase-opensource-src-5.1.1.tar.xz qtbase-opensource-src-5.1.1 # not officially supported seems...so didn't try it

 download_and_unpack_file http://download.qt-project.org/official_releases/qt/4.8/4.8.5/qt-everywhere-opensource-src-4.8.5.tar.gz qt-everywhere-opensource-src-4.8.5
  cd qt-everywhere-opensource-src-4.8.5
#  download_and_unpack_file http://download.qt-project.org/archive/qt/4.8/4.8.1/qt-everywhere-opensource-src-4.8.1.tar.gz qt-everywhere-opensource-src-4.8.1
#  cd qt-everywhere-opensource-src-4.8.1

    apply_patch https://raw.github.com/rdp/ffmpeg-windows-build-helpers/master/patches/imageformats.patch
    apply_patch https://raw.github.com/rdp/ffmpeg-windows-build-helpers/master/patches/qt-win64.patch
    # vlc's configure options...mostly
    do_configure "-static -release -fast -no-exceptions -no-stl -no-sql-sqlite -no-qt3support -no-gif -no-libmng -qt-libjpeg -no-libtiff -no-qdbus -no-openssl -no-webkit -sse -no-script -no-multimedia -no-phonon -opensource -no-scripttools -no-opengl -no-script -no-scripttools -no-declarative -no-declarative-debug -opensource -no-s60 -host-little-endian -confirm-license -xplatform win32-g++ -device-option CROSS_COMPILE=$cross_prefix -prefix $mingw_w64_x86_64_prefix -prefix-install -nomake examples"
    make sub-src
    make install sub-src # let it fail, baby, it still installs a lot of good stuff before dying on mng...? huh wuh?
    cp ./plugins/imageformats/libqjpeg.a $mingw_w64_x86_64_prefix/lib || exit 1 # I think vlc's install is just broken to need this [?]
    cp ./plugins/accessible/libqtaccessiblewidgets.a  $mingw_w64_x86_64_prefix/lib # this feels wrong...
    # do_make_install "sub-src" # sub-src might make the build faster? # complains on mng? huh?
    # vlc needs an adjust .pc file? huh wuh?
    sed -i 's/Libs: -L${libdir} -lQtGui/Libs: -L${libdir} -lcomctl32 -lqjpeg -lqtaccessiblewidgets -lQtGui/' "$PKG_CONFIG_PATH/QtGui.pc" # sniff
  cd ..
}

build_libsoxr() {
  download_and_unpack_file http://sourceforge.net/projects/soxr/files/soxr-0.1.0-Source.tar.xz soxr-0.1.0-Source # not /download since apparently some tar's can't untar it without an extension?
  cd soxr-0.1.0-Source
    cmake . -DENABLE_STATIC_RUNTIME=1 -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_RANLIB=${cross_prefix}ranlib -DCMAKE_C_COMPILER=${cross_prefix}gcc -DCMAKE_CXX_COMPILER=${cross_prefix}g++ -DCMAKE_RC_COMPILER=${cross_prefix}windres  -DCMAKE_INSTALL_PREFIX=$mingw_w64_x86_64_prefix -DHAVE_WORDS_BIGENDIAN_EXITCODE=0  -DBUILD_SHARED_LIBS:bool=off || exit 1
    # BUILD_TESTS:BOOL=ON instead of the below?
    rm -rf tests # disable tests. Is there another way?
    mkdir tests
    touch tests/CMakeLists.txt
    do_make_install
  cd ..
}

build_libxavs() {
  do_svn_checkout https://svn.code.sf.net/p/xavs/code/trunk xavs
  cd xavs
    export LDFLAGS='-lm'
    generic_configure "--cross-prefix=$cross_prefix" # see https://github.com/rdp/ffmpeg-windows-build-helpers/issues/3
    unset LDFLAGS
    do_make_install "CC=$(echo $cross_prefix)gcc AR=$(echo $cross_prefix)ar PREFIX=$mingw_w64_x86_64_prefix RANLIB=$(echo $cross_prefix)ranlib STRIP=$(echo $cross_prefix)strip"
  cd ..
}


build_libopenjpeg() {
  download_and_unpack_file http://openjpeg.googlecode.com/files/openjpeg_v1_4_sources_r697.tgz openjpeg_v1_4_sources_r697
  cd openjpeg_v1_4_sources_r697
  generic_configure
  sed -i "s/\/usr\/lib/\$\(libdir\)/" Makefile # install pkg_config to the right dir...
  cpu_count=1 # this one can't build multi-threaded <sigh> kludge
  do_make_install
  cpu_count=$original_cpu_count
  cd .. 

  #download_and_unpack_file http://openjpeg.googlecode.com/files/openjpeg-2.0.0.tar.gz openjpeg-2.0.0
  #cd openjpeg-2.0.0
  # cmake .  -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_RANLIB=${cross_prefix}ranlib -DCMAKE_C_COMPILER=${cross_prefix}gcc -DCMAKE_CXX_COMPILER=${cross_prefix}g++ -DCMAKE_RC_COMPILER=${cross_prefix}windres  -DCMAKE_INSTALL_PREFIX=$mingw_w64_x86_64_prefix -DBUILD_SHARED_LIBS:bool=off
  # do_make_install
  # cp $mingw_w64_x86_64_prefix/lib/libopenjp2.a $mingw_w64_x86_64_prefix/lib/libopenjpeg.a || exit 1
  # cp $mingw_w64_x86_64_prefix/include/openjpeg-2.0/* $mingw_w64_x86_64_prefix/include || exit 1
  #cd ..
}

build_libvpx() {
  do_git_checkout https://git.chromium.org/git/webm/libvpx.git "libvpx_git" 2d13e7b33e1ee
  cd libvpx_git
  export CROSS="$cross_prefix"
  if [[ "$bits_target" = "32" ]]; then
    do_configure "--extra-cflags=-DPTW32_STATIC_LIB --target=x86-win32-gcc --prefix=$mingw_w64_x86_64_prefix --enable-static --disable-shared"
  else
    do_configure "--extra-cflags=-DPTW32_STATIC_LIB --target=x86_64-win64-gcc --prefix=$mingw_w64_x86_64_prefix --enable-static --disable-shared "
  fi
  do_make_install
  unset CROSS
  cd ..
}

apply_patch() {
 local url=$1
 local patch_name=$(basename $url)
 local patch_done_name="$patch_name.done"
 if [[ ! -e $patch_done_name ]]; then
   curl $url -O || exit 1
   patch -p0 < "$patch_name" || exit 1
   touch $patch_done_name
 else
   echo "patch $patch_name already applied"
 fi
}

build_libutvideo() {
  download_and_unpack_file https://github.com/downloads/rdp/FFmpeg/utvideo-11.1.1-src.zip utvideo-11.1.1
  cd utvideo-11.1.1
    apply_patch https://raw.github.com/rdp/ffmpeg-windows-build-helpers/master/patches/utv.diff
    do_make_install "CROSS_PREFIX=$cross_prefix DESTDIR=$mingw_w64_x86_64_prefix prefix=" # prefix= to avoid it adding an extra /usr/local to it yikes
  cd ..
}

download_and_unpack_file() {
  url="$1"
  output_name=$(basename $url)
  output_dir="$2"
  if [ ! -f "$output_dir/unpacked.successfully" ]; then
    echo "downloading $url"
    curl "$url" -O -L || exit 1
    tar -xf "$output_name" || unzip $output_name || exit 1
    touch "$output_dir/unpacked.successfully" || exit 1
    rm "$output_name"
  fi
}

generic_configure() {
  local extra_configure_options="$1"
  do_configure "--host=$host_target --prefix=$mingw_w64_x86_64_prefix --disable-shared --enable-static $extra_configure_options"
}

# needs 2 parameters currently
generic_download_and_install() {
  local url="$1"
  local english_name="$2" 
  local extra_configure_options="$3"
  download_and_unpack_file $url $english_name
  cd $english_name || exit "needs 2 parameters"
  generic_configure_make_install $extra_configure_options
  cd ..
}

generic_configure_make_install() {
  generic_configure $1
  do_make_install
}

build_libilbc() {
  do_git_checkout https://github.com/dekkers/libilbc.git libilbc_git
  cd libilbc_git
  if [[ ! -f "configure" ]]; then
    autoreconf -fiv
  fi
  generic_configure_make_install
  cd ..
}

build_libflite() {
  download_and_unpack_file http://www.speech.cs.cmu.edu/flite/packed/flite-1.4/flite-1.4-release.tar.bz2 flite-1.4-release
  cd flite-1.4-release
   apply_patch https://raw.github.com/rdp/ffmpeg-windows-build-helpers/master/patches/flite_64.diff
   sed -i "s|i386-mingw32-|$cross_prefix|" configure*
   generic_configure
   do_make
   make install # it fails in error...
   if [[ "$bits_target" = "32" ]]; then
     cp ./build/i386-mingw32/lib/*.a $mingw_w64_x86_64_prefix/lib || exit 1
   else
     cp ./build/x86_64-mingw32/lib/*.a $mingw_w64_x86_64_prefix/lib || exit 1
   fi
  cd ..
}

build_libgsm() {
  download_and_unpack_file http://www.quut.com/gsm/gsm-1.0.13.tar.gz gsm-1.0-pl13
  cd gsm-1.0-pl13
  make CC=${cross_prefix}gcc AR=${cross_prefix}ar RANLIB=${cross_prefix}ranlib INSTALL_ROOT=${mingw_w64_x86_64_prefix} # fails, but in a way we expect (toast.c) LODO fix somehow?
  cp lib/libgsm.a $mingw_w64_x86_64_prefix/lib || exit 1
  mkdir -p $mingw_w64_x86_64_prefix/include/gsm
  cp inc/gsm.h $mingw_w64_x86_64_prefix/include/gsm || exit 1
  cd ..
}

build_libopus() {
  generic_download_and_install http://downloads.xiph.org/releases/opus/opus-1.0.1.tar.gz opus-1.0.1 
}

build_libdvdnav() {
  download_and_unpack_file http://dvdnav.mplayerhq.hu/releases/libdvdnav-4.2.0.tar.bz2 libdvdnav-4.2.0
  cd libdvdnav-4.2.0
  if [[ ! -f ./configure ]]; then
    ./autogen.sh
  fi
  generic_configure "--with-dvdread-config=$mingw_w64_x86_64_prefix/bin/dvdread-config"
  do_make_install 
  cd ..
}

build_libdvdcss() {
  generic_download_and_install http://download.videolan.org/pub/videolan/libdvdcss/1.2.13/libdvdcss-1.2.13.tar.bz2 libdvdcss-1.2.13
}

build_libdvdread() {
  download_and_unpack_file http://dvdnav.mplayerhq.hu/releases/libdvdread-4.2.0.tar.bz2 libdvdread-4.2.0
  cd libdvdread-4.2.0
  if [[ ! -f ./configure ]]; then
    ./autogen.sh
  fi

  generic_configure "CFLAGS=-DHAVE_DVDCSS_DVDCSS_H LDFLAGS=-ldvdcss" # vlc patch: "--enable-libdvdcss" # XXX ask how I'm *supposed* to do this to the dvdread peeps [svn?]
  apply_patch https://raw.github.com/rdp/ffmpeg-windows-build-helpers/master/patches/dvdread-win32.patch # XXX ???
  do_make_install 
  sed -i "s/-ldvdread.*/-ldvdread -ldvdcss/" $mingw_w64_x86_64_prefix/bin/dvdread-config
  sed -i 's/-ldvdread.*/-ldvdread -ldvdcss/' "$PKG_CONFIG_PATH/dvdread.pc"
  cd ..
}

build_glew() { # opengl stuff
  echo "still broken, wow this thing looks like junk LOL"
  exit
  download_and_unpack_file https://sourceforge.net/projects/glew/files/glew/1.10.0/glew-1.10.0.tgz/download glew-1.10.0 
  cd glew-1.10.0
    do_make_install "SYSTEM=linux-mingw32 GLEW_DEST=$mingw_w64_x86_64_prefix CC=${cross_prefix}gcc LD=${cross_prefix}ld CFLAGS=-DGLEW_STATIC" # could use $CFLAGS here [?] meh
    # now you should delete some "non static" files that it installed anyway? maybe? vlc does more here...
  cd ..
}

build_libopencore() {
  generic_download_and_install http://sourceforge.net/projects/opencore-amr/files/opencore-amr/opencore-amr-0.1.3.tar.gz/download opencore-amr-0.1.3
  generic_download_and_install http://sourceforge.net/projects/opencore-amr/files/vo-amrwbenc/vo-amrwbenc-0.1.2.tar.gz/download vo-amrwbenc-0.1.2
}

build_win32_pthreads() {
  download_and_unpack_file ftp://sourceware.org/pub/pthreads-win32/pthreads-w32-2-9-1-release.tar.gz   pthreads-w32-2-9-1-release
  cd pthreads-w32-2-9-1-release
    do_make "clean GC-static CROSS=$cross_prefix"
    cp libpthreadGC2.a $mingw_w64_x86_64_prefix/lib/libpthread.a || exit 1
    cp pthread.h sched.h semaphore.h $mingw_w64_x86_64_prefix/include || exit 1
  cd ..
}

build_libdl() {
  #download_and_unpack_file http://dlfcn-win32.googlecode.com/files/dlfcn-win32-r19.tar.bz2 dlfcn-win32-r19
  do_svn_checkout http://dlfcn-win32.googlecode.com/svn/trunk/ dlfcn-win32
  cd dlfcn-win32
    ./configure --disable-shared --enable-static --cross-prefix=$cross_prefix --prefix=$mingw_w64_x86_64_prefix
    do_make_install
  cd ..
}

build_libjpeg_turbo() {
  generic_download_and_install http://sourceforge.net/projects/libjpeg-turbo/files/1.3.0/libjpeg-turbo-1.3.0.tar.gz/download libjpeg-turbo-1.3.0
}

build_libogg() {
  generic_download_and_install http://downloads.xiph.org/releases/ogg/libogg-1.3.0.tar.gz libogg-1.3.0
}

build_libvorbis() {
  generic_download_and_install http://downloads.xiph.org/releases/vorbis/libvorbis-1.2.3.tar.gz libvorbis-1.2.3
}

build_libspeex() {
  generic_download_and_install http://downloads.xiph.org/releases/speex/speex-1.2rc1.tar.gz speex-1.2rc1
}  

build_libtheora() {
  cpu_count=1 # can't handle it
  generic_download_and_install http://downloads.xiph.org/releases/theora/libtheora-1.1.1.tar.bz2 libtheora-1.1.1
  cpu_count=$original_cpu_count
}

build_libfribidi() {
  # generic_download_and_install http://fribidi.org/download/fribidi-0.19.5.tar.bz2 fribidi-0.19.5 # got report of still failing?
  download_and_unpack_file http://fribidi.org/download/fribidi-0.19.4.tar.bz2 fribidi-0.19.4
  cd fribidi-0.19.4
    # make it export symbols right...
    apply_patch https://raw.github.com/rdp/ffmpeg-windows-build-helpers/master/patches/fribidi.diff
    generic_configure
    do_make_install
  cd ..

  #do_git_checkout http://anongit.freedesktop.org/git/fribidi/fribidi.git fribidi_git
  #cd fribidi_git
  #  ./bootstrap # couldn't figure out how to make this work...
  #  generic_configure
  #  do_make_install
  #cd ..
}

build_libass() {
  generic_download_and_install http://libass.googlecode.com/files/libass-0.10.1.tar.gz libass-0.10.1
  sed -i 's/-lass -lm/-lass -lfribidi -lm/' "$PKG_CONFIG_PATH/libass.pc"
}

build_gmp() {
  download_and_unpack_file ftp://ftp.gnu.org/gnu/gmp/gmp-5.0.5.tar.bz2 gmp-5.0.5
  cd gmp-5.0.5
    generic_configure "ABI=$bits_target"
    do_make_install
  cd .. 
}

build_orc() {
  generic_download_and_install  http://code.entropywave.com/download/orc/orc-0.4.16.tar.gz orc-0.4.16
}

build_libbluray() {
  generic_download_and_install ftp://ftp.videolan.org/pub/videolan/libbluray/0.2.3/libbluray-0.2.3.tar.bz2 libbluray-0.2.3
}

build_libschroedinger() {
  download_and_unpack_file http://diracvideo.org/download/schroedinger/schroedinger-1.0.11.tar.gz schroedinger-1.0.11
  cd schroedinger-1.0.11
    generic_configure
    sed -i 's/testsuite//' Makefile
    do_make_install
    sed -i 's/-lschroedinger-1.0$/-lschroedinger-1.0 -lorc-0.4/' "$PKG_CONFIG_PATH/schroedinger-1.0.pc" # yikes!
  cd ..
}

build_gnutls() {
  unset CFLAGS # auto-uses some wine stuff which can fail on foreign march...
  download_and_unpack_file ftp://ftp.gnutls.org/gcrypt/gnutls/v3.2/gnutls-3.2.3.tar.xz gnutls-3.2.3
  cd gnutls-3.2.3
    generic_configure "--disable-cxx --disable-doc" # don't need the c++ version, in an effort to cut down on size... LODO test difference...
    do_make_install
  cd ..
  sed -i 's/-lgnutls *$/-lgnutls -lnettle -lhogweed -lgmp -lcrypt32 -lws2_32 -liconv/' "$PKG_CONFIG_PATH/gnutls.pc"
  export CFLAGS=$original_cflags
}

build_libnettle() {
  generic_download_and_install http://www.lysator.liu.se/~nisse/archive/nettle-2.7.1.tar.gz nettle-2.7.1
}

build_bzlib2() {
  download_and_unpack_file http://www.bzip.org/1.0.6/bzip2-1.0.6.tar.gz bzip2-1.0.6
  cd bzip2-1.0.6
    apply_patch https://raw.github.com/rdp/ffmpeg-windows-build-helpers/master/patches/bzip2_cross_compile.diff
    do_make "CC=$(echo $cross_prefix)gcc AR=$(echo $cross_prefix)ar PREFIX=$mingw_w64_x86_64_prefix RANLIB=$(echo $cross_prefix)ranlib libbz2.a bzip2 bzip2recover install"
  cd ..
}

build_zlib() {
  download_and_unpack_file http://zlib.net/zlib-1.2.8.tar.gz zlib-1.2.8
  cd zlib-1.2.8
    do_configure "--static --prefix=$mingw_w64_x86_64_prefix"
    do_make_install "CC=$(echo $cross_prefix)gcc AR=$(echo $cross_prefix)ar RANLIB=$(echo $cross_prefix)ranlib"
  cd ..
}

build_libxvid() {
  download_and_unpack_file http://downloads.xvid.org/downloads/xvidcore-1.3.2.tar.gz xvidcore
  cd xvidcore/build/generic
  if [ "$bits_target" = "64" ]; then
    local config_opts="--build=x86_64-unknown-linux-gnu --disable-assembly" # kludgey work arounds for 64 bit
  fi
  do_configure "--host=$host_target --prefix=$mingw_w64_x86_64_prefix $config_opts" # no static option...
  sed -i "s/-mno-cygwin//" platform.inc # remove old compiler flag that now apparently breaks us
  do_make_install
  cd ../../..
  # force a static build after the fact
  if [[ -f "$mingw_w64_x86_64_prefix/lib/xvidcore.dll" ]]; then
    rm $mingw_w64_x86_64_prefix/lib/xvidcore.dll || exit 1
    mv $mingw_w64_x86_64_prefix/lib/xvidcore.a $mingw_w64_x86_64_prefix/lib/libxvidcore.a || exit 1
  fi
}

build_fontconfig() {
  unset CFLAGS= # wine...!
  download_and_unpack_file http://www.freedesktop.org/software/fontconfig/release/fontconfig-2.10.1.tar.gz fontconfig-2.10.1
  cd fontconfig-2.10.1
    generic_configure --disable-docs
    do_make_install
  cd .. 
  sed -i 's/-L${libdir} -lfontconfig[^l]*$/-L${libdir} -lfontconfig -lfreetype -lexpat/' "$PKG_CONFIG_PATH/fontconfig.pc"
  export CFLAGS=$original_cflags
}

build_libaacplus() {
  download_and_unpack_file http://217.20.164.161/~tipok/aacplus/libaacplus-2.0.2.tar.gz libaacplus-2.0.2
  cd libaacplus-2.0.2
    if [[ ! -f configure ]]; then
     ./autogen.sh --fail-early
    fi
    generic_configure_make_install 
  cd ..
}

build_openssl() {
  download_and_unpack_file http://www.openssl.org/source/openssl-1.0.1c.tar.gz openssl-1.0.1c
  cd openssl-1.0.1c
  export cross="$cross_prefix"
  export CC="${cross}gcc"
  export AR="${cross}ar"
  export RANLIB="${cross}ranlib"
  if [ "$bits_target" = "32" ]; then
    do_configure "--prefix=$mingw_w64_x86_64_prefix no-shared mingw" ./Configure
  else
    do_configure "--prefix=$mingw_w64_x86_64_prefix no-shared mingw64" ./Configure
  fi
  do_make_install
  unset cross
  unset CC
  unset AR
  unset RANLIB
  cd ..
}

build_fdk_aac() {
  #generic_download_and_install http://sourceforge.net/projects/opencore-amr/files/fdk-aac/fdk-aac-0.1.0.tar.gz/download fdk-aac-0.1.0
  do_git_checkout https://github.com/mstorsjo/fdk-aac.git fdk-aac_git
  cd fdk-aac_git
    if [[ ! -f "configure" ]]; then
      autoreconf -fiv
    fi
    generic_configure_make_install
  cd ..
}


build_libexpat() {
  generic_download_and_install http://sourceforge.net/projects/expat/files/expat/2.1.0/expat-2.1.0.tar.gz/download expat-2.1.0
}

build_iconv() {
  unset CFLAGS # tries to run some stuff like conftest.exe under wine which, if you've specified a foreign -march, causes a failure popup
  # and also is pretty terrifying that it's calling through to wine, so just punt here...I know it worked without CFLAGS so just stick with that for now...
  generic_download_and_install http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.14.tar.gz libiconv-1.14
  export CFLAGS=$original_cflags
}

build_freetype() {
  generic_download_and_install http://download.savannah.gnu.org/releases/freetype/freetype-2.4.10.tar.gz freetype-2.4.10
  sed -i 's/Libs: -L${libdir} -lfreetype.*/Libs: -L${libdir} -lfreetype -lexpat/' "$PKG_CONFIG_PATH/freetype2.pc"
}

build_vo_aacenc() {
  generic_download_and_install http://sourceforge.net/projects/opencore-amr/files/vo-aacenc/vo-aacenc-0.1.2.tar.gz/download vo-aacenc-0.1.2
}

build_sdl() {
  # apparently ffmpeg expects prefix-sdl-config not sdl-config that they give us, so rename...
  export CFLAGS=-DDECLSPEC=  # avoid SDL trac tickets 939 and 282
  generic_download_and_install http://www.libsdl.org/release/SDL-1.2.15.tar.gz SDL-1.2.15
  export CFLAGS=$original_cflags # reset it
  mkdir temp
  cd temp # so paths will work out right
  local prefix=$(basename $cross_prefix)
  local bin_dir=$(dirname $cross_prefix)
  sed -i "s/-mwindows//" "$mingw_w64_x86_64_prefix/bin/sdl-config" # allow ffmpeg to output anything
  sed -i "s/-mwindows//" "$PKG_CONFIG_PATH/sdl.pc"
  cp "$mingw_w64_x86_64_prefix/bin/sdl-config" "$bin_dir/${prefix}sdl-config" # this is the only one in the PATH so use it for now
  cd ..
  rmdir temp
}

build_faac() {
  generic_download_and_install http://downloads.sourceforge.net/faac/faac-1.28.tar.gz faac-1.28 "--with-mp4v2=no"
}

build_lame() {
  generic_download_and_install http://sourceforge.net/projects/lame/files/lame/3.99/lame-3.99.5.tar.gz/download lame-3.99.5
}

build_frei0r() {
  #download_and_unpack_file http://www.piksel.no/frei0r/releases/frei0r-plugins-1.3.tar.gz frei0r-1.3
  #cd frei0r-1.3
    #do_configure " --build=mingw32  --host=$host_target --prefix=$mingw_w64_x86_64_prefix --disable-static --enable-shared" # see http://ffmpeg.zeranoe.com/forum/viewtopic.php?f=5&t=312
    #do_make_install
    # we rely on external dll's for this one, so only need the header to enable it, for now
    #cp include/frei0r.h $mingw_w64_x86_64_prefix/include
  #cd ..
  if [[ ! -f "$mingw_w64_x86_64_prefix/include/frei0r.h" ]]; then
    curl https://raw.github.com/rdp/frei0r/master/include/frei0r.h > $mingw_w64_x86_64_prefix/include/frei0r.h || exit 1
  fi
}

build_vlc() {
  build_qt # needs libjpeg [?]
  cpu_count=1 # not wig out on .rc.lo files etc.
  #do_git_checkout https://github.com/videolan/vlc.git vlc # vlc git master seems to be unstable and break the build and not test for windows often, so specify a known working revision...
  do_git_checkout https://github.com/rdp/vlc.git vlc_rdp # till this thing stabilizes...
  cd vlc_rdp
  if [[ ! -f "configure" ]]; then
    ./bootstrap
  fi 
  do_configure "--disable-libgcrypt --disable-a52 --host=$host_target --disable-lua --disable-mad --enable-qt --disable-sdl" # don't have lua mingw yet, etc. [vlc has --disable-sdl [?]]
  do_make
  # do some gymnastics to avoid building the mozilla plugin for now [couldn't quite get it to work]
  #sed -i 's_git://git.videolan.org/npapi-vlc.git_https://github.com/rdp/npapi-vlc.git_' Makefile # this wasn't enough...
  sed -i "s/package-win-common: package-win-install build-npapi/package-win-common: package-win-install/" Makefile
  sed -i "s/.*cp .*builddir.*npapi-vlc.*//g" Makefile
  for file in ./*/vlc.exe; do
    rm $file # try to force a rebuild...
  done
  make package-win-common # not do_make, fails still at end, plus this way we get new vlc.exe's
  echo "created a file like ${PWD}/vlc-2.2.0-git/vlc.exe



"
  cpu_count=$original_cpu_count
  cd ..
}

build_mplayer() {
  download_and_unpack_file http://sourceforge.net/projects/mplayer-edl/files/mplayer-checkout-snapshot.tar.bz2/download mplayer-checkout-2013-09-11 # my own snapshot since mplayer seems to delete old file :\
  cd mplayer-checkout-2013-09-11
  do_git_checkout https://github.com/FFmpeg/FFmpeg ffmpeg bbcaf25d4 # random, known to work revision with 2013-09-11

  # XXX retry this with a slightly even more updated mplayer than one from 7/18
  #do_git_checkout https://github.com/pigoz/mplayer-svn.git mplayer-svn-git # lacks submodules for dvdnav unfortunately...
  #cd mplayer-svn-git
  #do_git_checkout https://github.com/FFmpeg/FFmpeg # TODO some specific revision here?

  do_configure "--enable-cross-compile --host-cc=cc --cc=${cross_prefix}gcc --windres=${cross_prefix}windres --ranlib=${cross_prefix}ranlib --ar=${cross_prefix}ar --as=${cross_prefix}as --nm=${cross_prefix}nm --enable-runtime-cpudetection --with-dvdnav-config=PATH $extra_config_options"
  rm already_ran_make* # try to force re-link just in case...this might not be enough tho
  rm *.exe
  do_make
  echo "built ${PWD}/{mplayer,mencoder}.exe"
  cd ..
}

build_mp4box() { # like build_gpac
  # This script only builds the gpac_static lib plus MP4Box. Other tools inside
  # specify revision until this works: https://sourceforge.net/p/gpac/discussion/287546/thread/72cf332a/
  do_svn_checkout https://svn.code.sf.net/p/gpac/code/trunk/gpac mp4box_gpac
  cd mp4box_gpac
  # are these tweaks needed? If so then complain to the mp4box people about it?
  sed -i "s/has_dvb4linux=\"yes\"/has_dvb4linux=\"no\"/g" configure
  sed -i "s/`uname -s`/MINGW32/g" configure
  # XXX do I want to disable more things here?
  generic_configure "--static-mp4box --enable-static-bin  --extra-libs=-lws2_32 -lwinmm"
  # I seem unable to pass 2 into the same config line so do it again...
  sed -i "s/EXTRALIBS=.*/EXTRALIBS=-lws2_32 -lwinmm/g" config.mak
  cd src
  rm already_
  do_make "CC=${cross_prefix}gcc AR=${cross_prefix}ar RANLIB=${cross_prefix}ranlib PREFIX= STRIP=${cross_prefix}strip"
  cd ..
  rm ./bin/gcc/MP4Box # try and force a relink
  cd applications/mp4box
  rm already_ran_make*
  do_make "CC=${cross_prefix}gcc AR=${cross_prefix}ar RANLIB=${cross_prefix}ranlib PREFIX= STRIP=${cross_prefix}strip"
  cd ../..
  # copy it every time just in case it was rebuilt...
  cp ./bin/gcc/MP4Box ./bin/gcc/MP4Box.exe # it doesn't name it .exe? That feels broken somehow...
  echo "built $(readlink -f ./bin/gcc/MP4Box.exe)"
  cd ..
}

build_ffmpeg() {
  echo "is $CFLAGS"
  local type=$1
  local shared=$2
  local git_url="https://github.com/FFmpeg/FFmpeg.git"
  local output_dir="ffmpeg_git"
  local extra_configure_opts="--enable-libsoxr --enable-fontconfig --enable-libass --enable-libutvideo --enable-libbluray "

  if [[ $type = "libav" ]]; then
    git_url="https://github.com/libav/libav.git"
    output_dir="libav_git"
    extra_configure_opts="" # has a few missing things?
  fi

  extra_configure_opts="$extra_configure_opts --extra-cflags=$CFLAGS" # not sure if this is needed or not?

  # can't mix and match --enable-static --enable-shared unfortunately, or the final executable seems to just use shared if the're both present
  if [[ $shared == "shared" ]]; then
    do_git_checkout $git_url ${output_dir}_shared
    extra_configure_opts="--enable-shared --disable-static $extra_configure_opts"
    cd ${output_dir}_shared
  else
    do_git_checkout $git_url $output_dir
    extra_configure_opts="--enable-static --disable-shared $extra_configure_opts"
    cd $output_dir
  fi
  if [ "$bits_target" = "32" ]; then
   local arch=x86
  else
   local arch=x86_64
  fi

config_options="--arch=$arch --target-os=mingw32 --cross-prefix=$cross_prefix --pkg-config=pkg-config --enable-gpl --enable-libx264 --enable-avisynth --enable-libxvid --enable-libmp3lame --enable-version3 --enable-zlib --enable-librtmp --enable-libvorbis --enable-libtheora --enable-libspeex --enable-libopenjpeg --enable-gnutls --enable-libgsm --enable-libfreetype --enable-libopus --disable-w32threads --enable-frei0r --enable-filter=frei0r --enable-libvo-aacenc --enable-bzlib --enable-libxavs --extra-cflags=-DPTW32_STATIC_LIB --enable-libopencore-amrnb --enable-libopencore-amrwb --enable-libvo-amrwbenc --enable-libschroedinger --enable-libvpx --enable-libilbc --prefix=$mingw_w64_x86_64_prefix $extra_configure_opts " # other possibilities: --enable-w32threads --enable-libflite
  if [[ "$non_free" = "y" ]]; then
    config_options="$config_options --enable-nonfree --enable-libfdk-aac" # --enable-libfaac -- faac deemed too poor quality and becomes the default -- add it in and uncomment the build_faac line to include it --enable-openssl --enable-libaacplus
  else
    config_options="$config_options"
  fi

  if [[ "$native_build" = "y" ]]; then
    config_options="$config_options --disable-runtime-cpudetect"
    # TODO --cpu=host ... ?
  else
    config_options="$config_options --enable-runtime-cpudetect"
  fi
  
  do_configure "$config_options"
  rm -f */*.a */*.dll *.exe # just in case some dependency library has changed, force it to re-link even if the ffmpeg source hasn't changed...
  rm already_ran_make*
  echo "doing ffmpeg make $(pwd)"
  do_make
  if [[ $shared != "shared" ]]; then
    do_make_install # install ffmpeg to get libavcodec libraries to be used as dependencies for other things, like vlc [XXX make this a config option?]
  fi
  echo "Done! You will find $bits_target bit $shared binaries in $(pwd)/{ffmpeg,ffprobe,ffplay,avconv,avprobe}*.exe"
  cd ..
}

build_dependencies() {
  echo "PKG_CONFIG_PATH=$PKG_CONFIG_PATH" # debug
  build_win32_pthreads # vpx etc. depend on this--provided by the compiler build script now, though
  build_libdl # ffmpeg's frei0r implentation needs this
  build_zlib # rtmp depends on it [as well as ffmpeg's optional but handy --enable-zlib]
  build_bzlib2 # in case someone wants it [ffmpeg uses it]
  build_gmp # for libnettle
  build_libnettle # needs gmp
  build_iconv # mplayer I think needs it for freetype [just it though], vlc also wants it.  looks like ffmpeg can use it too...?
  build_gnutls # needs libnettle, can use iconv it appears

  build_frei0r
  build_libutvideo
  #build_libflite # too big
  build_libgsm
  build_sdl # needed for ffplay to be created
  build_libopus
  build_libopencore
  build_libogg
  
  build_libspeex # needs libogg for exe's
  build_libvorbis # needs libogg
  build_libtheora # needs libvorbis, libogg
  build_orc
  build_libschroedinger # needs orc
  build_libbluray
  build_libjpeg_turbo # mplayer can use this, VLC qt might need it?
  build_libdvdcss
  build_libdvdread # vlc, possibly mplayer use it. needs dvdcss
  build_libdvdnav # vlc, possibly mplayer
  build_libxvid
  build_libxavs
  build_libsoxr
  build_x264
  build_lame
  build_libvpx
  build_vo_aacenc
  build_freetype
  build_libexpat
  build_libilbc
  build_fontconfig # needs expat, might need freetype, can use iconv, but I believe doesn't currently
  build_libfribidi
  build_libass # needs freetype, needs fribidi, needs fontconfig
  build_libopenjpeg
  if [[ "$non_free" = "y" ]]; then
    build_fdk_aac
    # build_faac # not included for now, too poor quality :)
    # build_libaacplus # if you use it, conflicts with other AAC encoders <sigh>, so disabled :)
  fi
  #build_openssl # hopefully don't need it anymore, since we have gnutls everywhere...
  build_librtmp # needs gnutls [or openssl...]
}

build_apps() {
  # now the things that use the dependencies...
  if [[ $build_mp4box = "y" ]]; then
    build_mp4box
  fi
  if [[ $build_mplayer = "y" ]]; then
    build_mplayer
  fi
  if [[ $build_ffmpeg_shared = "y" ]]; then
    build_ffmpeg ffmpeg shared
  fi
  if [[ $build_ffmpeg_static = "y" ]]; then
    build_ffmpeg ffmpeg
  fi
  if [[ $build_libav = "y" ]]; then
    build_ffmpeg libav
  fi
  if [[ $build_vlc = "y" ]]; then
    build_vlc # NB requires ffmpeg static as well, at least once...so put it last
  fi
}

# defaults :)
gcc_cpu_count=1 # allow them to specify more than 1, but default to the one that's most compatible...
build_ffmpeg_static=y
build_ffmpeg_shared=n
build_libav=n
build_mp4box=n
build_mplayer=n
build_vlc=n
unset CFLAGS # I think this does an export...we don't want any linux CFLAGS seeping through...they can set it via --cflags= 
original_cflags= # no export needed, this is just a local copy

while true; do
  case $1 in
    -h | --help ) echo "available options [with defaults]: 
      --build-ffmpeg-shared=n 
      --build-ffmpeg-static=y 
      --gcc-cpu-count=1 [number of cpu cores set it higher than 1 if you have multiple cores and > 1GB RAM, this speeds up cross compiler build. FFmpeg build uses number of cores regardless.] 
      --disable-nonfree=y (set to n to include nonfree like libfdk-aac) 
      --sandbox-ok=n [skip sandbox prompt if y] 
      --rebuild-compilers=y (prompts you which compilers to build, even if you already have some)
      --defaults|-d [skip all prompts, just use defaults] 
      --build-mp4box=n [builds MP4Box.exe from the gpac project] 
      --build-mplayer=n [builds mplayer.exe and mencoder.exe] 
      --build-vlc=n [builds a [rather bloated] vlc.exe] 
      --build-choice=[multi,win32,win64] [default prompt, or skip if you already have one built, multi is both win32 and win64]
      --build-libav=n [builds libav.exe, an FFmpeg fork] 
      --cflags= [default empty works for generic cpu, see README]"; exit 0 ;;
    --sandbox-ok=* ) sandbox_ok="${1#*=}"; shift ;;
    --gcc-cpu-count=* ) gcc_cpu_count="${1#*=}"; shift ;;
    --build-mp4box=* ) build_mp4box="${1#*=}"; shift ;;
    --build-mplayer=* ) build_mplayer="${1#*=}"; shift ;;
    --build-libav=* ) build_libav="${1#*=}"; shift ;;
    --cflags=* ) export CFLAGS="${1#*=}"; original_cflags="${1#*=}"; echo "setting cflags as $original_cflags"; shift ;;
    --build-vlc=* ) build_vlc="${1#*=}"; shift ;;
    --disable-nonfree=* ) disable_nonfree="${1#*=}"; shift ;;
    -d ) gcc_cpu_count=2; disable_nonfree="y"; sandbox_ok="y"; build_choice="multi"; shift ;;
    --defaults ) gcc_cpu_count=2; disable_nonfree="y"; sandbox_ok="y"; build_choice="multi"; shift ;;
    --build-choice=* ) build_choice="${1#*=}"; shift ;;
    --build-ffmpeg-static=* ) build_ffmpeg_static="${1#*=}"; shift ;;
    --build-ffmpeg-shared=* ) build_ffmpeg_shared="${1#*=}"; shift ;;
    --rebuild-compilers=* ) rebuild_compilers="${1#*=}"; shift ;;
    -- ) shift; break ;;
    -* ) echo "Error, unknown option: '$1'."; exit 1 ;;
    * ) break ;;
  esac
done

intro # remember to always run the intro, since it adjust pwd
check_missing_packages
install_cross_compiler # always run this, too, since it adjust the PATH
setup_env

original_path="$PATH"
if [ -d "mingw-w64-i686" ]; then # they installed a 32-bit compiler
  echo "Building 32-bit ffmpeg..."
  host_target='i686-w64-mingw32'
  mingw_w64_x86_64_prefix="$cur_dir/mingw-w64-i686/$host_target"
  export PATH="$cur_dir/mingw-w64-i686/bin:$original_path"
  export PKG_CONFIG_PATH="$cur_dir/mingw-w64-i686/i686-w64-mingw32/lib/pkgconfig"
  bits_target=32
  cross_prefix="$cur_dir/mingw-w64-i686/bin/i686-w64-mingw32-"
  mkdir -p win32
  cd win32
  build_dependencies
  build_apps
  cd ..
fi

if [ -d "mingw-w64-x86_64" ]; then # they installed a 64-bit compiler
  echo "Building 64-bit ffmpeg..."
  host_target='x86_64-w64-mingw32'
  mingw_w64_x86_64_prefix="$cur_dir/mingw-w64-x86_64/$host_target"
  export PATH="$cur_dir/mingw-w64-x86_64/bin:$original_path"
  export PKG_CONFIG_PATH="$cur_dir/mingw-w64-x86_64/x86_64-w64-mingw32/lib/pkgconfig"
  mkdir -p x86_64
  bits_target=64
  cross_prefix="$cur_dir/mingw-w64-x86_64/bin/x86_64-w64-mingw32-"
  cd x86_64
  build_dependencies
  build_apps
  cd ..
fi

# NB that we're currently in the sandbox dir

for file in `find . -name ffmpeg.exe` `find . -name MP4Box.exe` `find . -name mplayer.exe` `find . -name mencoder.exe` `find . -name avconv.exe` `find . -name avprobe.exe`; do
  echo "built $(readlink -f $file)"
done

# bash glob fails here again?
for file in `find . -name vlc.exe | grep -- -`; do
  echo "built $(readlink -f $file)"
done
