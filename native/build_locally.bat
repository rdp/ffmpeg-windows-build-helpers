ECHO downloading cygwin setup exe...
wscript download.vbs

ECHO running cygwin install
mkdir %cd%\cygwin_install
@rem cd to it so that cygwin install logs go there
cd %cd%\cygwin_install

setup-x86.exe ^
--quiet-mode ^
--no-admin ^
--no-startmenu ^
--no-shortcuts ^
--no-desktop ^
--site http://mirrors.xmission.com/cygwin/ ^
--root %cd% ^
--packages ^
curl,^
atool,^
autoconf,^
automake,^
autossh

@rem TODO more

echo "done installing cygwin"

@rem TODO run the script LOL