@ECHO OFF
ECHO this process will first install a local copy of cygwin
ECHO then it will prompt you for some options like 32 bit vs. 64 bit, free vs. non free dependencies
ECHO and then it will build the cross compiler and finally FFmpeg.
ECHO if you want more advanced options, after the first pass, it will give you more instructions when done.
ECHO continuing with a normal FFmpeg build...
pause

ECHO running cygwin install...
mkdir %cd%\cygwin_local_install
@rem cd to it so that cygwin install logs etc. go there
cd %cd%\cygwin_local_install

ECHO downloading cygwin setup executable...
@powershell -command "$clnt = new-object System.Net.WebClient; $clnt.DownloadFile(\"https://cygwin.com/setup-x86.exe\", \"setup-x86.exe\")"

@rem forced to hard select a mirror here apparently...
setup-x86.exe ^
--quiet-mode ^
--no-admin ^
--no-startmenu ^
--no-shortcuts ^
--no-desktop ^
--site http://mirrors.xmission.com/cygwin/ ^
--root %cd% ^
--packages ^
ed,wget,subversion,texinfo,gcc-g++,bison,flex,cvs,yasm,automake,libtool,autoconf,gcc-core,cmake,git,make,pkg-config,zlib1g-dev,mercurial,unzip,pax
@rem XXXX just use curl, could remove wget here [and in main readme] :)

echo "done installing cygwin"

cd .. 

setlocal
@rem want wget etc. so override path. Probably need this regardless...
set PATH=%cd%\cygwin_local_install\bin;%PATH%

mkdir ffmpeg_local_builds
cd ffmpeg_local_builds

..\cygwin_local_install\bin\bash.exe -c "wget https://raw.github.com/rdp/ffmpeg-windows-build-helpers/master/cross_compile_ffmpeg.sh -O cross_compile_ffmpeg.sh"
..\cygwin_local_install\bin\bash.exe -c "chmod u+x ./cross_compile_ffmpeg.sh"
..\cygwin_local_install\bin\bash.exe -c "./cross_compile_ffmpeg.sh"

cd ..

ECHO "done with local build...check logs above to see if success"
ECHO if you want more advanced configuration (like building mplayer or mp4box) 
ECHO open cmd, add cygwin bin to to beginning of PATH env. variable like
ECHO set PATH=%cd%\cygwin_local_install\bin;%%PATH%%
ECHO "then run bash.exe, and cd to %cd%\ffmpeg_local_builds and run the script manually yourself."
pause