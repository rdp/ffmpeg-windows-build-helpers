ECHO downloading cygwin setup exe...
wscript download.vbs

ECHO running cygwin install

setup-x86.exe ^
--quiet-mode ^
--no-admin ^
--no-startmenu ^
--no-desktop ^
--root .\cygwin_root ^
--packages ^
curl,^
atool,^
autoconf,^
automake,^
autossh