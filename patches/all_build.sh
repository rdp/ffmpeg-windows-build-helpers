# can pass param like --ffmpeg-git-checkout-version=release/3.1.1
rm -rf sandbox/distros # free up space

# git pulls synchronized
for dir in sandbox/*/ffmpeg_git*; do
  cd $dir
  git pull
  rm already*
  cd ../../.. 
done

# all are 32 and 64 bit
./cross_compile_ffmpeg.sh --compiler-flavors=multi --disable-nonfree=y --git-get-latest=n --build-ffmpeg-shared=y $1 # normal static and shared
./cross_compile_ffmpeg.sh --compiler-flavors=multi --disable-nonfree=y --git-get-latest=n --build-intel-qsv=n $1 # windows xp static
./cross_compile_ffmpeg.sh --compiler-flavors=multi --disable-nonfree=y --high-bitdepth=n --git-get-latest=y $1 # high bit depth static

./patches/collect.sh
touch ./sandbox/distros/readme.txt
echo "created readme file"
echo "now upload them!"

