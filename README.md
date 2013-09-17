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

Also NB that you can also "cross compile" mp4box.exe (32 and 64 bit versions) if you pass in the appropriate command line parameter.

Also NB that you can also "cross compile" {mplayer,mencoder}.exe (32 and 64 bit versions) if you pass in the appropriate command line parameter too.

Also NB that you can also "cross compile" vlc.exe if you pass in the appropriate command line parameter too.

Also NB that you can create "optimized builds" by modifying the --cflags parameter, like --cflags=-march=athlon64-sse2 or what not.

Feedback welcome roger-projects@googlegroups.com

Related projects:

vlc has its "contribs" building (cross compiling) system: https://wiki.videolan.org/Win32Compile/
mxe "m cross environment" https://github.com/mxe/mxe is for cross compiling many things.

