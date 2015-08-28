ECHO running cygwin install
mkdir %cd%\cygwin_install
@rem cd to it so that cygwin install logs etc. go there
cd %cd%\cygwin_install

ECHO downloading cygwin setup exe...
wscript ..\download.vbs

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
@rem todo just use curl, remove wget here [and in main readme] :)

echo "done installing cygwin"

@rem TODO run the script LOL

cd .. 

setlocal
@rem want wget etc. so override path. Probably need this anyway...
set PATH=%cd%\cygwin_install\bin;%PATH%

mkdir ffmpeg_build
cd ffmpeg_build

..\cygwin_install\bin\bash.exe -c "wget https://raw.github.com/rdp/ffmpeg-windows-build-helpers/master/cross_compile_ffmpeg.sh -O cross_compile_ffmpeg.sh"
..\cygwin_install\bin\bash.exe -c "chmod u+x ./cross_compile_ffmpeg.sh"
..\cygwin_install\bin\bash.exe -c "./cross_compile_ffmpeg.sh"

cd ..

ECHO "done with local build..."

pause