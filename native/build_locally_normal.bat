call build_cygwin.bat

mkdir cygwin_ffmpeg_build
cd cygwin_ffmpeg_build

..\cygwin_install\bin\bash.exe -c "curl https://raw.github.com/rdp/ffmpeg-windows-build-helpers/master/cross_compile_ffmpeg.sh -O"



@rem cd ..