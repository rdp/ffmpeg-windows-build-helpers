@ECHO OFF
ECHO Welcome to this FFmpeg compile script.
ECHO this process will first install a local copy of cygwin
ECHO then it will prompt you for some options like 32 bit vs. 64 bit, free vs. non free dependencies
ECHO and then it will build the cross compiler and finally FFmpeg.
ECHO there are also even *more* option available than what you'll be prompted for.
ECHO if you want more advanced options, after the first pass, it will give you more instructions when done.
ECHO
ECHO Starting cygwin install/update...
mkdir ffmpeg_local_builds\cygwin_local_install
@rem cd to it so that cygwin install logs etc. go there
cd ffmpeg_local_builds\cygwin_local_install
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
ed,wget,subversion,texinfo,gcc-g++,bison,flex,cvs,yasm,automake,libtool,autoconf,gcc-core,cmake,git,make,pkg-config,zlib1g-dev,mercurial,unzip,pax,ncurses
@rem XXXX just use curl, could remove wget here [and in main readme] :)
@ncurses for the "clear" command yikes!

echo "done installing cygwin"

cd ..\..

@rem want wget etc. so override path here by prepending. Probably need/want to do this anyway...
@rem since we're messing with the PATH
setlocal
set PATH=%cd%\ffmpeg_local_builds\cygwin_local_install\bin;%PATH%

cd ffmpeg_local_builds

.\cygwin_local_install\bin\bash.exe -c "wget https://raw.github.com/rdp/ffmpeg-windows-build-helpers/master/cross_compile_ffmpeg.sh -O cross_compile_ffmpeg.sh"
.\cygwin_local_install\bin\bash.exe -c "chmod u+x ./cross_compile_ffmpeg.sh"
.\cygwin_local_install\bin\bash.exe -c "./cross_compile_ffmpeg.sh %1 %2 %3"

cd ..

ECHO done with local build...check output above to see if successfull..
ECHO.
ECHO if you want more advanced configuration (like building mplayer or mp4box, 10-bit, etc) 
ECHO open cmd, add cygwin bin to to beginning of PATH env. variable like
ECHO set PATH=%cd%\ffmpeg_local_builds\cygwin_local_install\bin;%%PATH%%
ECHO then run bash.exe, next cd to %cd%\ffmpeg_local_builds and run the script manually yourself.
echo like $ ./cross_compile_ffmpeg.sh
pause
