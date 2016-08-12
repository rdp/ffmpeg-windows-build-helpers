# can pass param like "3.1.1" for that ffmpeg release
set -e # abort if any line fails

if [[ $1 != "" ]]; then
  desired_ffmpeg_ver="--ffmpeg-git-checkout-version=n$1"
fi

# synchronize git versions, in case it's doing a git master build (the default)
# so that packaging doesn't detect discrepancies and barf :)
for dir in sandbox/*/ffmpeg_git*; do
  if [[ -d $dir ]]; then # else there were none, and it passes through the string "sandbox/*..." <sigh>
    cd $dir
    if [[ $1 == "" ]]; then
      git pull
    fi 
    # else don't do git pull as it resets the git hash so forces a rebuild even if it's already previously built to that hash, ex: release build
    rm -f already*
    cd ../../.. 
  fi
done

# all are both 32 and 64 bit
./cross_compile_ffmpeg.sh --compiler-flavors=multi --disable-nonfree=y --git-get-latest=n --build-ffmpeg-shared=n --build-ffmpeg-static=y $desired_ffmpeg_ver 
./cross_compile_ffmpeg.sh --compiler-flavors=multi --disable-nonfree=y --git-get-latest=n --build-ffmpeg-shared=y --build-ffmpeg-static=n $desired_ffmpeg_ver
./cross_compile_ffmpeg.sh --compiler-flavors=multi --disable-nonfree=y --git-get-latest=n --build-intel-qsv=n --build-ffmpeg-shared=n --build-ffmpeg-static=y $desired_ffmpeg_ver # windows xp :|
./cross_compile_ffmpeg.sh --compiler-flavors=multi --disable-nonfree=y --git-get-latest=n --build-ffmpeg-static=y --build-ffmpeg-shared=n --high-bitdepth=y $desired_ffmpeg_ver

rm -rf sandbox/distros # free up space from any previous distros
if [[ $1 != "" ]]; then
  prettified_ver=v$1
fi

./patches/all_zip_distros.sh $prettified_ver
