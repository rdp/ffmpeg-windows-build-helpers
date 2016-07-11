#This basically zips up some local builds for distro

cd sandbox/win32/ffmpeg_git
  git_version=`git rev-parse --short HEAD`
cd ../../..
mkdir -p sandbox/distros # -p so it doesn't warn
date=`date +%Y-%m-%d`
date="$date-g$git_version"

file="$date"
root="sandbox/distros/$file"
echo "creating $root for $date"
rm -rf $root
mkdir -p "$root/32-bit"
mkdir -p "$root/64-bit"

# special static install files XXXX use make install here [?]

copy_ffmpeg_binaries() {
  local from_dir=$1
  local to_dir=$2
  local strip=$3

  # make sure git matches everywhere, otherwise zip names off :|
  cd $from_dir
    local_git_version=`git rev-parse --short HEAD`
    if [[ $git_version != $local_git_version ]]; then
      echo "git versions don't match $from_dir, $git_version != $local_git_version hesitating to continue..."
      exit -1
    fi
  cd ../../..
  mkdir $to_dir
  cp $from_dir/ffmpeg.exe "$to_dir"
  cp $from_dir/ffplay.exe "$to_dir"
  cp $from_dir/ffprobe.exe "$to_dir"

  # in case shared: TODO
  # cp $from_dir/*/*-*.dll "$to_dir"  # flatten it, since we're not using make install :|
  # $strip $to_dir/*.dll # XXX why?

  # XXXX copy in frei0r filters :) meh sopmeday
}


do_shareds() {
  copy_ffmpeg_binaries ./sandbox/win32/ffmpeg_git_shared $root/32-bit/ffmpeg-shared ./sandbox/mingw-w64-i686/bin/i686-w64-mingw32-strip
  copy_ffmpeg_binaries ./sandbox/x86_64/ffmpeg_git_shared $root/64-bit/ffmpeg-shared ./sandbox/mingw-w64-x86_64/bin/x86_64-w64-mingw32-strip
  echo "todo zip shared"
  exit 1
}


create_zip() {
  echo "zipping $1"
  zip -r $1 $2
}

create_static_zips() {
  cd sandbox/distros
    create_zip ffmpeg.static.$date.32-bit.zip "$file/32-bit/ffmpeg-static/*"
    create_zip ffmpeg.static.$date.64-bit.zip "$file/64-bit/ffmpeg-static/*"
  cd ../..
}

do_high_bitdepth_and_zip() {
  copy_ffmpeg_binaries ./sandbox/win32/ffmpeg_git_x26x_high_bitdepth "$root/32-bit/ffmpeg-static-x26x-high-bitdepth"  
  copy_ffmpeg_binaries ./sandbox/x86_64/ffmpeg_git_x26x_high_bitdepth "$root/64-bit/ffmpeg-static-x26x-high-bitdepth" 
  cd sandbox/distros
    create_zip ffmpeg.static.$date.32-bit.x26x-high-bitdepth.zip "$file/32-bit/ffmpeg-static-x26x-high-bitdepth/*"
    create_zip ffmpeg.static.$date.64-bit.x26x-high-bitdepth.zip "$file/64-bit/ffmpeg-static-x26x-high-bitdepth/*"
  cd ../..
}

copy_ffmpeg_binaries ./sandbox/win32/ffmpeg_git "$root/32-bit/ffmpeg-static"  
copy_ffmpeg_binaries ./sandbox/x86_64/ffmpeg_git "$root/64-bit/ffmpeg-static" 
create_static_zips
#do_shareds # if I ever care...
do_high_bitdepth_and_zip

