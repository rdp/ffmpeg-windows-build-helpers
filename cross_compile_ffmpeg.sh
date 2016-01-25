#!/usr/bin/env bash
# ffmpeg windows cross compile helper/download script, see github repo README
# Copyright (C) 2012 Roger Pack, the script is under the GPLv3, but output FFmpeg's executables aren't
# set -x # uncomment to enable script debug output

yes_no_sel () {
  unset user_input
  local question="$1"
  shift
  local default_answer="$1"
  while [[ "$user_input" != [YyNn] ]]; do
    echo -n "$question"
    read user_input
    if [[ -z "$user_input" ]]; then
      echo "using default $default_answer"
      user_input=$default_answer
    fi
    if [[ "$user_input" != [YyNn] ]]; then
      clear; echo 'Your selection was not vaild, please try again.'; echo
    fi
  done
  # downcase it
  user_input=$(echo $user_input | tr '[A-Z]' '[a-z]')
}

set_box_memory_size_bytes() {
  if [[ $OSTYPE == darwin* ]]; then 
    box_memory_size_bytes=20000000000 # 20G fake it out for now :|
  else
    local ram_kilobytes=`grep MemTotal /proc/meminfo | awk '{print $2}'` 
    local swap_kilobytes=`grep SwapTotal /proc/meminfo | awk '{print $2}'` 
    box_memory_size_bytes=$[ram_kilobytes * 1024 + swap_kilobytes * 1024]
  fi
}

check_missing_packages () {

  # zeranoe's build scripts use wget, though we don't here...
  local check_packages=('curl' 'pkg-config' 'make' 'git' 'svn' 'cmake' 'gcc' 'autoconf' 'automake' 'yasm' 'cvs' 'flex' 'bison' 'makeinfo' 'g++' 'ed' 'hg' 'pax' 'unzip' 'patch' 'wget' 'xz')
  # libtool check is wonky...
  if [[ $OSTYPE == darwin* ]]; then 
    check_packages+=(glibtoolize) # homebrew special :|
  else
    check_packages+=(libtoolize)
  fi

  for package in "${check_packages[@]}"; do
    type -P "$package" >/dev/null || missing_packages=("$package" "${missing_packages[@]}")
  done
  

  if [[ -n "${missing_packages[@]}" ]]; then
    clear
    echo "Could not find the following execs (svn is actually package subversion, makeinfo is actually package texinfo if you're missing them): ${missing_packages[@]}"
    echo 'Install the missing packages before running this script.'
    echo "for ubuntu: $ sudo apt-get install subversion curl texinfo g++ bison flex cvs yasm automake libtool autoconf gcc cmake git make pkg-config zlib1g-dev mercurial unzip pax -y" 
    echo "for gentoo (a non ubuntu distro): same as above, but no g++, no gcc, git is dev-vcs/git, zlib1g-dev is zlib, pkg-config is dev-util/pkgconfig, add ed..."
    echo "for OS X (homebrew): brew install wget cvs hg yasm automake autoconf cmake hg libtool xz"
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
    echo "warning: you may need to install zlib development headers first if you want to build mp4box [on ubuntu: $ apt-get install zlib1g-dev]" # XXX do like configure does and attempt to compile and include zlib.h instead?
    sleep 1
  fi

  out=`yasm --version`
  yasm_version=`echo "$out" | cut -d " " -f 2` # like 1.1.0.112
  if [[ $(version $yasm_version)  < $(version '1.2.0') ]]; then
    echo "your yasm version is too old $yasm_version wanted 1.2.0"
    exit 1
  fi

}


intro() {
  echo `date`
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
  if [[ $sandbox_ok != 'y' && ! -d sandbox ]]; then
    yes_no_sel "Is $PWD/sandbox ok (requires ~ 5GB space) [Y/n]?" "y"
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
      yes_no_sel "Would you like to include non-free (non GPL compatible) libraries, like many high quality aac encoders [libfdk_aac]
The resultant binary may not be distributable, but can be useful for in-house use. Include these non-free-license libraries [y/N]?" "n"
      non_free="$user_input" # save it away
    fi
  fi
}

pick_compiler_flavors() {
  while [[ "$compiler_flavors" != [1-4] ]]; do
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
    echo -n 'Input your choice [1-4]: '
    read compiler_flavors
  done
  case "$compiler_flavors" in
  1 ) compiler_flavors=multi ;;
  2 ) compiler_flavors=win32 ;;
  3 ) compiler_flavors=win64 ;;
  4 ) echo "exiting"; exit 0 ;;
  * ) clear;  echo 'Your choice was not valid, please try again.'; echo ;;
  esac
}

# made into a method so I don't/don't have to download this script every time if only doing 32 bit builds...
download_gcc_build_script() {
    local zeranoe_script_name=$1
    rm -f $zeranoe_script_name || exit 1
    curl -4 https://raw.githubusercontent.com/rdp/ffmpeg-windows-build-helpers/master/patches/$zeranoe_script_name -O  || exit 1
    chmod u+x $zeranoe_script_name
}

install_cross_compiler() {
  if [[ -f "cross_compilers/mingw-w64-i686/compiler.done" && -f "cross_compilers/mingw-w64-x86_64/compiler.done" ]]; then
   echo "MinGW-w64 compilers both already installed, not re-installing..."
   if [[ -z $compiler_flavors ]]; then
     compiler_flavors=multi
   fi
   return # early exit just assume they want both, don't even prompt :)
  fi

  if [[ -z $compiler_flavors ]]; then
    pick_compiler_flavors
  fi

  mkdir -p cross_compilers
  cd cross_compilers

    unset CFLAGS # don't want these for the compiler itself since it creates executables to run on the local box (we have a parameter allowing them to set them for the script "all builds" basically)
    # pthreads version to avoid having to use cvs for it
    echo "starting to download and build cross compile version of gcc [requires working internet access] with thread count $gcc_cpu_count..."
    echo ""

    # --disable-shared allows c++ to be distributed at all...which seemed necessary for some random dependency which happens to use/require c++...
    local zeranoe_script_name=mingw-w64-build-3.6.7.local
    # add --mingw-w64-ver=git for updated tuner.h [dshow dtv] past 4.0.4 TODO
    local zeranoe_script_options="--clean-build --disable-shared --default-configure  --pthreads-w32-ver=2-9-1 --cpu-count=$gcc_cpu_count --gcc-ver=5.3.0"
    if [[ ($compiler_flavors == "win32" || $compiler_flavors == "multi") && ! -f "mingw-w64-i686/compiler.done" ]]; then
      echo "building win32 cross compiler"
      download_gcc_build_script $zeranoe_script_name
      nice ./$zeranoe_script_name $zeranoe_script_options --build-type=win32 || exit 1 
      touch mingw-w64-i686/compiler.done # assume success
    fi
    if [[ ($compiler_flavors == "win64" || $compiler_flavors == "multi") && ! -f "mingw-w64-x86_64/compiler.done" ]]; then
      echo "building win64 x86_64 cross compiler"
      download_gcc_build_script $zeranoe_script_name
      nice ./$zeranoe_script_name $zeranoe_script_options --build-type=win64 || exit 1 
      touch mingw-w64-x86_64/compiler.done # assume success :)
    fi

    if [[ ! -f mingw-w64-i686/bin/i686-w64-mingw32-gcc && ! -f mingw-w64-x86_64/bin/x86_64-w64-mingw32-gcc ]]; then
      echo "no gcc cross compiler(s) seem to have been created [?] (build failure [?]) recommend nuke sandbox dir (rm -rf sandbox) and try again!"
      exit 1
    fi

    rm -f build.log
    export CFLAGS=$original_cflags # reset it back to what it was passed in as, via parameter :)
  cd ..
  echo "Done building (or already built) MinGW-w64 cross-compiler(s) successfully..."
  echo `date`

}

# helper methods for downloading and building projects that can take generic input

do_svn_checkout() {
  repo_url="$1"
  to_dir="$2"
  desired_revision="$3"
  if [ ! -d $to_dir ]; then
    echo "svn checking out to $to_dir"
    if [[ -z "$desired_revision" ]]; then
      svn checkout $repo_url $to_dir.tmp  --non-interactive --trust-server-cert || exit 1
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

update_to_desired_git_branch_or_revision() {
  local to_dir="$1"
  local desired_branch="$2" # or tag or whatever...
  if [ -n "$desired_branch" ]; then
   pushd $to_dir
      echo "git checkout'ing $desired_branch"
      git checkout "$desired_branch" || exit 1 # if this fails, nuke the directory first...
      git merge "$desired_branch" || exit 1 # this would be if they want to checkout a revision number, not a branch...
   popd # in case it's a cd to ., don't want to cd to .. here...since sometimes we call it with a '.'
  fi
}

do_git_checkout() {
  local repo_url="$1"
  local to_dir="$2"
  if [[ -z $to_dir ]]; then
    echo "got empty to dir for git checkout?"
    exit 1
  fi
  local desired_branch="$3"
  if [ ! -d $to_dir ]; then
    echo "Downloading (via git clone) $to_dir from $repo_url"
    rm -rf $to_dir.tmp # just in case it was interrupted previously...
    # prevent partial checkouts by renaming it only after success
    git clone $repo_url $to_dir.tmp || exit 1
    mv $to_dir.tmp $to_dir
    echo "done downloading $to_dir"
    update_to_desired_git_branch_or_revision $to_dir $desired_branch
  else
    cd $to_dir
    old_git_version=`git rev-parse HEAD`

    if [[ -z $desired_branch ]]; then
      if [[ $git_get_latest = "y" ]]; then
        echo "Updating to latest $to_dir git version [origin/master]..."
        git fetch
        git merge origin/master || exit 1
      else
        echo "not doing git get latest pull for latest code $to_dir"
      fi
    else
      if [[ $git_get_latest = "y" ]]; then
        echo "Doing git fetch $to_dir in case it affects the desired branch [$desired_branch]"
        git fetch
        git merge $desired_branch || exit 1
      else
        echo "not doing git fetch $to_dir to see if it affected desired branch [$desired_branch]"
      fi
    fi
    update_to_desired_git_branch_or_revision "." $desired_branch
    new_git_version=`git rev-parse HEAD`
    if [[ "$old_git_version" != "$new_git_version" ]]; then
     echo "got upstream changes, forcing re-configure."
     rm -f already*
    else
     echo "this pull got no new upstream changes, not forcing re-configure... (already at $new_git_version)"
    fi 
    cd ..
  fi
}

get_small_touchfile_name() { # have to call with assignment like a=$(get_small...)
  local beginning="$1"
  local extra_stuff="$2"
  local touch_name="${beginning}_$(echo -- $extra_stuff $CFLAGS | /usr/bin/env md5sum)" # make it smaller
  touch_name=$(echo "$touch_name" | sed "s/ //g") # md5sum introduces spaces, remove them
  echo "$touch_name" # bash cruddy return system LOL
} 

do_configure() {
  local configure_options="$1"
  local configure_name="$2"
  if [[ "$configure_name" = "" ]]; then
    configure_name="./configure"
  fi
  local cur_dir2=$(pwd)
  local english_name=$(basename $cur_dir2)
  local touch_name=$(get_small_touchfile_name already_configured "$configure_options $configure_name $LDFLAGS $CFLAGS")
  if [ ! -f "$touch_name" ]; then
    make clean # just in case useful...try and cleanup stuff...possibly not useful
    # make uninstall # does weird things when run under ffmpeg src so disabled
    if [ -f bootstrap ]; then
      ./bootstrap
    fi
    if [ -f bootstrap.sh ]; then
      ./bootstrap.sh
    fi
    if [[ ! -f $configure_name ]]; then
      autoreconf -fiv # a handful of them require this  to create ./configure :|
    fi
    rm -f already_* # reset
    echo "configuring $english_name ($PWD) as $ PATH=$path_addition:$original_path $configure_name $configure_options"
    nice "$configure_name" $configure_options || exit 1
    touch -- "$touch_name"
    make clean # just in case, but sometimes useful when files change, etc.
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
    echo "making $cur_dir2 as $ PATH=$path_addition:\$PATH make $extra_make_options"
    echo
    if [ ! -f configure ]; then
      make clean # just in case helpful if old junk left around and this is a 're make' and wasn't cleaned at reconfigure time
    fi
    nice make $extra_make_options || exit 1
    touch $touch_name || exit 1 # only touch if the build was OK
  else
    echo "already did make $(basename "$cur_dir2")"
  fi
}

do_make_and_make_install() {
  local extra_make_options="$1"
  do_make "$extra_make_options"
  do_make_install "$extra_make_options"
}

do_make_install() {
  local extra_make_install_options="$1"
  local override_make_install_options="$2" # startingly, some need/use something different than just 'make install'
  if [[ -z $override_make_install_options ]]; then
    local make_install_options="install $extra_make_options"
  else
    local make_install_options="$override_make_install_options"
  fi
  local touch_name=$(get_small_touchfile_name already_ran_make_install "$make_install_options")
  if [ ! -f $touch_name ]; then
    echo "make installing $(pwd) as $ PATH=$path_addition:\$PATH make $make_install_options"
    nice make $make_install_options || exit 1
    touch $touch_name || exit 1
  fi
}

do_cmake_and_install() {
  extra_args="$1" 
  local touch_name=$(get_small_touchfile_name already_ran_cmake "$extra_args")

  if [ ! -f $touch_name ]; then
    rm -f already_* # reset so that make will run again if option just changed
    local cur_dir2=$(pwd)
    echo doing cmake in $cur_dir2 with PATH=$path_addition:\$PATH with extra_args=$extra_args like this:
    echo cmake –G”Unix Makefiles” . -DENABLE_STATIC_RUNTIME=1 -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_RANLIB=${cross_prefix}ranlib -DCMAKE_C_COMPILER=${cross_prefix}gcc -DCMAKE_CXX_COMPILER=${cross_prefix}g++ -DCMAKE_RC_COMPILER=${cross_prefix}windres -DCMAKE_INSTALL_PREFIX=$mingw_w64_x86_64_prefix $extra_args
    cmake –G”Unix Makefiles” . -DENABLE_STATIC_RUNTIME=1 -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_RANLIB=${cross_prefix}ranlib -DCMAKE_C_COMPILER=${cross_prefix}gcc -DCMAKE_CXX_COMPILER=${cross_prefix}g++ -DCMAKE_RC_COMPILER=${cross_prefix}windres -DCMAKE_INSTALL_PREFIX=$mingw_w64_x86_64_prefix $extra_args || exit 1
    touch $touch_name || exit 1
  fi
  do_make_and_make_install
}

apply_patch() {
 local url=$1
 local patch_type=$2
 if [[ -z $patch_type ]]; then
   patch_type="-p0"
 fi
 local patch_name=$(basename $url)
 local patch_done_name="$patch_name.done"
 if [[ ! -e $patch_done_name ]]; then
   if [[ -f $patch_name ]]; then
     rm $patch_name || exit 1 # remove old version in case it has been since updated
   fi
   curl -4 $url -O || exit 1
   echo "applying patch $patch_name"
   patch $patch_type < "$patch_name" || exit 1
   touch $patch_done_name || exit 1
   rm -f already_ran* # if it's a new patch, reset everything too, in case it's really really really new
 else
   echo "patch $patch_name already applied"
 fi
}

# takes a url, output_dir as params, output_dir optional
download_and_unpack_file() {
  url="$1"
  output_name=$(basename $url)
  output_dir="$2"
  if [[ -z $output_dir ]]; then
    output_dir=$(basename $url | sed s/\.tar\.*//) # remove .tar.xx
  fi
  if [ ! -f "$output_dir/unpacked.successfully" ]; then
    echo "downloading $url"
    if [[ -f $output_name ]]; then
      rm $output_name || exit 1
    fi

    #  From man curl
    #  -4, --ipv4
    #  If curl is capable of resolving an address to multiple IP versions (which it is if it is  IPv6-capable),
    #  this option tells curl to resolve names to IPv4 addresses only.
    #  avoid a "network unreachable" error in certain [broken Ubuntu] configurations some user ran into once

    curl -4 "$url" -O -L || exit 1
    tar -xf "$output_name" || unzip "$output_name" || exit 1
    touch "$output_dir/unpacked.successfully" || exit 1
    rm "$output_name" || exit 1
  fi
}

generic_configure() {
  local extra_configure_options="$1"
  do_configure "--host=$host_target --prefix=$mingw_w64_x86_64_prefix --disable-shared --enable-static $extra_configure_options"
}

# params: url, optional "english name it will unpack to"
generic_download_and_install() {
  local url="$1"
  local english_name="$2" 
  if [[ -z $english_name ]]; then
    english_name=$(basename $url | sed s/\.tar\.*//) # remove .tar.xx
  fi
  local extra_configure_options="$3"
  download_and_unpack_file $url $english_name
  cd $english_name || exit "unable to cd, may need to specify dir it will unpack to as parameter"
  generic_configure "$extra_configure_options"
  do_make_and_make_install
  cd ..
}

generic_configure_make_install() {
  generic_configure # no parameters, force them to break it up :)
  do_make_and_make_install
}

build_libx265() {
  # the only one that uses mercurial, so there's some extra initial junk here...
  if [[ $prefer_stable = "n" ]]; then
    local old_hg_version
    if [[ -d x265 ]]; then
      cd x265
      if [[ $git_get_latest = "y" ]]; then
        echo "doing hg pull -u x265"
        old_hg_version=`hg --debug id -i`
        hg pull -u || exit 1
        hg update || exit 1 # guess you need this too if no new changes are brought down [what the...]
      else
        echo "not doing hg pull x265"
        old_hg_version=`hg --debug id -i`
      fi
    else
      echo "doing hg clone x265"
      hg clone https://bitbucket.org/multicoreware/x265 || exit 1
      cd x265
      old_hg_version=none-yet
    fi
    cd source

    # hg checkout 9b0c9b # no longer needed, but once was...

    local new_hg_version=`hg --debug id -i`  
    if [[ "$old_hg_version" != "$new_hg_version" ]]; then
      echo "got upstream hg changes, forcing rebuild...x265"
      rm -f already*
    else
      echo "still at hg $new_hg_version x265"
    fi
  else
    local old_hg_version
    if [[ -d x265 ]]; then
      cd x265
      if [[ $git_get_latest = "y" ]]; then
        echo "doing hg pull -u x265"
        old_hg_version=`hg --debug id -i`
        hg pull -u || exit 1
        hg update || exit 1 # guess you need this too if no new changes are brought down [what the...]
      else
        echo "not doing hg pull x265"
        old_hg_version=`hg --debug id -i`
      fi
    else
      hg clone https://bitbucket.org/multicoreware/x265 -r stable || exit 1
      cd x265
      old_hg_version=none-yet
    fi
    cd source

    # hg checkout 9b0c9b # no longer needed, but once was...

    local new_hg_version=`hg --debug id -i`  
    if [[ "$old_hg_version" != "$new_hg_version" ]]; then
      echo "got upstream hg changes, forcing rebuild...x265"
      rm -f already*
    else
      echo "still at hg $new_hg_version x265"
    fi
  fi
  
  local cmake_params="-DENABLE_SHARED=OFF"
  if [[ $high_bitdepth == "y" ]]; then
    cmake_params="$cmake_params -DHIGH_BIT_DEPTH=ON" # Enable 10 bits (main10) and 12 bits (???) per pixels profiles.
    if [ "$bits_target" = "32" ]; then
      cmake_params="$cmake_params -DENABLE_ASSEMBLY=OFF" # apparently required or build fails
    fi
  fi

  #if [ "$bits_target" = "32" ]; then
    cmake_params="$cmake_params -DWINXP_SUPPORT:BOOL=TRUE" # enable windows xp support apparently
  #fi

  do_cmake_and_install "$cmake_params" 
  cd ../..
}

build_libopenh264() {
  do_git_checkout "https://github.com/cisco/openh264.git" openh264 24916a652ee5d3 # need this to match ffmpeg's apparently or openh264v1.4 [this is last commit before 1.5 AFAICT]
  cd openh264
    if [ $bits_target = 32 ]; then
      local arch=i686 # or x86? 
    else
      local arch=x86_64
    fi
    do_make "$make_prefix_options OS=mingw_nt ARCH=$arch ASM=yasm"
    do_make_install "" "$make_prefix_options OS=mingw_nt install-static"
  cd ..
}

x264_profile_guided=n # or y -- haven't gotten this working yet...

build_libx264() {
  do_git_checkout "http://repo.or.cz/r/x264.git" "x264" "origin/stable"
  cd x264
  local configure_flags="--host=$host_target --enable-static --cross-prefix=$cross_prefix --prefix=$mingw_w64_x86_64_prefix --enable-strip --disable-lavf" # --enable-win32thread --enable-debug is another useful option here.
  
  if [[ $high_bitdepth == "y" ]]; then
    configure_flags="$configure_flags --bit-depth=10" # Enable 10 bits (main10) per pixels profile.
  fi
  
  if [[ $x264_profile_guided = y ]]; then
    # I wasn't able to figure out how/if this gave any speedup...
    # TODO more march=native here?
    # TODO profile guided here option, with wine?
    do_configure "$configure_flags"
    curl -4 http://samples.mplayerhq.hu/yuv4mpeg2/example.y4m.bz2 -O || exit 1
    rm -f example.y4m # in case it exists already...
    bunzip2 example.y4m.bz2 || exit 1
    # XXX does this kill git updates? maybe a more general fix, since vid.stab does also?
    sed -i.bak "s_\\, ./x264_, wine ./x264_" Makefile # in case they have wine auto-run disabled http://askubuntu.com/questions/344088/how-to-ensure-wine-does-not-auto-run-exe-files
    do_make_and_make_install "fprofiled VIDS=example.y4m" # guess it has its own make fprofiled, so we don't need to manually add -fprofile-generate here...
  else 
    do_configure "$configure_flags"
    do_make_and_make_install
  fi
  cd ..
}

build_librtmp() {
  #  download_and_unpack_file http://rtmpdump.mplayerhq.hu/download/rtmpdump-2.3.tgz # has some odd configure failure

  do_git_checkout "http://repo.or.cz/r/rtmpdump.git" rtmpdump_git 
  cd rtmpdump_git/librtmp
  do_make_and_make_install "CRYPTO=GNUTLS OPT=-O2 CROSS_COMPILE=$cross_prefix SHARED=no prefix=$mingw_w64_x86_64_prefix"
  #make install CRYPTO=GNUTLS OPT='-O2 -g' "CROSS_COMPILE=$cross_prefix" SHARED=no "prefix=$mingw_w64_x86_64_prefix" || exit 1
  sed -i.bak 's/-lrtmp -lz/-lrtmp -lwinmm -lz/' "$PKG_CONFIG_PATH/librtmp.pc"
  # also build .exe's for fun:
  cd ..
   if [[ ! -f rtmpsuck.exe ]]; then # hacky not do it twice
     # TODO do_make here instead...not easy since it doesn't seem to accept env. variable for LIB_GNUTLS...
     make SYS=mingw CRYPTO=GNUTLS OPT=-O2 CROSS_COMPILE=$cross_prefix SHARED=no LIB_GNUTLS="`pkg-config --libs gnutls` -lz" || exit 1 # NB not multi process here so we can ensure existence of rtmpsuck.exe means "we made it all the way to the end"
   fi
  cd ..

}

build_qt() {
  build_libjpeg_turbo # libjpeg a dependency [?]

  unset CFLAGS # it makes something of its own first, which runs locally, so can't use a foreign arch, or maybe it can, but not important enough: http://stackoverflow.com/a/18775859/32453
  # download_and_unpack_file http://download.qt-project.org/official_releases/qt/5.1/5.1.1/submodules/qtbase-opensource-src-5.1.1.tar.xz qtbase-opensource-src-5.1.1 # not officially supported seems...so didn't try it

  download_and_unpack_file http://pkgs.fedoraproject.org/repo/pkgs/qt/qt-everywhere-opensource-src-4.8.5.tar.gz/1864987bdbb2f58f8ae8b350dfdbe133/qt-everywhere-opensource-src-4.8.5.tar.gz 
  cd qt-everywhere-opensource-src-4.8.5
#  download_and_unpack_file http://download.qt-project.org/archive/qt/4.8/4.8.1/qt-everywhere-opensource-src-4.8.1.tar.gz
#  cd qt-everywhere-opensource-src-4.8.1

    apply_patch https://raw.githubusercontent.com/rdp/ffmpeg-windows-build-helpers/master/patches/imageformats.patch
    apply_patch https://raw.githubusercontent.com/rdp/ffmpeg-windows-build-helpers/master/patches/qt-win64.patch
    # vlc's configure options...mostly
    do_configure "-static -release -fast -no-exceptions -no-stl -no-sql-sqlite -no-qt3support -no-gif -no-libmng -qt-libjpeg -no-libtiff -no-qdbus -no-openssl -no-webkit -sse -no-script -no-multimedia -no-phonon -opensource -no-scripttools -no-opengl -no-script -no-scripttools -no-declarative -no-declarative-debug -opensource -no-s60 -host-little-endian -confirm-license -xplatform win32-g++ -device-option CROSS_COMPILE=$cross_prefix -prefix $mingw_w64_x86_64_prefix -prefix-install -nomake examples"
    if [ ! -f 'already_qt_maked_k' ]; then
      make sub-src -j $cpu_count
      make install sub-src # let it fail, baby, it still installs a lot of good stuff before dying on mng...? huh wuh?
      cp ./plugins/imageformats/libqjpeg.a $mingw_w64_x86_64_prefix/lib || exit 1 # I think vlc's install is just broken to need this [?]
      cp ./plugins/accessible/libqtaccessiblewidgets.a  $mingw_w64_x86_64_prefix/lib || exit 1 # this feels wrong...
      # do_make_and_make_install "sub-src" # sub-src might make the build faster? # complains on mng? huh?
      touch 'already_qt_maked_k'
    fi
    # vlc needs an adjust .pc file? huh wuh?
    sed -i.bak 's/Libs: -L${libdir} -lQtGui/Libs: -L${libdir} -lcomctl32 -lqjpeg -lqtaccessiblewidgets -lQtGui/' "$PKG_CONFIG_PATH/QtGui.pc" # sniff
  cd ..
  export CFLAGS=$original_cflags
}

build_libsoxr() {
  download_and_unpack_file http://sourceforge.net/projects/soxr/files/soxr-0.1.0-Source.tar.xz 
  cd soxr-0.1.0-Source
    do_cmake_and_install "-DHAVE_WORDS_BIGENDIAN_EXITCODE=0  -DBUILD_SHARED_LIBS:bool=off -DBUILD_TESTS:BOOL=OFF"
  cd ..
}

build_libxavs() {
  do_svn_checkout https://svn.code.sf.net/p/xavs/code/trunk xavs
  cd xavs
    export LDFLAGS='-lm'
    generic_configure "--cross-prefix=$cross_prefix" # see https://github.com/rdp/ffmpeg-windows-build-helpers/issues/3
    unset LDFLAGS
    do_make_and_make_install "$make_prefix_options"
    rm -f NUL # cygwin causes windows explorer to not be able to delete this folder if it has this oddly named file in it...
  cd ..
}

build_libsndfile() {
  generic_download_and_install http://www.mega-nerd.com/libsndfile/files/libsndfile-1.0.25.tar.gz
}

build_libbs2b() {
  export ac_cv_func_malloc_0_nonnull=yes # rp_alloc failure yikes
  generic_download_and_install http://downloads.sourceforge.net/project/bs2b/libbs2b/3.1.0/libbs2b-3.1.0.tar.lzma
  unset ac_cv_func_malloc_0_nonnull
}

build_libgme_game_music_emu() {
  download_and_unpack_file  https://bitbucket.org/mpyne/game-music-emu/downloads/game-music-emu-0.6.0.tar.bz2 
  cd game-music-emu-0.6.0
    sed -i.bak "s|SHARED|STATIC|" gme/CMakeLists.txt
    do_cmake_and_install
  cd ..
}

build_wavpack() {
  generic_download_and_install http://wavpack.com/wavpack-4.70.0.tar.bz2
}

build_libdcadec() {
  do_git_checkout https://github.com/foo86/dcadec.git dcadec_git
  cd dcadec_git
    do_make_and_make_install "$make_prefix_options"
  cd ..
}

build_libwebp() {
  generic_download_and_install http://downloads.webmproject.org/releases/webp/libwebp-0.5.0.tar.gz
}

build_libpng() {
  # generic_download_and_install http://download.sourceforge.net/libpng/libpng-1.6.12.tar.xz 
  generic_download_and_install http://download.sourceforge.net/libpng/libpng-1.5.18.tar.xz  # libtheora can't take 1.6.x :|
}

build_libopenjpeg() {
  # does openjpeg 2.0 work with ffmpeg? possibly not yet...
  download_and_unpack_file http://sourceforge.net/projects/openjpeg.mirror/files/1.5.2/openjpeg-1.5.2.tar.gz
  cd openjpeg-1.5.2
    export CFLAGS="$CFLAGS -DOPJ_STATIC" # see https://github.com/rdp/ffmpeg-windows-build-helpers/issues/37
    generic_configure_make_install
    export CFLAGS=$original_cflags # reset it
  cd ..
}

build_libvpx() {
  local config_options=""
  if [[ $prefer_stable = "y" ]]; then
    download_and_unpack_file http://storage.googleapis.com/downloads.webmproject.org/releases/webm/libvpx-1.4.0.tar.bz2
    cd libvpx-1.4.0
  else
    config_options="--enable-vp10 --enable-vp10-encoder --enable-vp10-decoder" #enable vp10 for experimental use
    do_git_checkout https://chromium.googlesource.com/webm/libvpx "libvpx_git"
    cd libvpx_git
  fi
  export CROSS="$cross_prefix"
  if [[ "$bits_target" = "32" ]]; then
    config_options="--target=x86-win32-gcc --prefix=$mingw_w64_x86_64_prefix --enable-static --disable-shared $config_options"
  else
    config_options="--target=x86_64-win64-gcc --prefix=$mingw_w64_x86_64_prefix --enable-static --disable-shared $config_options"
  fi
  do_configure "$config_options"
  do_make_and_make_install
  unset CROSS
  cd ..
}

build_libutvideo() {
  # if ending in .zip from sourceforge needs to not have /download on it? huh wuh?
  download_and_unpack_file http://sourceforge.net/projects/ffmpegwindowsbi/files/utvideo-12.2.1-src.zip utvideo-12.2.1 # local copy since the originating site http://umezawa.dyndns.info/archive/utvideo is sometimes inaccessible from draconian proxies
  #do_git_checkout https://github.com/qyot27/libutvideo.git libutvideo_git_qyot27 # todo this would be even newer version than 12.2.1?
  cd utvideo-12.2.1
    apply_patch https://raw.githubusercontent.com/rdp/ffmpeg-windows-build-helpers/master/patches/utv.diff
    sed -i.bak "s|Format.o|DummyCodec.o|" GNUmakefile
    do_make_and_make_install "CROSS_PREFIX=$cross_prefix DESTDIR=$mingw_w64_x86_64_prefix prefix=" # prefix= to avoid it adding an extra /usr/local to it yikes
  cd ..
}

build_libilbc() {
  do_git_checkout https://github.com/dekkers/libilbc.git libilbc_git
  cd libilbc_git
  if [[ ! -f "configure" ]]; then
    autoreconf -fiv || exit 1 # failure here, OS X means "you need libtoolize" perhaps? http://betterlogic.com/roger/2014/12/ilbc-cross-compile-os-x-mac-woe/
  fi
  generic_configure_make_install
  cd ..
}

build_libflite() {
  download_and_unpack_file http://www.speech.cs.cmu.edu/flite/packed/flite-1.4/flite-1.4-release.tar.bz2
  cd flite-1.4-release
   apply_patch https://raw.githubusercontent.com/rdp/ffmpeg-windows-build-helpers/master/patches/flite_64.diff
   sed -i.bak "s|i386-mingw32-|$cross_prefix|" configure*
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
  download_and_unpack_file http://www.quut.com/gsm/gsm-1.0.14.tar.gz gsm-1.0-pl14
  cd gsm-1.0-pl14
    # patch for openssl to work with it, I think?
    apply_patch https://raw.githubusercontent.com/rdp/ffmpeg-windows-build-helpers/master/patches/libgsm.patch
    if [[ ! -f $mingw_w64_x86_64_prefix/include/gsm/gsm.h ]]; then
      # not do_make here since this actually fails [wrongly]
      make $make_prefix_options INSTALL_ROOT=${mingw_w64_x86_64_prefix}
      cp lib/libgsm.a $mingw_w64_x86_64_prefix/lib || exit 1
      mkdir -p $mingw_w64_x86_64_prefix/include/gsm
      cp inc/gsm.h $mingw_w64_x86_64_prefix/include/gsm || exit 1
    else
      echo "already installed gsm"
    fi
  cd ..
}

build_libopus() {
  download_and_unpack_file http://downloads.xiph.org/releases/opus/opus-1.1.tar.gz 
  cd opus-1.1
    apply_patch https://raw.githubusercontent.com/rdp/ffmpeg-windows-build-helpers/master/patches/opus11.patch # allow it to work with shared builds
    generic_configure_make_install 
  cd ..
}

build_libdvdread() {
  build_libdvdcss
  download_and_unpack_file http://dvdnav.mplayerhq.hu/releases/libdvdread-4.9.9.tar.xz # last revision before 5.X series so still works with MPlayer
  cd libdvdread-4.9.9
  generic_configure "CFLAGS=-DHAVE_DVDCSS_DVDCSS_H LDFLAGS=-ldvdcss --enable-dlfcn" # vlc patch: "--enable-libdvdcss" # XXX ask how I'm *supposed* to do this to the dvdread peeps [svn?]
  #apply_patch https://raw.githubusercontent.com/rdp/ffmpeg-windows-build-helpers/master/patches/dvdread-win32.patch # has been reported to them...
  do_make_and_make_install 
  sed -i.bak 's/-ldvdread.*/-ldvdread -ldvdcss/' "$PKG_CONFIG_PATH/dvdread.pc"
  cd ..
}

build_libdvdnav() {
  download_and_unpack_file http://dvdnav.mplayerhq.hu/releases/libdvdnav-4.2.1.tar.xz # 4.2.1. latest revision before 5.x series [?]
  cd libdvdnav-4.2.1
  if [[ ! -f ./configure ]]; then
    ./autogen.sh
  fi
  generic_configure_make_install
  sed -i.bak 's/-ldvdnav.*/-ldvdnav -ldvdread -ldvdcss -lpsapi/' "$PKG_CONFIG_PATH/dvdnav.pc" # psapi for dlfcn ... [hrm?]
  cd ..
}

build_libdvdcss() {
  generic_download_and_install http://download.videolan.org/pub/videolan/libdvdcss/1.2.13/libdvdcss-1.2.13.tar.bz2
}

build_glew() { # opengl stuff, apparently [disabled...]
  echo "still broken, wow this one looks tough LOL"
  exit
  download_and_unpack_file https://sourceforge.net/projects/glew/files/glew/1.10.0/glew-1.10.0.tgz
  cd glew-1.10.0
    do_make_and_make_install "SYSTEM=linux-mingw32 GLEW_DEST=$mingw_w64_x86_64_prefix $make_prefix_options CFLAGS=-DGLEW_STATIC" # could use $CFLAGS here [?] meh
    # now you should delete some "non static" files that it installed anyway? maybe? vlc does more here...
  cd ..
}

build_libopencore() {
  generic_download_and_install http://sourceforge.net/projects/opencore-amr/files/opencore-amr/opencore-amr-0.1.3.tar.gz
  generic_download_and_install http://sourceforge.net/projects/opencore-amr/files/vo-amrwbenc/vo-amrwbenc-0.1.2.tar.gz
}

build_libdlfcn() {
  do_git_checkout https://github.com/dlfcn-win32/dlfcn-win32.git dlfcn-win32 
  cd dlfcn-win32
    do_configure "--disable-shared --enable-static --cross-prefix=$cross_prefix --prefix=$mingw_w64_x86_64_prefix" # rejects some normal cross compile options so custom here
    do_make_and_make_install
  cd ..
}

build_libjpeg_turbo() {
  download_and_unpack_file http://sourceforge.net/projects/libjpeg-turbo/files/1.4.2/libjpeg-turbo-1.4.2.tar.gz
  cd libjpeg-turbo-1.4.0
    #do_cmake_and_install "-DNASM=yasm" # couldn't figure out a static only build...
    generic_configure "NASM=yasm"
    do_make_and_make_install
    sed -i.bak 's/typedef long INT32/typedef long XXINT32/' "$mingw_w64_x86_64_prefix/include/jmorecfg.h" # breaks VLC build without this...freaky...theoretically using cmake instead would be enough, but that installs .dll.a file...
  cd ..
}

build_libogg() {
  generic_download_and_install http://downloads.xiph.org/releases/ogg/libogg-1.3.1.tar.gz
}

build_libvorbis() {
  generic_download_and_install http://downloads.xiph.org/releases/vorbis/libvorbis-1.3.4.tar.gz
}

build_libspeex() {
  generic_download_and_install http://downloads.xiph.org/releases/speex/speex-1.2rc1.tar.gz
}  

build_libtheora() {
  cpu_count=1 # can't handle it
  download_and_unpack_file http://downloads.xiph.org/releases/theora/libtheora-1.2.0alpha1.tar.gz 
  cd libtheora-1.2.0alpha1
    sed -i.bak 's/double rint/double rint_disabled/' examples/encoder_example.c # double define issue [?]
    generic_configure_make_install 
  cd ..
  cpu_count=$original_cpu_count
}

build_libfribidi() {
  # generic_download_and_install http://fribidi.org/download/fribidi-0.19.5.tar.bz2 fribidi-0.19.5 # got report of still failing?
  download_and_unpack_file http://fribidi.org/download/fribidi-0.19.4.tar.bz2
  cd fribidi-0.19.4
    # make it export symbols right...
    apply_patch https://raw.githubusercontent.com/rdp/ffmpeg-windows-build-helpers/master/patches/fribidi.diff
    generic_configure_make_install
  cd ..

  #do_git_checkout http://anongit.freedesktop.org/git/fribidi/fribidi.git fribidi_git
  #cd fribidi_git
  #  ./bootstrap # couldn't figure out how to make this work...
  #  generic_configure_make_install
  #cd ..
}

build_libass() {
  generic_download_and_install https://github.com/libass/libass/releases/download/0.13.1/libass-0.13.1.tar.gz 
  # fribidi, fontconfig, freetype throw them all in there for good measure, trying to help mplayer once though it didn't help [FFmpeg needed a change for fribidi here though I believe]
  sed -i.bak 's/-lass -lm/-lass -lfribidi -lfontconfig -lfreetype -lexpat -lm/' "$PKG_CONFIG_PATH/libass.pc"
}

build_gmp() {
  download_and_unpack_file https://gmplib.org/download/gmp/gmp-6.0.0a.tar.xz gmp-6.0.0
  cd gmp-6.0.0
    export CC_FOR_BUILD=/usr/bin/gcc
    export CPP_FOR_BUILD=usr/bin/cpp
    generic_configure "ABI=$bits_target"
    unset CC_FOR_BUILD
    unset CPP_FOR_BUILD
    do_make_and_make_install
  cd .. 
}

build_orc() {
  generic_download_and_install http://download.videolan.org/contrib/orc-0.4.18.tar.gz
}

build_libxml2() {
  generic_download_and_install http://xmlsoft.org/sources/libxml2-2.9.2.tar.gz libxml2-2.9.2 "--without-python"
}

build_libbluray() {
  # higher versions require java, which is a bit trickier...
  generic_download_and_install ftp://ftp.videolan.org/pub/videolan/libbluray/0.7.0/libbluray-0.7.0.tar.bz2
  sed -i.bak 's/-lbluray.*$/-lbluray -lfreetype -lexpat -lz -lbz2 -lxml2 -lws2_32 -liconv/' "$PKG_CONFIG_PATH/libbluray.pc" # not sure...is this a blu-ray bug, or VLC's problem in not pulling freetype's .pc file? or our problem with not using pkg-config --static ...
}

build_libschroedinger() {
  download_and_unpack_file http://download.videolan.org/contrib/schroedinger-1.0.11.tar.gz
  cd schroedinger-1.0.11
    generic_configure
    sed -i.bak 's/testsuite//' Makefile
    do_make_and_make_install
    sed -i.bak 's/-lschroedinger-1.0$/-lschroedinger-1.0 -lorc-0.4/' "$PKG_CONFIG_PATH/schroedinger-1.0.pc" # yikes!
  cd ..
}

build_gnutls() {
  download_and_unpack_file ftp://ftp.gnutls.org/gcrypt/gnutls/v3.4/gnutls-3.4.8.tar.xz
  cd gnutls-3.4.8
    sed -i.bak 's/mkstemp(tmpfile)/ -1 /g' src/danetool.c # fix x86_64 absent? but danetool is just an exe AFAICT so this hack should be ok...
    generic_configure "--disable-cxx --disable-doc --enable-local-libopts --disable-guile -with-included-libtasn1 --without-p11-kit" 
    # --disable-cxx don't need the c++ version, in an effort to cut down on size... XXXX test size difference... 
    # --enable-local-libopts to allow building with local autogen installed, 
    # --disable-guile is so that if it finds guile installed (cygwin did/does) it won't try and link/build to it and fail...
    # libtasn1 is some dependency, appears provided is an option [see also build_libnettle]
    # pks #11 hopefully we don't need kit
    do_make_and_make_install
  cd ..
  sed -i.bak 's/-lgnutls *$/-lgnutls -lnettle -lhogweed -lgmp -lcrypt32 -lws2_32 -liconv/' "$PKG_CONFIG_PATH/gnutls.pc"
}

build_libtasn() {
  generic_download_make_install http://ftp.gnu.org/gnu/libtasn1/libtasn1-4.7.tar.gz
}

build_libnettle() {
  build_libtasn # dependency
  download_and_unpack_file https://ftp.gnu.org/gnu/nettle/nettle-3.1.tar.gz
  cd nettle-3.1
    generic_configure "--disable-openssl --with-included-libtasn1" # in case we have both gnutls and openssl, just use gnutls [except that gnutls uses this so...huh? https://github.com/rdp/ffmpeg-windows-build-helpers/issues/25#issuecomment-28158515
    do_make_and_make_install
  cd ..
}

build_bzlib2() {
  download_and_unpack_file http://fossies.org/linux/misc/bzip2-1.0.6.tar.gz
  cd bzip2-1.0.6
    apply_patch https://raw.githubusercontent.com/rdp/ffmpeg-windows-build-helpers/master/patches/bzip2_cross_compile.diff
    do_make "$make_prefix_options libbz2.a bzip2 bzip2recover install"
  cd ..
}

build_zlib() {
  download_and_unpack_file http://sourceforge.net/projects/libpng/files/zlib/1.2.8/zlib-1.2.8.tar.gz
  cd zlib-1.2.8
    do_configure "--static --prefix=$mingw_w64_x86_64_prefix"
    do_make_and_make_install "$make_prefix_options ARFLAGS=rcs"
  cd ..
}

build_libxvid() {
  download_and_unpack_file http://downloads.xvid.org/downloads/xvidcore-1.3.3.tar.gz xvidcore
  cd xvidcore/build/generic
  do_configure "--host=$host_target --prefix=$mingw_w64_x86_64_prefix $config_opts" # no static option...
  sed -i.bak "s/-mno-cygwin//" platform.inc # remove old compiler flag that now apparently breaks us

  cpu_count=1 # possibly can't build this multi-thread ? http://betterlogic.com/roger/2014/02/xvid-build-woe/
  do_make_and_make_install
  cpu_count=$original_cpu_count
  cd ../../..

  # force a static build after the fact by only leaving the .a file, not the .dll.a file
  if [[ -f "$mingw_w64_x86_64_prefix/lib/xvidcore.dll.a" ]]; then
    rm $mingw_w64_x86_64_prefix/lib/xvidcore.dll.a || exit 1
    mv $mingw_w64_x86_64_prefix/lib/xvidcore.a $mingw_w64_x86_64_prefix/lib/libxvidcore.a || exit 1
  fi
}

build_fontconfig() {
  download_and_unpack_file http://www.freedesktop.org/software/fontconfig/release/fontconfig-2.11.94.tar.gz 
  cd fontconfig-2.11.94
    generic_configure --disable-docs
    do_make_and_make_install
  cd .. 
  sed -i.bak 's/-L${libdir} -lfontconfig[^l]*$/-L${libdir} -lfontconfig -lfreetype -lexpat/' "$PKG_CONFIG_PATH/fontconfig.pc"
}

build_libaacplus() {
  download_and_unpack_file http://217.20.164.161/~tipok/aacplus/libaacplus-2.0.2.tar.gz
  cd libaacplus-2.0.2
    if [[ ! -f configure ]]; then
     ./autogen.sh --fail-early
    fi
    generic_configure_make_install 
  cd ..
}

build_openssl() {
  # warning, this is a very old version of openssl since we don't really use it anymore hasn't been updated in awhile...
  download_and_unpack_file http://www.openssl.org/source/openssl-1.0.1q.tar.gz
  cd openssl-1.0.1q
  #export CC="${cross_prefix}gcc"
  #export AR="${cross_prefix}ar"
  #export RANLIB="${cross_prefix}ranlib"
  #XXXX do we need no-asm here?
  if [ "$bits_target" = "32" ]; then
    do_configure "--prefix=$mingw_w64_x86_64_prefix no-shared no-asm mingw" ./Configure
  else
    do_configure "--prefix=$mingw_w64_x86_64_prefix no-shared no-asm mingw64" ./Configure
  fi
  cpu_count=1
  do_make_and_make_install "$make_prefix_options"
  cpu_count=$original_cpu_count
  unset cross
  unset CC
  unset AR
  unset RANLIB
  cd ..
}

build_libnvenc() {
  if [[ ! -f $mingw_w64_x86_64_prefix/include/nvEncodeAPI.h ]]; then
    rm -rf nvenc # just in case :)
    mkdir nvenc
    cd nvenc
      echo "installing nvenc [nvidia gpu assisted encoder]"
      curl -4 http://developer.download.nvidia.com/assets/cuda/files/nvidia_video_sdk_6.0.1.zip -O -L || exit 1
      unzip nvidia_video_sdk_6.0.1.zip
      cp nvidia_video_sdk_6.0.1/Samples/common/inc/* $mingw_w64_x86_64_prefix/include
    cd ..
  else
    echo "already installed nvenc"
  fi
}

build_intel_quicksync_mfx() { # qsv
  do_git_checkout https://github.com/mjb2000/mfx_dispatch.git mfx_dispatch_git
  cd mfx_dispatch_git
    if [[ ! -f "configure" ]]; then
      autoreconf -fiv || exit 1
    fi
    generic_configure_make_install
  cd ..
}

build_fdk_aac() {
  #generic_download_and_install http://sourceforge.net/projects/opencore-amr/files/fdk-aac/fdk-aac-0.1.0.tar.gz
  do_git_checkout https://github.com/mstorsjo/fdk-aac.git fdk-aac_git
  cd fdk-aac_git
    if [[ ! -f "configure" ]]; then
      autoreconf -fiv || exit 1
    fi
    generic_configure_make_install
  cd ..
}

build_libexpat() {
  generic_download_and_install http://sourceforge.net/projects/expat/files/expat/2.1.0/expat-2.1.0.tar.gz
}

build_iconv() {
  download_and_unpack_file http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.14.tar.gz 
  cd libiconv-1.14
    export CFLAGS=-O2 
    generic_configure_make_install
    unset CFLAGS
  cd ..
}

build_freetype() {
  download_and_unpack_file http://download.savannah.gnu.org/releases/freetype/freetype-2.5.5.tar.gz
  cd freetype-2.5.5
    if [[ `uname -s` == CYGWIN* ]]; then
      generic_configure "--build=i686-pc-cygwin --with-png=no"  # hard to believe but needed...
    else
      generic_configure "--with-png=no"
    fi
    do_make_and_make_install
    sed -i.bak 's/Libs: -L${libdir} -lfreetype.*/Libs: -L${libdir} -lfreetype -lexpat -lz -lbz2/' "$PKG_CONFIG_PATH/freetype2.pc" # this should not need expat, but...I think maybe people use fontconfig's wrong and that needs expat? huh wuh? or dependencies are setup wrong in some .pc file?
    # possibly don't need the bz2 in there [bluray adds its own]...
  cd ..
}

build_vo_aacenc() {
  generic_download_and_install http://sourceforge.net/projects/opencore-amr/files/vo-aacenc/vo-aacenc-0.1.3.tar.gz
}

build_sdl() {
  # apparently ffmpeg expects prefix-sdl-config not sdl-config that they give us, so rename...
  export CFLAGS=-DDECLSPEC=  # avoid SDL trac tickets 939 and 282, not worried about optimizing yet
  generic_download_and_install http://www.libsdl.org/release/SDL-1.2.15.tar.gz
  export CFLAGS=$original_cflags # and reset it
  mkdir temp
  cd temp # so paths will work out right
  local prefix=$(basename $cross_prefix)
  local bin_dir=$(dirname $cross_prefix)
  sed -i.bak "s/-mwindows//" "$PKG_CONFIG_PATH/sdl.pc" # allow ffmpeg to output anything to console :|
  sed -i.bak "s/-mwindows//" "$mingw_w64_x86_64_prefix/bin/sdl-config" # update this one too for good measure, FFmpeg can use either, not sure which one it defaults to...
  cp "$mingw_w64_x86_64_prefix/bin/sdl-config" "$bin_dir/${prefix}sdl-config" # this is the only mingw dir in the PATH so use it for now [though FFmpeg doesn't use it?]
  cd ..
  rmdir temp
}

build_faac() {
  generic_download_and_install http://downloads.sourceforge.net/faac/faac-1.28.tar.gz faac-1.28 "--with-mp4v2=no"
}

build_lame() {
  download_and_unpack_file http://sourceforge.net/projects/lame/files/lame/3.99/lame-3.99.5.tar.gz
  cd lame-3.99.5
    apply_patch https://raw.githubusercontent.com/rdp/ffmpeg-windows-build-helpers/master/patches/lame3.patch
    generic_configure_make_install
  cd ..
}

build_zvbi() {
  download_and_unpack_file http://sourceforge.net/projects/zapping/files/zvbi/0.2.35/zvbi-0.2.35.tar.bz2
  cd zvbi-0.2.35
    apply_patch https://raw.githubusercontent.com/rdp/ffmpeg-windows-build-helpers/master/patches/zvbi-win32.patch
    apply_patch https://raw.githubusercontent.com/rdp/ffmpeg-windows-build-helpers/master/patches/zvbi-ioctl.patch
    export LIBS=-lpng
    generic_configure " --disable-dvb --disable-bktr --disable-nls --disable-proxy --without-doxygen" # thanks vlc contribs!
    unset LIBS
    cd src
      do_make_and_make_install 
    cd ..
#   there is no .pc for zvbi, so we add --extra-libs=-lpng to FFmpegs configure TODO there is a .pc file it just doesn't get installed [?]
#   sed -i.bak 's/-lzvbi *$/-lzvbi -lpng/' "$PKG_CONFIG_PATH/zvbi.pc"
  cd ..
}

build_libmodplug() {
  generic_download_and_install http://sourceforge.net/projects/modplug-xmms/files/libmodplug/0.8.8.5/libmodplug-0.8.8.5.tar.gz
  # unfortunately this sed isn't enough, though I think it should be [so we add --extra-libs=-lstdc++ to FFmpegs configure] http://trac.ffmpeg.org/ticket/1539
  sed -i.bak 's/-lmodplug.*/-lmodplug -lstdc++/' "$PKG_CONFIG_PATH/libmodplug.pc" # huh ?? c++?
  sed -i.bak 's/__declspec(dllexport)//' "$mingw_w64_x86_64_prefix/include/libmodplug/modplug.h" #strip DLL import/export directives
  sed -i.bak 's/__declspec(dllimport)//' "$mingw_w64_x86_64_prefix/include/libmodplug/modplug.h"
}

build_libcaca() {
  # beta19 and git were non xp friendly
  download_and_unpack_file http://pkgs.fedoraproject.org/repo/extras/libcaca/libcaca-0.99.beta18.tar.gz/93d35dbdb0527d4c94df3e9a02e865cc/libcaca-0.99.beta18.tar.gz 
  cd libcaca-0.99.beta18
    cd caca
      sed -i.bak "s/int vsnprintf/int vnsprintf_disabled/" *.c # doesn't compile with this in it double defined uh guess
      sed -i.bak "s/__declspec(dllexport)//g" *.h # get rid of the declspec lines otherwise the build will fail for undefined symbols
      sed -i.bak "s/__declspec(dllimport)//g" *.h 
    cd ..
    generic_configure "--libdir=$mingw_w64_x86_64_prefix/lib --disable-cxx --disable-csharp --disable-java --disable-python --disable-ruby --disable-imlib2 --disable-doc"
    do_make_and_make_install
  cd ..
}

build_libproxy() {
  # NB this lacks a .pc file still
  download_and_unpack_file https://libproxy.googlecode.com/files/libproxy-0.4.11.tar.gz
  cd libproxy-0.4.11
    sed -i.bak "s/= recv/= (void *) recv/" libmodman/test/main.cpp # some compile failure
    do_cmake_and_install
  cd ..
}

build_lua() {
  download_and_unpack_file http://www.lua.org/ftp/lua-5.1.tar.gz
  cd lua-5.1
    export AR="${cross_prefix}ar rcu" # needs a parameter :|
    do_make "$make_prefix_options generic" # generic == static :)
    unset AR
    do_make_and_make_install "INSTALL_TOP=$mingw_w64_x86_64_prefix"
    cp etc/lua.pc $PKG_CONFIG_PATH
  cd ..
}

build_libquvi() {
  download_and_Unpack_file http://sourceforge.net/projects/quvi/files/0.9/libquvi/libquvi-0.9.4.tar.xz/download libquvi-0.9.4
  cd libquvi-0.9.4
    generic_configure_make_install
  cd ..
}

build_twolame() {
  generic_download_and_install http://sourceforge.net/projects/twolame/files/twolame/0.3.13/twolame-0.3.13.tar.gz twolame-0.3.13 "CPPFLAGS=-DLIBTWOLAME_STATIC"
}

build_frei0r() {
  # theoretically we could get by with just copying a .h file in, but why not build them here anyway, just for fun? :)
  download_and_unpack_file https://files.dyne.org/frei0r/releases/frei0r-plugins-1.4.tar.gz
  cd frei0r-plugins-1.4
    do_cmake_and_install
  cd ..
}

build_vidstab() {
  do_git_checkout https://github.com/georgmartius/vid.stab.git vid.stab "430b4cffeb" # 0.9.8
  cd vid.stab
    sed -i.bak "s/SHARED/STATIC/g" CMakeLists.txt # static build-ify
    do_cmake_and_install
  cd ..
}

build_libcurl() {
  generic_download_and_install http://curl.haxx.se/download/curl-7.46.0.tar.gz
}

build_libdvbtee() {
  build_libcurl # it "can use this" so why not
  do_git_checkout https://github.com/mkrufky/libdvbtee.git libdvbtee origin/win # win compat branch
  cd libdvbtee
    # checkout its submodule
    if [ ! -e libdvbpsi/bootstrap ]; then
      rm -rf libdvbpsi # remove placeholder
      do_git_checkout https://github.com/mkrufky/libdvbpsi.git libdvbpsi
      cd libdvbpsi
        generic_configure_make_install # library dependency submodule...
      cd ..
    fi
    generic_configure_make_install 
  cd ..
}

build_vlc() {
  # currently broken, since it got too old for libavcodec and I didn't want to build its own custom one yet to match, and now it's broken with gcc 5.2.0 seemingly
  # call out dependencies here since it's a lot, plus hierarchical FTW!
  # should be ffmpeg 1.1.1 or some odd?

  echo "not doing vlc build, currently broken until enough interest to fix it"
  return

  #if [ ! -f $mingw_w64_x86_64_prefix/lib/libavutil.a ]; then # it takes awhile without this 
    build_ffmpeg ffmpeg 
  #fi
  build_libdvdread
  build_libdvdnav
  build_libx265
  build_qt

  do_git_checkout https://github.com/videolan/vlc.git vlc_git
  cd vlc_git
  # apply_patch https://raw.githubusercontent.com/rdp/ffmpeg-windows-build-helpers/master/patches/vlc_localtime_s.patch # git revision needs it...

  # outdated and patch doesn't apply cleanly anymore apparently...
  #if [[ "$non_free" = "y" ]]; then
  #  apply_patch https://raw.githubusercontent.com/gcsx/ffmpeg-windows-build-helpers/patch-5/patches/priorize_avcodec.patch
  #fi

  if [[ ! -f "configure" ]]; then
    ./bootstrap
  fi 
  export DVDREAD_LIBS='-ldvdread -ldvdcss -lpsapi'
  do_configure "--disable-libgcrypt --disable-a52 --host=$host_target --disable-lua --disable-mad --enable-qt --disable-sdl --disable-mod" # don't have lua mingw yet, etc. [vlc has --disable-sdl [?]] x265 disabled until we care enough... Looks like the bluray problem was related to the BLURAY_LIBS definition. [not sure what's wrong with libmod]
  rm -f `find . -name *.exe` # try to force a rebuild...though there are tons of .a files we aren't rebuilding as well FWIW...:|
  rm -f already_ran_make* # try to force re-link just in case...
  do_make
  # do some gymnastics to avoid building the mozilla plugin for now [couldn't quite get it to work]
  #sed -i.bak 's_git://git.videolan.org/npapi-vlc.git_https://github.com/rdp/npapi-vlc.git_' Makefile # this wasn't enough...
  sed -i.bak "s/package-win-common: package-win-install build-npapi/package-win-common: package-win-install/" Makefile
  sed -i.bak "s/.*cp .*builddir.*npapi-vlc.*//g" Makefile
  make package-win-common # not do_make, fails still at end, plus this way we get new vlc.exe's
  echo "


     created a file like ${PWD}/vlc-2.2.0-git/vlc.exe



"
  cd ..
  unset DVDREAD_LIBS
}

build_mplayer() {
  # pre requisites
  build_libdvdread
  build_libdvdnav
  download_and_unpack_file http://sourceforge.net/projects/mplayer-edl/files/mplayer-export-snapshot.2014-05-19.tar.bz2 mplayer-export-2014-05-19
  cd mplayer-export-2014-05-19
  do_git_checkout https://github.com/FFmpeg/FFmpeg ffmpeg d43c303038e9bd
  export LDFLAGS='-lpthread -ldvdnav -ldvdread -ldvdcss' # not compat with newer dvdread possibly? huh wuh?
  export CFLAGS=-DHAVE_DVDCSS_DVDCSS_H
  do_configure "--enable-cross-compile --host-cc=cc --cc=${cross_prefix}gcc --windres=${cross_prefix}windres --ranlib=${cross_prefix}ranlib --ar=${cross_prefix}ar --as=${cross_prefix}as --nm=${cross_prefix}nm --enable-runtime-cpudetection --extra-cflags=$CFLAGS --with-dvdnav-config=$mingw_w64_x86_64_prefix/bin/dvdnav-config --disable-dvdread-internal --disable-libdvdcss-internal --disable-w32threads --enable-pthreads --extra-libs=-lpthread --enable-debug --enable-ass-internal --enable-dvdread --enable-dvdnav" # haven't reported the ldvdcss thing, think it's to do with possibly it not using dvdread.pc [?] XXX check with trunk
  unset LDFLAGS
  export CFLAGS=$original_cflags
  sed -i.bak "s/HAVE_PTHREAD_CANCEL 0/HAVE_PTHREAD_CANCEL 1/g" config.h # mplayer doesn't set this up right?
  touch -t 201203101513 config.h # the above line change the modify time for config.h--forcing a full rebuild *every time* yikes!
  # try to force re-link just in case...
  rm -f *.exe
  rm -f already_ran_make* # try to force re-link just in case...
  do_make
  cp mplayer.exe mplayer_debug.exe
  ${cross_prefix}strip mplayer.exe
  echo "built ${PWD}/{mplayer,mencoder,mplayer_debug}.exe"
  cd ..
}

build_mp4box() { # like build_gpac
  # This script only builds the gpac_static lib plus MP4Box. Other tools inside
  # specify revision until this works: https://sourceforge.net/p/gpac/discussion/287546/thread/72cf332a/
  do_svn_checkout https://svn.code.sf.net/p/gpac/code/trunk/gpac mp4box_gpac
  cd mp4box_gpac
  # are these tweaks needed? If so then complain to the mp4box people about it?
  sed -i.bak "s/has_dvb4linux=\"yes\"/has_dvb4linux=\"no\"/g" configure
  sed -i.bak "s/`uname -s`/MINGW32/g" configure
  # XXX do I want to disable more things here?
  generic_configure "--static-mp4box --enable-static-bin"
  # I seem unable to pass 3 libs into the same config line so do it with sed...
  sed -i.bak "s/EXTRALIBS=.*/EXTRALIBS=-lws2_32 -lwinmm -lz/g" config.mak
  cd src
  do_make "$make_prefix_options"
  cd ..
  rm -f ./bin/gcc/MP4Box* # try and force a relink/rebuild of the .exe
  cd applications/mp4box
  rm -f already_ran_make* # ?? 
  do_make "$make_prefix_options"
  cd ../..
  # copy it every time just in case it was rebuilt...
  cp ./bin/gcc/MP4Box ./bin/gcc/MP4Box.exe # it doesn't name it .exe? That feels broken somehow...
  echo "built $(readlink -f ./bin/gcc/MP4Box.exe)"
  cd ..
}

build_libMXF() {
  download_and_unpack_file http://sourceforge.net/projects/ingex/files/1.0.0/libMXF/libMXF-src-1.0.0.tgz "libMXF-src-1.0.0"
  cd libMXF-src-1.0.0
  apply_patch https://raw.githubusercontent.com/rdp/ffmpeg-windows-build-helpers/master/patches/libMXF.diff
  do_make "MINGW_CC_PREFIX=$cross_prefix"
  #
  # Manual equivalent of make install.  Enable it if desired.  We shouldn't need it in theory since we never use libMXF.a file and can just hand pluck out the *.exe files...
  #
  # cp libMXF/lib/libMXF.a $mingw_w64_x86_64_prefix/lib/libMXF.a
  # cp libMXF++/libMXF++/libMXF++.a $mingw_w64_x86_64_prefix/lib/libMXF++.a
  # mv libMXF/examples/writeaviddv50/writeaviddv50 libMXF/examples/writeaviddv50/writeaviddv50.exe
  # mv libMXF/examples/writeavidmxf/writeavidmxf libMXF/examples/writeavidmxf/writeavidmxf.exe
  # cp libMXF/examples/writeaviddv50/writeaviddv50.exe $mingw_w64_x86_64_prefix/bin/writeaviddv50.exe
  # cp libMXF/examples/writeavidmxf/writeavidmxf.exe $mingw_w64_x86_64_prefix/bin/writeavidmxf.exe
  cd ..
}

build_libdecklink() {
   if [[ ! -f $mingw_w64_x86_64_prefix/include/DeckLinkAPIVersion.h ]]; then
     # smaller files don't worry about partials for now, plus we only care about the last file anyway here...
     curl -4 https://raw.githubusercontent.com/rdp/ffmpeg-windows-build-helpers/master/patches/DeckLinkAPI.h > $mingw_w64_x86_64_prefix/include/DeckLinkAPI.h  || exit 1
     curl -4 https://raw.githubusercontent.com/rdp/ffmpeg-windows-build-helpers/master/patches/DeckLinkAPI_i.c > $mingw_w64_x86_64_prefix/include/DeckLinkAPI_i.c.tmp  || exit 1
     mv $mingw_w64_x86_64_prefix/include/DeckLinkAPI_i.c.tmp $mingw_w64_x86_64_prefix/include/DeckLinkAPI_i.c
     curl -4 https://raw.githubusercontent.com/rdp/ffmpeg-windows-build-helpers/master/patches/DeckLinkAPIVersion.h > $mingw_w64_x86_64_prefix/include/DeckLinkAPIVersion.h  || exit 1
  fi
}

build_ffmpeg() {
  local type=$1
  local shared=$2
  local git_url="https://github.com/FFmpeg/FFmpeg.git"
  local output_dir="ffmpeg_git"

  if [[ "$non_free" = "y" ]]; then
    output_dir="${output_dir}_with_fdk_aac"
  fi

  local postpend_configure_opts=""

  # can't mix and match --enable-static --enable-shared unfortunately, or the final executable seems to just use shared if the're both present
  if [[ $shared == "shared" ]]; then
    output_dir=${output_dir}_shared
    final_install_dir=`pwd`/${output_dir}.installed
    postpend_configure_opts="--enable-shared --disable-static $postpend_configure_opts"
    # avoid installing this to system?
    postpend_configure_opts="$postpend_configure_opts --prefix=$final_install_dir --disable-libgme" # gme broken for shared as of yet TODO...
  else
    postpend_configure_opts="--enable-static --disable-shared $postpend_configure_opts --prefix=$mingw_w64_x86_64_prefix"
  fi

  do_git_checkout $git_url ${output_dir}
  cd $output_dir
  
  if [ "$bits_target" = "32" ]; then
   local arch=x86
  else
   local arch=x86_64
  fi

  init_options="--arch=$arch --target-os=mingw32 --cross-prefix=$cross_prefix --pkg-config=pkg-config --disable-w32threads"
  config_options="$init_options --enable-gpl --enable-libsoxr --enable-fontconfig --enable-libass --enable-libutvideo --enable-libbluray --enable-iconv --enable-libtwolame --extra-cflags=-DLIBTWOLAME_STATIC --enable-libzvbi --enable-libcaca --enable-libmodplug --extra-libs=-lstdc++ --extra-libs=-lpng --enable-libvidstab --enable-libx265 --enable-decklink --extra-libs=-loleaut32 --enable-libx264 --enable-libxvid --enable-libmp3lame --enable-version3 --enable-zlib --enable-librtmp --enable-libvorbis --enable-libtheora --enable-libspeex --enable-libopenjpeg --enable-gnutls --enable-libgsm --enable-libfreetype --enable-libopus --enable-frei0r --enable-filter=frei0r --enable-libvo-aacenc --enable-bzlib --enable-libxavs --enable-libopencore-amrnb --enable-libopencore-amrwb --enable-libvo-amrwbenc --enable-libschroedinger --enable-libvpx --enable-libilbc --enable-libwavpack --enable-libwebp --enable-libgme --enable-dxva2 --enable-libdcadec --enable-avisynth --enable-gray --enable-libopenh264" 
  # other possibilities (you'd need to also uncomment the call to their build method): 
  # --enable-w32threads # [worse UDP than pthreads, so not using that] 
  # --enable-libflite # [too big so not enabled]
  if [[ $build_intel_qsv = y ]]; then
    config_options="$config_options --enable-libmfx" # [not windows xp friendly]
  fi
  config_options="$config_options --extra-libs=-lpsapi" # dlfcn [frei0r?] requires this, has no .pc file XXX put in frei0r.pc? ...
  config_options="$config_options --extra-cflags=$CFLAGS" # --extra-cflags is not needed here, but adds it to the console output which I like for debugging purposes

  config_options="$config_options $postpend_configure_opts"

  if [[ "$non_free" = "y" ]]; then
    config_options="$config_options --enable-nonfree --enable-libfdk-aac --disable-libfaac --enable-nvenc " 
    # libfaac deemed too poor quality and becomes the default if included -- add it in and uncomment the build_faac line to include it, if anybody ever wants it... 
    # To use fdk-aac in VLC, we need to change FFMPEG's default (aac), but I haven't found how to do that... So I disabled it. This could be an new option for the script? (was --disable-decoder=aac )
    # other possible options: --enable-openssl [unneeded since we use gnutls] --enable-libaacplus [just use fdk-aac only to avoid collision]
    #  apply_patch https://raw.githubusercontent.com/rdp/ffmpeg-windows-build-helpers/master/patches/nvresize2.patch "-p1" # uncomment if you want to test nvresize filter [et al] http://ffmpeg.org/pipermail/ffmpeg-devel/2015-November/182781.html patch worked with 7ab37cae34b3845
  fi

  if [[ "$native_build" = "y" ]]; then
    config_options="$config_options --disable-runtime-cpudetect"
    # XXXX add --cpu=host ... ???
  else
    config_options="$config_options --enable-runtime-cpudetect"
  fi

  do_debug_build=n # if you need one for backtraces/examining segfaults using gdb.exe ... change this to a y :)
  if [[ "$do_debug_build" = "y" ]]; then
    # not sure how many of these are actually needed/useful...possibly none LOL
    config_options="$config_options --disable-optimizations --extra-cflags=-Og --extra-cflags=-fno-omit-frame-pointer --enable-debug=3 --extra-cflags=-fno-inline $postpend_configure_opts"
    # this one kills gdb workability for static build? ai ai [?] XXXX
    config_options="$config_options --disable-libgme"
  fi
  
  do_configure "$config_options"
  rm -f */*.a */*.dll *.exe # just in case some dependency library has changed, force it to re-link even if the ffmpeg source hasn't changed...
  rm -f already_ran_make*
  echo "doing ffmpeg make $(pwd)"
  do_make_and_make_install # install ffmpeg to get libavcodec libraries to be used as dependencies for other things, like vlc [XXX make this a parameter?] or install shared to a local dir

  # build ismindex.exe, too, just for fun 
  make tools/ismindex.exe || exit 1

  sed -i.bak 's/-lavutil -lm.*/-lavutil -lm -lpthread/' "$PKG_CONFIG_PATH/libavutil.pc" # XXX patch ffmpeg itself...
  sed -i.bak 's/-lswresample -lm.*/-lswresample -lm -lsoxr/' "$PKG_CONFIG_PATH/libswresample.pc" # XXX patch ffmpeg
  echo "Done! You will find $bits_target bit $shared non_free=$non_free binaries in $(pwd)/*.exe"
  echo `date`
  cd ..
}

find_all_build_exes() {
  local found=""
# NB that we're currently in the sandbox dir...
  for file in `find . -name ffmpeg.exe` `find . -name ffmpeg_g.exe` `find . -name ffplay.exe` `find . -name MP4Box.exe` `find . -name mplayer.exe` `find . -name mencoder.exe` `find . -name avconv.exe` `find . -name avprobe.exe` `find . -name x264.exe` `find . -name writeavidmxf.exe` `find . -name writeaviddv50.exe` `find . -name rtmpdump.exe` `find . -name x265.exe` `find . -name ismindex.exe`; do
    found="$found $(readlink -f $file)"
  done

  # bash recursive glob fails here again?
  for file in `find . -name vlc.exe | grep -- -`; do
    found="$found $(readlink -f $file)"
  done
  echo $found # pseudo return value...
}

build_dependencies() {
  build_libdlfcn # ffmpeg's frei0r implentation needs this <sigh>
  build_zlib # rtmp depends on it [as well as ffmpeg's optional but handy --enable-zlib]
  build_bzlib2 # in case someone wants it [ffmpeg uses it]
  build_libpng # for openjpeg, needs zlib
  build_gmp # for libnettle
  build_libnettle # needs gmp
  build_iconv # mplayer I think needs it for freetype [just it though], vlc also wants it.  looks like ffmpeg can use it too...not sure what for :)
  build_gnutls # needs libnettle, can use iconv it appears

  build_frei0r
  build_libsndfile
  build_libbs2b # needs libsndfile
  build_wavpack
  build_libdcadec
  build_libgme_game_music_emu
  build_libwebp
  build_libutvideo
  #build_libflite # too big for distro...though may still be useful
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
  build_freetype # uses bz2/zlib seemingly
  build_libexpat
  build_libxml2
  build_libbluray # needs libxml2, freetype [FFmpeg, VLC use this, at least]
  build_libjpeg_turbo # mplayer can use this, VLC qt might need it? [replaces libjpeg]
  build_libxvid
  build_libxavs
  build_libsoxr
  build_libx264
  build_libx265
  build_libopenh264
  build_lame
  build_twolame
  #build_lua was only used by libquvi
  #build_libproxy  # broken, needs a .pc file still... only used by libquvi
  #build_libquvi # needs libproxy, lua, apparently not useful anyway...so don't build it
  build_vidstab
  build_libcaca
  build_libmodplug # ffmepg and vlc can use this
  build_zvbi
  build_libvpx
  build_vo_aacenc
  build_libdecklink
  build_libilbc
  build_fontconfig # needs expat, needs freetype (at least uses it if available), can use iconv, but I believe doesn't currently
  build_libfribidi
  build_libass # needs freetype, needs fribidi, needs fontconfig
  build_libopenjpeg
  if [[ $build_intel_qsv = y ]]; then
    build_intel_quicksync_mfx
  fi
  if [[ "$non_free" = "y" ]]; then
    build_fdk_aac
    # build_faac # not included for now, too poor quality output :)
    # build_libaacplus # if you use it, conflicts with other AAC encoders <sigh>, so disabled :)
    build_libnvenc
  fi
  # build_openssl # hopefully do not need it anymore, since we use gnutls everywhere, so just don't even build it anymore...
  build_librtmp # needs gnutls [or openssl...]
}

build_apps() {
  if [[ $should_build_libdvbtee = "y" ]]; then
    build_libdvbtee
  fi
  # now the things that use the dependencies...
  if [[ $build_libmxf = "y" ]]; then
    build_libMXF
  fi
  if [[ $build_mp4box = "y" ]]; then
    build_mp4box
  fi
  if [[ $build_mplayer = "y" ]]; then
    build_mplayer
  fi
  if [[ $build_ffmpeg_static = "y" ]]; then
    build_ffmpeg ffmpeg
  fi
  if [[ $build_ffmpeg_shared = "y" ]]; then
    build_ffmpeg ffmpeg shared
  fi
  if [[ $build_vlc = "y" ]]; then
    build_vlc
  fi
}

# set some parameters initial values
cur_dir="$(pwd)/sandbox"
unset CFLAGS # I think this resets it...we don't want any linux CFLAGS seeping through...they can set this via --cflags=  if they want it set to anything
cpu_count="$(grep -c processor /proc/cpuinfo 2>/dev/null)" # linux cpu count
if [ -z "$cpu_count" ]; then
  cpu_count=`sysctl -n hw.ncpu | tr -d '\n'` # OS X
  if [ -z "$cpu_count" ]; then
    echo "warning, unable to determine cpu count, defaulting to 1"
    cpu_count=1 # else default to just 1, instead of blank, which means infinite 
  fi
fi
original_cpu_count=$cpu_count # save it away for some that revert it temporarily

set_box_memory_size_bytes
if [[ $box_memory_size_bytes -lt 600000000 ]]; then
  echo "your box only has $box_memory_size_bytes, 512MB (only) boxes crash when building cross compiler gcc, please add some swap" # 1G worked OK however...
  exit 1
fi

if [[ $box_memory_size_bytes -gt 2000000000 ]]; then
  gcc_cpu_count=$cpu_count # they can handle it seemingly...
else
  echo "low RAM detected so using only one cpu for gcc compilation"
  gcc_cpu_count=1 # compatible low RAM...
fi

build_ffmpeg_static=y
build_ffmpeg_shared=n
should_build_libdvbtee=n
build_libmxf=n
build_mp4box=n
build_mplayer=n
build_vlc=n
git_get_latest=y
prefer_stable=y
build_intel_qsv=n
#disable_nonfree=n # have no value by default to force user selection
original_cflags= # no export needed, this is just a local copy

# parse command line parameters, if any
while true; do
  case $1 in
    -h | --help ) echo "available options [with defaults]: 
      --build-ffmpeg-shared=n 
      --build-ffmpeg-static=y 
      --gcc-cpu-count=1x [number of cpu cores set it higher than 1 if you have multiple cores and > 1GB RAM, this speeds up initial cross compiler build. FFmpeg build uses number of cores no matter what] 
      --disable-nonfree=y (set to n to include nonfree like libfdk-aac) 
      --build-intel-qsv=n (set to y to include the [non windows xp compat.] qsv library and ffmpeg module
      --sandbox-ok=n [skip sandbox prompt if y] 
      -d [meaning \"defaults\" skip all prompts, just build ffmpeg static with some reasonable defaults like no git updates] 
      --build-libmxf=n [builds libMXF, libMXF++, writeavidmxfi.exe and writeaviddv50.exe from the BBC-Ingex project] 
      --build-mp4box=n [builds MP4Box.exe from the gpac project] 
      --build-mplayer=n [builds mplayer.exe and mencoder.exe] 
      --build-vlc=n [builds a [rather bloated] vlc.exe] 
      -a 'build all' builds mplayer, vlc, etc.
      --build-dvbtee=n [build dvbtee.exe a DVB profiler]
      --compiler-flavors=[multi,win32,win64] [default prompt, or skip if you already have one built, multi is both win32 and win64]
      --cflags= [default is empty, compiles for generic cpu, see README]
      --git-get-latest=y [do a git pull for latest code from repositories like FFmpeg--can force a rebuild if changes are detected]
      --prefer-stable=y build a few libraries from releases instead of git master
      --high-bitdepth=y Enable high bit depth for x264 (10 bits) and x265 (10 and 12 bits, x64 build. Not officially supported on x86 (win32), but enabled by disabling its assembly).
       "; exit 0 ;;
    --sandbox-ok=* ) sandbox_ok="${1#*=}"; shift ;;
    --gcc-cpu-count=* ) gcc_cpu_count="${1#*=}"; shift ;;
    --build-libmxf=* ) build_libmxf="${1#*=}"; shift ;;
    --build-mp4box=* ) build_mp4box="${1#*=}"; shift ;;
    --git-get-latest=* ) git_get_latest="${1#*=}"; shift ;;
    --build-intel-qsv=* ) build_intel_qsv="${1#*=}"; shift ;;
    --build-mplayer=* ) build_mplayer="${1#*=}"; shift ;;
    --cflags=* ) 
       echo "removing old .exe's, in case cflags has changed"
       for file in $(find_all_build_exes); do
         echo "deleting $file in case it isn't rebuilt with new different cflags, which could cause confusion"
         echo "also deleting $(dirname $file)/already_ran_make*"
         rm $(dirname $file)/already_ran_make*
         rm $(dirname $(dirname $file))/already_ran_make* # vlc is packaged somewhere nested 2 deep
         rm $file
       done
       export CFLAGS="${1#*=}"; original_cflags="${1#*=}"; echo "setting cflags as $original_cflags"; shift ;;
    --build-vlc=* ) build_vlc="${1#*=}"; shift ;;
    --build-dvbtee=* ) should_build_libdvbtee="${1#*=}"; shift ;;
    --disable-nonfree=* ) disable_nonfree="${1#*=}"; shift ;;
    -a         ) compiler_flavors="multi"; build_mplayer=y; build_libmxf=y; build_mp4box=y; build_vlc=y; build_ffmpeg_shared=y; high_bitdepth=y; build_ffmpeg_static=y; 
                 disable_nonfree=n; git_get_latest=y; sandbox_ok="y"; build_intel_qsv="y"; should_build_libdvbtee="y"; shift ;;
    -d         ) gcc_cpu_count=$cpu_count; disable_nonfree="y"; sandbox_ok="y"; compiler_flavors="win32"; git_get_latest="n"; shift ;;
    --compiler-flavors=* ) compiler_flavors="${1#*=}"; shift ;;
    --build-ffmpeg-static=* ) build_ffmpeg_static="${1#*=}"; shift ;;
    --build-ffmpeg-shared=* ) build_ffmpeg_shared="${1#*=}"; shift ;;
    --prefer-stable=* ) prefer_stable="${1#*=}"; shift ;;
    --high-bitdepth=* ) high_bitdepth="${1#*=}"; shift ;;
    -- ) shift; break ;;
    -* ) echo "Error, unknown option: '$1'."; exit 1 ;;
    * ) break ;;
  esac
done

check_missing_packages # do this first since it's annoying to go through prompts then be rejected
intro # remember to always run the intro, since it adjust pwd
install_cross_compiler 

export PKG_CONFIG_LIBDIR= # disable pkg-config from finding [and using] normal linux system installed libs [yikes]

if [[ $OSTYPE == darwin* ]]; then 
  # mac add some helper scripts
  if [[ ! -d mac_helper_scripts ]]; then
    mkdir mac_helper_scripts
  fi
  cd mac_helper_scripts
    if [[ ! -x readlink ]]; then
      # make some scripts behave like linux...
      curl -4 https://raw.githubusercontent.com/rdp/ffmpeg-windows-build-helpers/master/patches/md5sum.mac > md5sum  || exit 1
      chmod u+x ./md5sum
      curl -4 https://raw.githubusercontent.com/rdp/ffmpeg-windows-build-helpers/master/patches/readlink.mac > readlink  || exit 1
      chmod u+x ./readlink
    fi
    export PATH=`pwd`:$PATH
  cd ..
fi

original_path="$PATH"
if [[ $compiler_flavors == "multi" || $compiler_flavors == "win32" ]]; then
  echo "Building 32-bit ffmpeg..."
  host_target='i686-w64-mingw32'
  mingw_w64_x86_64_prefix="$cur_dir/cross_compilers/mingw-w64-i686/$host_target"
  path_addition="$cur_dir/cross_compilers/mingw-w64-i686/bin"
  export PATH="$path_addition:$original_path"
  export PKG_CONFIG_PATH="$cur_dir/cross_compilers/mingw-w64-i686/i686-w64-mingw32/lib/pkgconfig"
  bits_target=32
  cross_prefix="$cur_dir/cross_compilers/mingw-w64-i686/bin/i686-w64-mingw32-"
  make_prefix_options="CC=${cross_prefix}gcc AR=${cross_prefix}ar PREFIX=$mingw_w64_x86_64_prefix RANLIB=${cross_prefix}ranlib LD=${cross_prefix}ld STRIP=${cross_prefix}strip CXX=${cross_prefix}g++"
  mkdir -p win32
  cd win32
  build_dependencies
  build_apps
  cd ..
fi

if [[ $compiler_flavors == "multi" || $compiler_flavors == "win64" ]]; then
  echo "**************Building 64-bit ffmpeg..." # make it have a bit header to you can see when 32 bit is done more easily
  host_target='x86_64-w64-mingw32'
  mingw_w64_x86_64_prefix="$cur_dir/cross_compilers/mingw-w64-x86_64/$host_target"
  path_addition="$cur_dir/cross_compilers/mingw-w64-x86_64/bin"
  export PATH="$path_addition:$original_path"
  export PKG_CONFIG_PATH="$cur_dir/cross_compilers/mingw-w64-x86_64/x86_64-w64-mingw32/lib/pkgconfig"
  mkdir -p x86_64
  bits_target=64
  cross_prefix="$cur_dir/cross_compilers/mingw-w64-x86_64/bin/x86_64-w64-mingw32-"
  make_prefix_options="CC=${cross_prefix}gcc AR=${cross_prefix}ar PREFIX=$mingw_w64_x86_64_prefix RANLIB=${cross_prefix}ranlib LD=${cross_prefix}ld STRIP=${cross_prefix}strip CXX=${cross_prefix}g++"
  cd x86_64
  build_dependencies
  build_apps
  cd ..
fi

echo "searching for all local exe's..."
for file in $(find_all_build_exes); do
  echo "built $file"
done
echo "done!"
