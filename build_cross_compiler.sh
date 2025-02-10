#!/usr/bin/env bash
# ffmpeg windows cross compile helper/download script, see github repo README
# Copyright (C) 2012 Roger Pack, the script is under the GPLv3, but output FFmpeg's executables aren't
# set -x

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
  # downcase it—
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

function sortable_version { echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; }

at_least_required_version() { # params: required actual
  local sortable_required=$(sortable_version $1)
  sortable_required=$(echo $sortable_required | sed 's/^0*//') # remove preceding zeroes, which bash later interprets as octal or screwy
  local sortable_actual=$(sortable_version $2)
  sortable_actual=$(echo $sortable_actual | sed 's/^0*//')
  [[ "$sortable_actual" -ge "$sortable_required" ]]
}

apt_not_installed() {
  for x in "$@"; do
    if ! dpkg -l "$x" | grep -q '^.i'; then
      need_install="$need_install $x"
    fi
  done
  echo "$need_install"
}

check_missing_packages () {
  # We will need this later if we don't want to just constantly be grepping the /etc/os-release file
  if [ -z "${VENDOR}" ] && grep -E '(centos|rhel)' /etc/os-release &> /dev/null; then
    # In RHEL this should always be set anyway. But not so sure about CentOS
    VENDOR="redhat"
  fi
  # zeranoe's build scripts use wget, though we don't here...
  local check_packages=('ragel' 'curl' 'pkg-config' 'make' 'git' 'svn' 'gcc' 'autoconf' 'automake' 'yasm' 'cvs' 'flex' 'bison' 'makeinfo' 'g++' 'ed' 'pax' 'unzip' 'patch' 'wget' 'xz' 'nasm' 'gperf' 'autogen' 'bzip2' 'realpath' 'meson' 'clang' 'python')
  # autoconf-archive is just for leptonica FWIW
  # I'm not actually sure if VENDOR being set to centos is a thing or not. On all the centos boxes I can test on it's not been set at all.
  # that being said, if it where set I would imagine it would be set to centos... And this contition will satisfy the "Is not initially set"
  # case because the above code will assign "redhat" all the time.
  if [ -z "${VENDOR}" ] || [ "${VENDOR}" != "redhat" ] && [ "${VENDOR}" != "centos" ]; then
    check_packages+=('cmake')
  fi
  # libtool check is wonky...
  if [[ $OSTYPE == darwin* ]]; then
    check_packages+=('glibtoolize') # homebrew special :|
  else
    check_packages+=('libtoolize') # the rest of the world
  fi
  # Use hash to check if the packages exist or not. Type is a bash builtin which I'm told behaves differently between different versions of bash.
  for package in "${check_packages[@]}"; do
    hash "$package" &> /dev/null || missing_packages=("$package" "${missing_packages[@]}")
  done
  if [ "${VENDOR}" = "redhat" ] || [ "${VENDOR}" = "centos" ]; then
    if [ -n "$(hash cmake 2>&1)" ] && [ -n "$(hash cmake3 2>&1)" ]; then missing_packages=('cmake' "${missing_packages[@]}"); fi
  fi
  if [[ -n "${missing_packages[@]}" ]]; then
    clear
    echo "Could not find the following execs (svn is actually package subversion, makeinfo is actually package texinfo if you're missing them): ${missing_packages[*]}"
    echo 'Install the missing packages before running this script.'
    determine_distro

    apt_pkgs='subversion ragel curl texinfo g++ ed bison flex cvs libva-dev yasm automake libtool autoconf gcc cmake git make pkg-config zlib1g-dev unzip pax nasm gperf autogen bzip2 autoconf-archive p7zip-full meson clang gettext subversion texinfo patch wget xz-utils coreutils'

    [[ $DISTRO == "debian" ]] && apt_pkgs="$apt_pkgs libtool-bin ed" # extra for debian
    case "$DISTRO" in
      Ubuntu)
        echo "for ubuntu:"
        echo "$ sudo apt-get update"
        ubuntu_ver="$(lsb_release -rs)"
        if at_least_required_version "18.04" "$ubuntu_ver"; then
          apt_pkgs="$apt_pkgs python3-distutils" # guess it's no longer built-in, lensfun requires it...
        fi
        if at_least_required_version "20.04" "$ubuntu_ver"; then
          apt_pkgs="$apt_pkgs python-is-python3" # needed
        fi
        echo "$ sudo apt-get install $apt_pkgs -y"
        if uname -a | grep  -q -- "-microsoft" ; then
         echo NB if you use WSL Ubuntu 20.04 you need to do an extra step: https://github.com/rdp/ffmpeg-windows-build-helpers/issues/452
	fi
        ;;
      debian)
        echo "for debian:"
        echo "$ sudo apt-get update"
        # Debian version is always encoded in the /etc/debian_version
        # This file is deployed via the base-files package which is the essential one - deployed in all installations.
        # See their content for individual debian releases - https://sources.debian.org/src/base-files/
        # Stable releases contain a version number.
        # Testing/Unstable releases contain a textual codename description (e.g. bullseye/sid)
        #
        deb_ver="$(cat /etc/debian_version)"
        # Upcoming codenames taken from https://en.wikipedia.org/wiki/Debian_version_history
        #
        if [[ $deb_ver =~ bullseye ]]; then
            deb_ver="11"
        elif [[ $deb_ver =~ bookworm ]]; then
            deb_ver="12"
        elif [[ $deb_ver =~ trixie ]]; then
            deb_ver="13"
        fi
        if at_least_required_version "10" "$deb_ver"; then
          apt_pkgs="$apt_pkgs python3-distutils" # guess it's no longer built-in, lensfun requires it...
        fi
        if at_least_required_version "11" "$deb_ver"; then
          apt_pkgs="$apt_pkgs python-is-python3" # needed
        fi
        apt_missing="$(apt_not_installed "$apt_pkgs")"
        echo "$ sudo apt-get install $apt_missing -y"
        ;;
      *)
        echo "for OS X (homebrew): brew install ragel wget cvs yasm autogen automake autoconf cmake libtool xz pkg-config nasm bzip2 autoconf-archive p7zip coreutils meson llvm" # if edit this edit docker/Dockerfile also :|
        echo "   and set llvm to your PATH if on catalina"
        echo "for RHEL/CentOS: First ensure you have epel repo available, then run $ sudo yum install ragel subversion texinfo libtool autogen gperf nasm patch unzip pax ed gcc-c++ bison flex yasm automake autoconf gcc zlib-devel cvs bzip2 cmake3 -y"
        echo "for fedora: if your distribution comes with a modern version of cmake then use the same as RHEL/CentOS but replace cmake3 with cmake."
        echo "for linux native compiler option: same as <your OS> above, also add libva-dev"
        ;;
    esac
    exit 1
  fi

  export REQUIRED_CMAKE_VERSION="3.0.0"
  for cmake_binary in 'cmake' 'cmake3'; do
    # We need to check both binaries the same way because the check for installed packages will work if *only* cmake3 is installed or
    # if *only* cmake is installed.
    # On top of that we ideally would handle the case where someone may have patched their version of cmake themselves, locally, but if
    # the version of cmake required move up to, say, 3.1.0 and the cmake3 package still only pulls in 3.0.0 flat, then the user having manually
    # installed cmake at a higher version wouldn't be detected.
    if hash "${cmake_binary}"  &> /dev/null; then
      cmake_version="$( "${cmake_binary}" --version | sed -e "s#${cmake_binary}##g" | head -n 1 | tr -cd '[0-9.\n]' )"
      if at_least_required_version "${REQUIRED_CMAKE_VERSION}" "${cmake_version}"; then
        export cmake_command="${cmake_binary}"
        break
      else
        echo "your ${cmake_binary} version is too old ${cmake_version} wanted ${REQUIRED_CMAKE_VERSION}"
      fi
    fi
  done

  # If cmake_command never got assigned then there where no versions found which where sufficient.
  if [ -z "${cmake_command}" ]; then
    echo "there where no appropriate versions of cmake found on your machine."
    exit 1
  else
    # If cmake_command is set then either one of the cmake's is adequate.
    if [[ $cmake_command != "cmake" ]]; then # don't echo if it's the normal default
      echo "cmake binary for this build will be ${cmake_command}"
    fi
  fi

  if [[ ! -f /usr/include/zlib.h ]]; then
    echo "warning: you may need to install zlib development headers first if you want to build mp4-box [on ubuntu: $ apt-get install zlib1g-dev] [on redhat/fedora distros: $ yum install zlib-devel]" # XXX do like configure does and attempt to compile and include zlib.h instead?
    sleep 1
  fi

  # TODO nasm version :|

  # doing the cut thing with an assigned variable dies on the version of yasm I have installed (which I'm pretty sure is the RHEL default)
  # because of all the trailing lines of stuff
  export REQUIRED_YASM_VERSION="1.2.0" # export ???
  local yasm_binary=yasm
  local yasm_version="$( "${yasm_binary}" --version |sed -e "s#${yasm_binary}##g" | head -n 1 | tr -dc '[0-9.\n]' )"
  if ! at_least_required_version "${REQUIRED_YASM_VERSION}" "${yasm_version}"; then
    echo "your yasm version is too old $yasm_version wanted ${REQUIRED_YASM_VERSION}"
    exit 1
  fi
  local meson_version=`meson --version`
  if ! at_least_required_version "0.49.2" "${meson_version}"; then
    echo "your meson version is too old $meson_version wanted 0.49.2"
    exit 1
  fi
  # also check missing "setup" so it's early LOL

  #check if WSL
  # check WSL for interop setting make sure its disabled
  # check WSL for kernel version look for version 4.19.128 current as of 11/01/2020
  if uname -a | grep  -iq -- "-microsoft" ; then
    if cat /proc/sys/fs/binfmt_misc/WSLInterop | grep -q enabled ; then
      echo "windows WSL detected: you must first disable 'binfmt' by running this
      sudo bash -c 'echo 0 > /proc/sys/fs/binfmt_misc/WSLInterop'
      then try again"
      #exit 1
    fi
    export MINIMUM_KERNEL_VERSION="4.19.128"
    KERNVER=$(uname -a | awk -F'[ ]' '{ print $3 }' | awk -F- '{ print $1 }')

    function version { # for version comparison @ stackoverflow.com/a/37939589
      echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'
    }

    if [ $(version $KERNVER) -lt $(version $MINIMUM_KERNEL_VERSION) ]; then
      echo "Windows Subsystem for Linux (WSL) detected - kernel not at minumum version required: $MINIMUM_KERNEL_VERSION
      Please update via windows update then try again"
      #exit 1
    fi
    echo "for WSL ubuntu 20.04 you need to do an extra step https://github.com/rdp/ffmpeg-windows-build-helpers/issues/452"
  fi

}

determine_distro() {

# Determine OS platform from https://askubuntu.com/a/459425/20972
UNAME=$(uname | tr "[:upper:]" "[:lower:]")
# If Linux, try to determine specific distribution
if [ "$UNAME" == "linux" ]; then
    # If available, use LSB to identify distribution
    if [ -f /etc/lsb-release -o -d /etc/lsb-release.d ]; then
        export DISTRO=$(lsb_release -i | cut -d: -f2 | sed s/'^\t'//)
    # Otherwise, use release info file
    else
        export DISTRO=$(grep '^ID' /etc/os-release | sed 's#.*=\(\)#\1#')
    fi
fi
# For everything else (or if above failed), just use generic identifier
[ "$DISTRO" == "" ] && export DISTRO=$UNAME
unset UNAME
}


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
  echo `date` # for timestamping super long builds LOL
  if [[ $sandbox_ok != 'y' && ! -d sandbox ]]; then
    echo
    echo "Building in $PWD/sandbox, will use ~ 12GB space!"
    echo
  fi
  mkdir -p "$cur_dir"
  cd "$cur_dir" || exit
  if [[ $disable_nonfree = "y" ]]; then
    non_free="n"
  else
    if  [[ $disable_nonfree = "n" ]]; then
      non_free="y"
    else
      yes_no_sel "Would you like to include non-free (non GPL compatible) libraries, like [libfdk_aac,decklink -- note that the internal AAC encoder is ruled almost as high a quality as fdk-aac these days]
The resultant binary may not be distributable, but can be useful for in-house use. Include these non-free license libraries [y/N]?" "n"
      non_free="$user_input" # save it away
    fi
  fi
  echo "sit back, this may take awhile..."
}

pick_compiler_flavors() {
  while [[ "$compiler_flavors" != [1-5] ]]; do
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
  4. Local native
  5. Exit
EOF
    echo -n 'Input your choice [1-5]: '
    read compiler_flavors
  done
  case "$compiler_flavors" in
  1 ) compiler_flavors=multi ;;
  2 ) compiler_flavors=win32 ;;
  3 ) compiler_flavors=win64 ;;
  4 ) compiler_flavors=native ;;
  5 ) echo "exiting"; exit 0 ;;
  * ) clear;  echo 'Your choice was not valid, please try again.'; echo ;;
  esac
}

# made into a method so I don't/don't have to download this script every time if only doing just 32 or just6 64 bit builds...
download_gcc_build_script() {
    local zeranoe_script_name=$1
    rm -f $zeranoe_script_name || exit 1
    curl -4 file://$patch_dir/$zeranoe_script_name -O --fail || exit 1
    chmod u+x $zeranoe_script_name
}

install_cross_compiler() {
  local win32_gcc="cross_compilers/mingw-w64-i686/bin/i686-w64-mingw32-gcc"
  local win64_gcc="cross_compilers/mingw-w64-x86_64/bin/x86_64-w64-mingw32-gcc"
  if [[ -f $win32_gcc && -f $win64_gcc ]]; then
   echo "MinGW-w64 compilers both already installed, not re-installing..."
   if [[ -z $compiler_flavors ]]; then
     echo "selecting multi build (both win32 and win64)...since both cross compilers are present assuming you want both..."
     compiler_flavors=multi
   fi
   return # early exit they've selected at least some kind by this point...
  fi

  if [[ -z $compiler_flavors ]]; then
    pick_compiler_flavors
  fi
  if [[ $compiler_flavors == "native" ]]; then
    echo "native build, not building any cross compilers..."
    return
  fi

  mkdir -p cross_compilers
  cd cross_compilers || exit 

    unset CFLAGS # don't want these "windows target" settings used the compiler itself since it creates executables to run on the local box (we have a parameter allowing them to set them for the script "all builds" basically)
    # pthreads version to avoid having to use cvs for it
    echo "Starting to download and build cross compile version of gcc [requires working internet access] with thread count $gcc_cpu_count..."
    echo ""

    # --disable-shared allows c++ to be distributed at all...which seemed necessary for some random dependency which happens to use/require c++...
    local zeranoe_script_name=mingw-w64-build-r22.local
    local zeranoe_script_options="--gcc-ver=10.2.0 --mingw-w64-ver=9.0.0 --default-configure --cpu-count=$gcc_cpu_count --disable-shared --clean-build --verbose --allow-overwrite --threads=winpthreads" # allow-overwrite to avoid some crufty prompts if I do rebuilds [or maybe should just nuke everything...]
    if [[ ($compiler_flavors == "win32" || $compiler_flavors == "multi") && ! -f ../$win32_gcc ]]; then
      echo "Building win32 cross compiler..."
      download_gcc_build_script $zeranoe_script_name
      if [[ `uname` =~ "5.1" ]]; then # Avoid using secure API functions for compatibility with msvcrt.dll on Windows XP.
        sed -i "s/ --enable-secure-api//" $zeranoe_script_name
      fi
      CFLAGS=-O2 CXXFLAGS=-O2 nice ./$zeranoe_script_name $zeranoe_script_options --build-type=win32 || exit 1
      if [[ ! -f ../$win32_gcc ]]; then
        echo "Failure building 32 bit gcc? Recommend nuke sandbox (rm -rf sandbox) and start over..."
        exit 1
      fi
      if [[ ! -f  ../cross_compilers/mingw-w64-i686/i686-w64-mingw32/lib/libmingwex.a ]]; then
	      echo "failure building mingwex? 32 bit"
	      exit 1
      fi
    fi
    if [[ ($compiler_flavors == "win64" || $compiler_flavors == "multi") && ! -f ../$win64_gcc ]]; then
      echo "Building win64 x86_64 cross compiler..."
      download_gcc_build_script $zeranoe_script_name
      CFLAGS=-O2 CXXFLAGS=-O2 nice ./$zeranoe_script_name $zeranoe_script_options --build-type=win64 || exit 1
      if [[ ! -f ../$win64_gcc ]]; then
        echo "Failure building 64 bit gcc? Recommend nuke sandbox (rm -rf sandbox) and start over..."
        exit 1
      fi
      if [[ ! -f  ../cross_compilers/mingw-w64-x86_64/x86_64-w64-mingw32/lib/libmingwex.a ]]; then
	      echo "failure building mingwex? 64 bit"
	      exit 1
      fi
    fi

    # rm -f build.log # leave resultant build log...sometimes useful...
    reset_cflags
  cd ..
  echo "Done building (or already built) MinGW-w64 cross-compiler(s) successfully..."
  echo `date` # so they can see how long it took :)
}
