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
subversion,texinfo,g++,bison,flex,cvs,yasm,automake,libtool,autoconf,gcc,cmake,git,make,pkg-config,zlib1g-dev,mercurial,unzip,pax

echo "done installing cygwin"

@rem TODO run the script LOL

cd .. 