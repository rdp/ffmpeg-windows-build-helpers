# This basically zips up some local builds for distro
# can pass an argument like "v3.2.1"
set -e # abort if any line fails

cd sandbox/win32/ffmpeg_git
  git_version=`git rev-parse --short HEAD` # "all" of them should match this
cd ../../..
mkdir -p sandbox/distros # -p so it doesn't warn
date=`date +%Y-%m-%d`

if [[ $1 != "" ]]; then
  date="$date-$1" # add it here so it gets added everywhere
fi

date_version="$date-g$git_version"

root="sandbox/distros/$date_version"
echo "creating $root distros..."
rm -rf $root
mkdir -p "$root/32-bit"
mkdir -p "$root/64-bit"

copy_ffmpeg_binaries() {
  local from_dir=$1
  local to_dir=$2

  # make sure git matches everywhere, otherwise zip names off :|
  cd $from_dir
    local_git_version=`git rev-parse --short HEAD`
    if [[ $git_version != $local_git_version ]]; then
      echo "git versions don't match $from_dir, $git_version != $local_git_version hesitating to continue..."
      exit -1
    fi
  cd ../../..
  mkdir $to_dir
  # just copy static install files XXXX use make install here better [?]
  cp $from_dir/ffmpeg.exe "$to_dir"
  cp $from_dir/ffplay.exe "$to_dir"
  cp $from_dir/ffprobe.exe "$to_dir"
}

do_shared() {
  local from_dir=$1
  local to_dir=$2

  mkdir $to_dir

  # XXX no git version check :|

  cp -r $from_dir/* $to_dir
}

do_shareds() {
  do_shared ./sandbox/win32/ffmpeg_git_shared.installed $root/32-bit/ffmpeg-shared
  do_shared ./sandbox/x86_64/ffmpeg_git_shared.installed $root/64-bit/ffmpeg-shared
  cd sandbox/distros
    create_zip ffmpeg.shared.$date.32-bit.zip "$date_version/32-bit/ffmpeg-shared/*"
    create_zip ffmpeg.shared.$date.64-bit.zip "$date_version/64-bit/ffmpeg-shared/*"
  cd ../..
}

create_zip() {
  echo "zipping $1"
  zip -qr $1 $2 # without  -q for quiet it was kind of screen chatty
}

do_xp_compat_and_zip() {
  copy_ffmpeg_binaries ./sandbox/win32/ffmpeg_git_xp_compat "$root/32-bit/ffmpeg-static-xp-compatible"
  copy_ffmpeg_binaries ./sandbox/x86_64/ffmpeg_git_xp_compat "$root/64-bit/ffmpeg-static-xp-compatible"
  cd sandbox/distros
    create_zip ffmpeg.static.$date.32-bit.ffmpeg-static-xp-compatible.zip "$date_version/32-bit/ffmpeg-static-xp-compatible/*"
    create_zip ffmpeg.static.$date.64-bit.ffmpeg-static-xp-compatible.zip "$date_version/64-bit/ffmpeg-static-xp-compatible/*"
  cd ../..
}

do_statics() {
  copy_ffmpeg_binaries ./sandbox/win32/ffmpeg_git "$root/32-bit/ffmpeg-static"  
  copy_ffmpeg_binaries ./sandbox/x86_64/ffmpeg_git "$root/64-bit/ffmpeg-static" 
  cd sandbox/distros
    create_zip ffmpeg.static.$date.32-bit.zip "$date_version/32-bit/ffmpeg-static/*"
    create_zip ffmpeg.static.$date.64-bit.zip "$date_version/64-bit/ffmpeg-static/*"
  cd ../..
}

do_statics
do_xp_compat_and_zip
do_shareds

readme=./sandbox/distros/readme.txt
local_git_v=$(git rev-parse --short HEAD)
echo "built $date_version using ffmpeg-windows-build-helpers v$local_git_v
see the github distro at that commit if you want to know which dependencies and their versions were used
also see https://github.com/rdp/ffmpeg-windows-build-helpers if you need/want instructions to build your own modified version" > $readme
echo "created file $readme"
echo "now upload them!"

