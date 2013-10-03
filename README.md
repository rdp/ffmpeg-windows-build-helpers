ffmpeg-windows-build-helpers
============================

This helper script lets you cross compile a windows 32 or 64 bit version of ffmpeg/mplayer/mp4box.exe,
including many dependency libraries they use.

To run the script:

In a Linux box (VM or native):

download the script (git clone the repo, run it, or do the following in a bash window) $

```bash
wget https://raw.github.com/rdp/ffmpeg-windows-build-helpers/master/cross_compile_ffmpeg.sh -O cross_compile_ffmpeg.sh
chmod u+x cross_compile_ffmpeg.sh
./cross_compile_ffmpeg.sh
```

And follow the prompts.
It works with 32 or 64 bit (hoost) Linux, and can produce either/or 32 and 64 bit windows ffmpeg.exe's

See also 
http://github.com/rdp/ffmpeg-windows-build-helpers/wiki for more tips, including being able to build it more quickly!

OS X users, this may help: https://github.com/rdp/ffmpeg-windows-build-helpers/wiki/OS-X

Also NB that it has some command line parameters you can pass it, for instance to speed
up the building speed of gcc, build shared, etc. run it with 
./cross_compile_ffmpeg.sh -h 
to see them all

If you want to customize your FFmpeg final executable even more (remove features you don't need, etc.) then edit the script and tweak the "--enable" settings in the build_ffmpeg method near the buttom.  Ping me if this doesn't make sense.

Also NB that you can also "cross compile" mp4box.exe if you pass in the appropriate command line parameter.

Also NB that you can also "cross compile" {mplayer,mencoder}.exe if you pass in the appropriate command line parameter too.

Also NB that you can also "cross compile" vlc.exe if you pass in the appropriate command line parameter too.

Also NB that you can optionally create a "somewhat more machine optimized builds" by modifying an appropriate --cflags parameter, like --cflags=-march=athlon64-sse2 or what not.  
So if you're cross compiling it on the box you'll end up targeting it for, you could build it like --cflags=-march=native to get a slightly faster executable [NB I haven't run any benchmarks to prove this yet, but it's possible...if you run any do let me know]
NB that if you have wine installed you may need to run this command first to disable it (if you are building for a different architecture than the building machine, especially), so that it doesn't auto run files like conftest.exe, etc. during the build (they will crash with an annoying popup prompt otherwise)
$ sudo update-binfmts --disable wine
ref: http://askubuntu.com/questions/344088/how-to-ensure-wine-does-not-auto-run-exe-files

Feedback welcome roger-projects@googlegroups.com

Related projects:

vlc has its "contribs" building (cross compiling) system: https://wiki.videolan.org/Win32Compile/
mxe "m cross environment" https://github.com/mxe/mxe is for cross compiling many things.

