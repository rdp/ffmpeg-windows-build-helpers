wscript download.vbs https://cygwin.com/setup-x86.exe

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
autossh,^