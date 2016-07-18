rm -rf sandbox/distros # free up space

# git pulls synchronized
for dir in sandbox/*/ffmpeg_git*; do
  cd $dir
  git pull
  rm already*
  cd ../../.. 
done

./cross_compile_ffmpeg.sh --compiler-flavors=multi --disable-nonfree=y --git-get-latest=n # static
./cross_compile_ffmpeg.sh --compiler-flavors=multi --disable-nonfree=y --git-get-latest=n --build-intel-qsv=n # windows xp
./cross_compile_ffmpeg.sh --compiler-flavors=multi --disable-nonfree=y --high-bitdepth=n --git-get-latest=y # high bit depth

./patches/collect.sh
touch ./sandbox/distros/readme.txt
echo "created readme file"
echo "now upload them!"
