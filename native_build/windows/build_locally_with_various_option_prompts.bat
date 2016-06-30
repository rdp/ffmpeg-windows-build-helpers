@ECHO OFF
ECHO Welcome to this FFmpeg compile script.
ECHO this process will first install a local copy of cygwin to a new directory "ffmpeg_local_builds"
ECHO then it will prompt you for some options like 32 bit vs. 64 bit, free vs. non free dependencies
ECHO and then it will build the gcc cross compiler, then some FFmpeg dependencies, and finally, FFmpeg.
ECHO there are also even *more* option available than what you'll be prompted for.
ECHO if you want more advanced options, after the first pass, it will give instructions when done
ECHO on how to run it again with more advanced options.
ECHO
ECHO Starting cygwin install/update...
ECHO
mkdir ffmpeg_local_builds\cygwin_local_install
@rem cd to it so that cygwin install logs etc. go there
cd ffmpeg_local_builds\cygwin_local_install
ECHO Downloading cygwin setup executable...some error warning messages are expected from the cygwin install...
@rem setup exe name either setup-x86_64.exe or setup-x86.exe 64 bit "blew up" on libtheora or something <sigh>
@powershell -command "$clnt = new-object System.Net.WebClient; $clnt.DownloadFile(\"https://www.cygwin.com/setup-x86.exe\", \"setup-x86.exe\")"

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
ed,curl,wget,subversion,texinfo,gcc-g++,bison,flex,cvs,yasm,automake,libtool,autoconf,gcc-core,cmake,git,make,pkg-config,zlib1g-dev,mercurial,unzip,pax,ncurses,patch,gettext-devel,nasm
@rem wget for the initial script download as well as zeranoe's uses it
@rem curl is used in our script all over
@rem ncurses for the "clear" command yikes!
@rem gettext-dev is for 64 bit cygwin which doesn't install it but binutils links against it and needs it...

echo "done installing cygwin"

cd ..\..

@rem want wget etc. so override path here by prepending. Probably need/want to do this anyway...
@rem since we're messing with the PATH
setlocal
set PATH=%cd%\ffmpeg_local_builds\cygwin_local_install\bin;%PATH%

cd ffmpeg_local_builds

.\cygwin_local_install\bin\bash.exe -c "wget https://raw.github.com/rdp/ffmpeg-windows-build-helpers/master/cross_compile_ffmpeg.sh -O cross_compile_ffmpeg.sh"
.\cygwin_local_install\bin\bash.exe -c "chmod u+x ./cross_compile_ffmpeg.sh"
.\cygwin_local_install\bin\bash.exe -c "./cross_compile_ffmpeg.sh %1 %2 %3 %4 %5 %6 %7 %8 %9 %10 %11 %12 %13 %14 %15 %16 %17"

cd ..

ECHO done with local build...check output above to see if successfull..
ECHO if not successful you might try re running the script, it "should" pick up where it left off.
ECHO.
ECHO if you want more advanced configuration (like building mplayer or mp4box, 10-bit, etc) 
ECHO open %cd%\ffmpeg_local_builds\cygwin_local_install\cygwin.bat
ECHO (which sets up the path for you)
ECHO then cd to %cd%\ffmpeg_local_builds and run the script manually yourself with -h
echo like $ cd /cygdrive/c/.../ffmpeg_local_builds $ ./cross_compile_ffmpeg.sh -h
pause
