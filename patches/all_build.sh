# can pass param like "n3.1.1"

if [[ $1 != "" ]]; then
  $1="--ffmpeg-git-checkout-version=$1"
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
./cross_compile_ffmpeg.sh --compiler-flavors=multi --disable-nonfree=y --git-get-latest=n --build-ffmpeg-shared=y $1 && # normal static and shared
./cross_compile_ffmpeg.sh --compiler-flavors=multi --disable-nonfree=y --git-get-latest=n --build-intel-qsv=n $1 && # windows xp static
./cross_compile_ffmpeg.sh --compiler-flavors=multi --disable-nonfree=y --git-get-latest=y --high-bitdepth=y $1 # high bit depth static

rm -rf sandbox/distros # free up space from previous distros
./patches/all_zip_distros.sh $1
