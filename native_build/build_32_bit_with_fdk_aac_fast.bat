@ECHO OFF
ECHO Welcome to this FFmpeg compile script "fast version"
ECHO Starting cygwin install/update...

@rem use the same dir so it can be reused cygwin install :)

mkdir ffmpeg_local_builds\cygwin_local_install
@rem cd to it so that cygwin install logs etc. go there
cd ffmpeg_local_builds\cygwin_local_install
ECHO downloading cygwin setup executable...
@powershell -command "$clnt = new-object System.Net.WebClient; $clnt.DownloadFile(\"https://cygwin.com/setup-x86.exe\", \"setup-x86.exe\")"

@rem forced to hard select a mirror here apparently...
start /min /wait setup-x86.exe ^
--quiet-mode ^
--no-admin ^
--no-startmenu ^
--no-shortcuts ^
--no-desktop ^
--site http://mirrors.xmission.com/cygwin/ ^
--root %cd% ^
--packages ^
yasm,automake,gcc-core,git,make,pkg-config,mingw64-i686-gcc-g++,mingw64-i686-gcc-core

echo "done installing cygwin"

cd ..\..

setlocal
set PATH=%cd%\ffmpeg_local_builds\cygwin_local_install\bin;%PATH%

cd ffmpeg_local_builds

.\cygwin_local_install\bin\bash.exe -c "wget https://raw.github.com/rdp/ffmpeg-windows-build-helpers/master/cross_compile_ffmpeg.sh -O cross_compile_ffmpeg.sh"
.\cygwin_local_install\bin\bash.exe -c "chmod u+x ./cross_compile_ffmpeg.sh"
.\cygwin_local_install\bin\bash.exe -c "./cross_compile_ffmpeg.sh %1 %2 %3"




ECHO done with local build...check output above to see if successfull..