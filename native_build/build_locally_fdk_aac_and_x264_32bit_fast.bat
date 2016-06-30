@ECHO OFF
ECHO Welcome to this FFmpeg compile script "fast version"
ECHO Starting cygwin install/update...

@rem use the same dir so it can be reused cygwin install :)

mkdir ffmpeg_local_builds\cygwin_local_install_fast
@rem cd to it so that cygwin install logs etc. go there
cd ffmpeg_local_builds\cygwin_local_install_fast
ECHO Downloading local cygwin setup executable...some error logs are expected...
@powershell -command "$clnt = new-object System.Net.WebClient; $clnt.DownloadFile(\"https://cygwin.com/setup-x86_64.exe\", \"setup-x86_64.exe\")"

@rem forced to hard select a mirror here apparently...
start /min /wait setup-x86_64.exe ^
--quiet-mode ^
--no-admin ^
--no-startmenu ^
--no-shortcuts ^
--no-desktop ^
--site http://mirrors.xmission.com/cygwin/ ^
--root %cd% ^
--packages ^
wget,yasm,git,make,pkg-config,mingw64-i686-gcc-g++,mingw64-i686-gcc-core,libtool,autoconf,automake
@rem no curl required here seemingly, though it still might be being installed by some other dependency [?]

echo "done installing cygwin"

cd ..\..

setlocal
set PATH=%cd%\ffmpeg_local_builds\cygwin_local_install_fast\bin;%PATH%

cd ffmpeg_local_builds

.\cygwin_local_install_fast\bin\bash.exe -c "wget https://raw.github.com/rdp/ffmpeg-windows-build-helpers/master/quick_cross_compile_ffmpeg_fdk_aac_and_x264_using_packaged_mingw64.sh -O quick_cross_compile_ffmpeg_fdk_aac_and_x264_using_packaged_mingw64.sh"
.\cygwin_local_install_fast\bin\bash.exe -c "chmod u+x ./quick_cross_compile_ffmpeg_fdk_aac_and_x264_using_packaged_mingw64.sh"
.\cygwin_local_install_fast\bin\bash.exe -c ./quick_cross_compile_ffmpeg_fdk_aac_and_x264_using_packaged_mingw64.sh

ECHO done with local build...check output above to see if successfull...
pause
