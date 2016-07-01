./cross_compile_ffmpeg.sh --compiler-flavors=multi --disable-nonfree=y --git-get-latest=y
./cross_compile_ffmpeg.sh --compiler-flavors=multi --disable-nonfree=y --high-bitdepth=y --git-get-latest=y
./patches/all_build.sh
echo "now upload them!"
