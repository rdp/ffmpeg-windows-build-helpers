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
    old_git_version=`git rev-parse HEAD`
    if [[ $1 == "" ]]; then
      git pull # assume we want them all on git master
    fi 
    # avoid forcing reconfigure+remake *every time you rerun* this script :|
    if [[ `git rev-parse HEAD` != $old_git_version ]]; then
      rm -f already*
    fi
    cd ../../.. 
  fi
done

# all are both 32 and 64 bit
./cross_compile_ffmpeg.sh --compiler-flavors=multi --disable-nonfree=y --git-get-latest=n --build-ffmpeg-shared=y --build-ffmpeg-static=y $desired_ffmpeg_ver 
./cross_compile_ffmpeg.sh --compiler-flavors=multi --disable-nonfree=y --git-get-latest=n --build-ffmpeg-shared=y --build-ffmpeg-static=y --enable-gpl=n $desired_ffmpeg_ver  # lgpl
./cross_compile_ffmpeg.sh --compiler-flavors=multi --disable-nonfree=y --git-get-latest=n --build-intel-qsv=n --build-ffmpeg-shared=n --build-ffmpeg-static=y $desired_ffmpeg_ver # windows xp :|
./cross_compile_ffmpeg.sh --compiler-flavors=multi --disable-nonfree=y --git-get-latest=n --build-ffmpeg-static=y --build-ffmpeg-shared=n --high-bitdepth=y $desired_ffmpeg_ver # high bitdepth

rm -rf sandbox/distros # free up space from any previous distros
if [[ $1 != "" ]]; then
  prettified_ver=v$1
fi

./patches/all_zip_distros.sh $prettified_ver
