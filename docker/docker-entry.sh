#!/bin/bash
set -e

OUTPUTDIR=/output

./cross_compile_ffmpeg.sh --build-ffmpeg-shared=y --build-ffmpeg-static=y --disable-nonfree=n --build-intel-qsv=y --compiler-flavors=win64 --enable-gpl=y --high-bitdepth=n

mkdir -p $OUTPUTDIR/static/bin
cp -R -f ./sandbox/win64/ffmpeg_git_with_fdk_aac/ffmpeg.exe $OUTPUTDIR/static/bin
cp -R -f ./sandbox/win64/ffmpeg_git_with_fdk_aac/ffprobe.exe $OUTPUTDIR/static/bin
cp -R -f ./sandbox/win64/ffmpeg_git_with_fdk_aac/ffplay.exe $OUTPUTDIR/static/bin

mkdir -p $OUTPUTDIR/shared
cp -R -f ./sandbox/win64/ffmpeg_git_with_fdk_aac_shared/bin/ $OUTPUTDIR/shared