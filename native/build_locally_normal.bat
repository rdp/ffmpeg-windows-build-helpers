@rem call build_cygwin.bat

setlocal
@rem want wget etc. so override path. Probably need this anyway...
set PATH=%cd%\cygwin_install\bin;%PATH%

mkdir ffmpeg_build
cd ffmpeg_build

..\cygwin_install\bin\bash.exe -c "wget https://raw.github.com/rdp/ffmpeg-windows-build-helpers/master/cross_compile_ffmpeg.sh -O cross_compile_ffmpeg.sh"
..\cygwin_install\bin\bash.exe -c "chmod u+x ./cross_compile_ffmpeg.sh"
..\cygwin_install\bin\bash.exe -c "./cross_compile_ffmpeg.sh"

cd ..