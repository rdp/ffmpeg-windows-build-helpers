ffmpeg-windows-build-helpers
============================

This helper script lets you cross compile a windows 32 or 64 bit version of ffmpeg/mplayer/mp4box.exe, etc.
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
It should end up with a working static ffmpeg.exe within the sandbox directory.

It works with 32 or 64 bit (host) Linux, and can produce either/or 32 and 64 bit windows ffmpeg.exe's, with lots of dependencies built in. To build more than just FFmpeg, use command line parameters to the script.

OS X users, this may help: https://github.com/rdp/ffmpeg-windows-build-helpers/wiki/OS-X

Also NB that it has some command line parameters you can pass it, for instance to speed
up the building speed of gcc, building a shared build (.dll style) of FFmpeg, etc. 
Run it like 
./cross_compile_ffmpeg.sh -h 
to see all the various options available to you.

If you're using a "fresh" linux distro then the following command "might" install all the local dependencies you may need (if not, it will prompt you).
```sudo apt-get install subversion texinfo cmake bison flex cvs yasm automake libtool git g++ curl zlib1g-dev```


If you want to customize your FFmpeg final executable even more (remove features you don't need, etc.) then edit the script
1. Add or remove the "--enable-xxx" settings in the build_ffmpeg method (under config_options) near the bottom
2. Remove or add the # to the lines you're enabling or disabling in the build_dependencies() function
3. You can write custom functions for new features you want to integrate, make sure to add them to the build_dependencies() functions and also include the corresponding "--enable-xxx" settings to the build_ffmpeg() function under the config_options
4. There are some helper method do_XXX etc. for checking out code, running make, etc. that may be useful.

Also NB that you can also "cross compile" mp4box.exe if you pass in the appropriate command line parameter.

Also NB that you can also "cross compile" {mplayer,mencoder}.exe if you pass in the appropriate command line parameter too.

Also NB that you can also "cross compile" vlc.exe if you pass in the appropriate command line parameter too.

Also NB that you can optionally create a "somewhat more machine optimized builds" by modifying an appropriate --cflags parameter, like --cflags=-march=athlon64-sse2 or what not.  
So if you're cross compiling it on the box you'll end up targeting it for, you could build it like --cflags=-march=native to get a slightly faster executable [NB I haven't run any benchmarks to prove this yet, but it's possible...if you run any do let me know]
NB that if you have wine installed you may need to run this command first to disable it (if you are building for a different architecture than the building machine, especially), so that it doesn't auto run files like conftest.exe, etc. during the build (they will crash with an annoying popup prompt otherwise)
$ sudo update-binfmts --disable wine
ref: http://askubuntu.com/questions/344088/how-to-ensure-wine-does-not-auto-run-exe-files
NB that using a -march might not significantly improve speed [YMMV], ping me if you want even more aggressive optimization possibilities, I may be able to come up with a few more.

Feedback welcome roger-projects@googlegroups.com

Related projects:

vlc has its "contribs" building (cross compiling) system: https://wiki.videolan.org/Win32Compile/
mxe "m cross environment" https://github.com/mxe/mxe is for cross compiling many things.
https://github.com/qyot27/mpv/blob/extra-new/DOCS/crosscompile-mingw-tedious.txt lists lots of howto's

For building FFmpeg (for windows) in a more native windows environment these might help (though it might be slower as well unless):
https://github.com/jb-alvarado/media-autobuild_suite
https://github.com/svnpenn/a/blob/master/install-ffmpeg.sh (cygwin) http://ffmpeg.zeranoe.com/forum/viewtopic.php?f=19&t=1193&p=5006&hilit=svnpenn#p5006
ping me if you want this script ported to MSYS et al.

