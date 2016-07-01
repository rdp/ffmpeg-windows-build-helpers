#This basically packages up all your FFmpeg static/shared builds into zipped files
# set -x

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
      echo "git versions don't match $from_dir, hesitating to continue..."
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

copy_ffmpeg_binaries ./sandbox/win32/ffmpeg_git "$root/32-bit/ffmpeg-static"  
copy_ffmpeg_binaries ./sandbox/x86_64/ffmpeg_git "$root/64-bit/ffmpeg-static" 

do_shareds() {
  copy_ffmpeg_binaries ./sandbox/win32/ffmpeg_git_shared $root/32-bit/ffmpeg-shared ./sandbox/mingw-w64-i686/bin/i686-w64-mingw32-strip
  copy_ffmpeg_binaries ./sandbox/x86_64/ffmpeg_git_shared $root/64-bit/ffmpeg-shared ./sandbox/mingw-w64-x86_64/bin/x86_64-w64-mingw32-strip
}

#do_shareds # if I ever care

copy_from() {
 # if you want other exe's like x264.exe ...
 from_dir=$1 # like win32
 to_dir=$2 # like 32-bit

  cd sandbox/$from_dir
  for file2 in `find . -name MP4Box.exe` `find . -name mplayer.exe` `find . -name mencoder.exe` `find . -name avconv.exe` `find . -name avprobe.exe` `find . -name x264.exe`; do
    cp $file2 "../../$root/$to_dir"
  done
  cd ../..
  if [[ -f ./sandbox/$from_dir/vlc_rdp/vlc-2.2.0-git/vlc.exe ]]; then
    cp -r ./sandbox/$from_dir/vlc_rdp/vlc-2.2.0-git $root/$to_dir/vlc
  fi
}

# copy_from win32 32-bit
# copy_from x86_64 64-bit

create_zip() {
  echo "zipping $1"
  zip -r $1 $2
}

create_zips() {
  cd sandbox/distros
    create_zip ffmpeg.static.$date.32-bit.zip "$file/32-bit/ffmpeg-static/*"
    create_zip ffmpeg.static.$date.64-bit.zip "$file/64-bit/ffmpeg-static/*"
  cd ..
}

create_zips

do_high_bitdepth() {
  copy_ffmpeg_binaries ./sandbox/win32/ffmpeg_git_x26x_high_bitdepth "$root/32-bit/ffmpeg-static-x26x-high-bitdepth"  
  copy_ffmpeg_binaries ./sandbox/x86_64/ffmpeg_git_x26x_high_bitdepth "$root/64-bit/ffmpeg-static-x26x-high-bitdepth" 
  cd sandbox/distros
    create_zip ffmpeg.static.$date.32-bit.x26x-high-bitdepth.zip "$file/32-bit/ffmpeg-static-x26x-high-bitdepth/*"
    create_zip ffmpeg.static.$date.64-bit.x26x-high-bitdepth.zip "$file/64-bit/ffmpeg-static-x26x-high-bitdepth/*"
  cd ..
}

#do_high_bitdepth

