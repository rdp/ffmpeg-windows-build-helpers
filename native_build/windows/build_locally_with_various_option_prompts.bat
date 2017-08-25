@ECHO off
ECHO Welcome to this FFmpeg compile script.
ECHO This process will first install a local copy of Cygwin to a new directory "ffmpeg_local_builds".
ECHO Then it will prompt you for some options like 32 bit vs. 64 bit, free vs. non free dependencies.
ECHO It will then build the GCC cross compiler, followed by FFmpeg dependencies and FFmpeg itself.
ECHO There are also even *more* option available than what you'll be prompted for.
ECHO If you want more advanced options after the first pass, it will give instructions when done
ECHO on how to run it again with more advanced options.
ECHO.
ECHO Starting Cygwin install/update.
ECHO.
SETLOCAL ENABLEDELAYEDEXPANSION
IF NOT EXIST ffmpeg_local_builds\cygwin_local_install (
	MKDIR ffmpeg_local_builds\cygwin_local_install
	REM cd to it so that Cygwin install, logs, etc. go there
	CD ffmpeg_local_builds\cygwin_local_install
	ECHO Downloading Cygwin setup executable.
	ECHO Keep an eye on this window for error warning messages from the Cygwin install. Some of them are expected.
	REM setup exe name either setup-x86_64.exe or setup-x86.exe 64 bit "blew up" uname unrecognized on libflite/libtheora or something <sigh>
	FOR /F "tokens=4,5 delims=[.XP " %%A IN ('VER') DO (
		IF %%A.%%B==5.1 (
			powershell -command "$clnt = new-object System.Net.WebClient; $clnt.DownloadFile(\"http://cygwin-xp.portfolis.net/setup/setup-x86.exe\", \"setup-x86.exe\")"
			REM forced to hard select a mirror here apparently...
			START /wait setup-x86.exe ^
			-X ^
			--quiet-mode ^
			--no-admin ^
			--no-startmenu ^
			--no-shortcuts ^
			--no-desktop ^
			--site http://cygwin-xp.portfolis.net/cygwin ^
			--root !cd! ^
			--packages ^
			ed,curl,libcurl4,wget,subversion,texinfo,gcc-g++,bison,flex,cvs,yasm,automake,libtool,autoconf,gcc-core,cmake,git,make,pkg-config,zlib1g-dev,mercurial,unzip,pax,ncurses,patch,gettext-devel,nasm,p7zip,gperf
		) ELSE (
			powershell -command "$clnt = new-object System.Net.WebClient; $clnt.DownloadFile(\"https://www.cygwin.com/setup-x86.exe\", \"setup-x86.exe\")"
			START /wait setup-x86.exe ^
			--quiet-mode ^
			--no-admin ^
			--no-startmenu ^
			--no-shortcuts ^
			--no-desktop ^
			--site http://mirrors.xmission.com/cygwin/ ^
			--root !cd! ^
			--packages ^
			ed,curl,libcurl4,wget,subversion,texinfo,gcc-g++,bison,flex,cvs,yasm,automake,libtool,autoconf,gcc-core,cmake,git,make,pkg-config,zlib1g-dev,mercurial,unzip,pax,ncurses,patch,gettext-devel,nasm,p7zip,gperf
		)
	)
	REM wget for the initial script download as well as zeranoe's uses it
	REM curl is used in our script all over
	REM libcurl4 is apparently required so that updating curl doesn't bwork it, reported as a bug to cygwin :|
	REM ncurses for the "clear" command yikes!
	REM gettext-dev is for 64 bit cygwin which doesn't install it but binutils links against it and needs it...
	ECHO Done installing Cygwin.
	CD ..\..
) ELSE (
	ECHO Cygwin already installed.
)
ECHO.
REM want wget etc. so override path here by prepending. Probably need/want to do this anyway...
REM   since we're messing with the PATH
SET PATH=%cd%\ffmpeg_local_builds\cygwin_local_install\bin;%PATH%

CD ffmpeg_local_builds

IF NOT EXIST cross_compile_ffmpeg.sh (
	.\cygwin_local_install\bin\bash.exe -c "cp ../../cross_compile_ffmpeg.sh ."
)

ECHO.
.\cygwin_local_install\bin\bash.exe -c "./cross_compile_ffmpeg.sh %1 %2 %3 %4 %5 %6 %7 %8 %9"

CD ..
ENDLOCAL
ECHO.
ECHO Done with local build. Check output above to see if successfull.
ECHO If not successful, then you could try to rerun the script. It "should" pick up where it left off.
ECHO.
ECHO If you want more advanced configuration (like building mplayer or mp4box, 10-bit, etc.), then open '%cd%\ffmpeg_local_builds\cygwin_local_install\cygwin.bat' (which sets up the path for you). Then cd to '%cd%\ffmpeg_local_builds' and run the script manually yourself with -h, like:
ECHO $ cd /cygdrive/c/.../ffmpeg_local_builds
ECHO $ ./cross_compile_ffmpeg.sh -h
PAUSE
