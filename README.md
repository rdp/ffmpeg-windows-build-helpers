ffmpeg-windows-build-helpers
============================

This helper script lets you cross compile a windows 32 or 64 bit version of ffmpeg/mplayer/mp4box.exe, etc.
including many dependency libraries they use.
Note that I do offer custom builds, typically $200 ping me rogerdpack@gmail.com
and I'll do the work for you :) 

To run the script, either build in windows, or build in linux (cross compiles to build windows executables).
Building in linux takes less time overall, but requires a linux box or VM.
Building in windows takes "quite awhile" but avoids the need of needing linux installed somewhere.
I do have some "distro release builds" of running the script here: https://sourceforge.net/projects/ffmpegwindowsbi/files

To build in windows (uses the native'ish cygwin):

obtain repository: 
       download zip file, and unzip it: 
       
https://github.com/rdp/ffmpeg-windows-build-helpers/archive/master.zip
       
clone the repository: 

     c:\>git clone https://github.com/rdp/ffmpeg-windows-build-helpers.git
       
Next run one of the "native_build/build_locally_XXX.bat" file.
* build_locally_fdk_aac_and_x264_32bit_fast: Just libx264, fdk aac, and FFmpeg, and takes about 1 hour. Easiest way to get fdk aac, if you don't know which you want, use this one.
* build_locally_with_various_option_prompts: Has FFmpeg and many dependency libraries.  Prompts for whether you'd like to also include fdk/nvenc libraries, 32 and/or 64 bit executables.  Can take 6 hours or more.
* build_locally_gpl_32_bit_option: Same as option prompts above, but 32bit non-fdk auto selected.

  
Or second option: build it from linux as a cross compiler (much faster, takes 2 hours for the "options" build, requires a linux box or VM with linux guest running on a windows box):  In some type of Linux box (VM or native, or you could even create a VM temporarily, ex: digitalocean [1], [use it, then destroy your droplet]). Linux instructions:

    Download the script 
    git clone this repo:
    $ git clone https://github.com/rdp/ffmpeg-windows-build-helpers.git
    $ cd ffmpeg-windows-build-helpers

    Or do the following in a bash prompt instead of git clone:
    $ mkdir ffmpeg_build
    $ cd ffmpeg_build
    $ wget https://raw.github.com/rdp/ffmpeg-windows-build-helpers/master/cross_compile_ffmpeg.sh -O cross_compile_ffmpeg.sh
    $ chmod u+x cross_compile_ffmpeg.sh
    
    Now run the script:
    
    $ ./cross_compile_ffmpeg.sh

And answer the prompts.  
It should end up with a working static ffmpeg.exe within the "sandbox/*/ffmpeg_git" director(ies).

Another option instead of running ./cross_compile_ffmpeg.sh is to run 

    $ native_build/quick_cross_compile_ffmpeg_fdk_aac_and_x264_using_packaged_mingw64.sh script.

The "quick" part being the important part here, this one attempts to just uses your local distributions'
  mingw-w64 package for the cross compiler, thus speeding up compilation *dramatically*.

OS X users, follow instructions for linux above (it should "just work" no VM needed, using cross compiling).

Also NB that it has some other optional command line parameters you can pass it, for instance 
building a shared FFmpeg build (libavcodec-56.dll type distro), 
building mp4box/mplayer/vlc, 10 bit libx264, etc.
Run it like

./cross_compile_ffmpeg.sh -h 

to see all the various options available.

  For the long running builds, recommend start it, wait for it to give you prompts (if it does, it asks them as a bunch up front after installing cygwin) then  let it build overnight :)

Also NB that you can also "cross compile" mp4box.exe if you pass in the appropriate command line parameter.
Also NB that you can also "cross compile" {mplayer,mencoder}.exe if you pass in the appropriate command line parameter too.
Also NB that you can also "cross compile" vlc.exe if you pass in the appropriate command line parameter too [currently broken, ping if you want it to work again].
To enable Intel QSV (vista+ compatible only dependency so not enabled by default) use option --build-intel-qsv=y
There is also an LGPL command line option for those that want that.

If you want to customize your FFmpeg final executable even more (remove features you don't need, make a smaller build, or custom build, etc.) then edit the script
1. Add or remove the "--enable-xxx" settings in the build_ffmpeg method (under config_options) near the bottom of the script.  This can enable or disable parts of FFmpeg that you don't need, or want more, etc.

If you *really* want to customize it, you can add new dependencies:
1. You can write custom functions for new features you want to integrate, make sure to add them to the build_dependencies() functions and also include the corresponding "--enable-xxx" settings to the build_ffmpeg() function under the config_options
2. There are some helper method do_XXX etc. for checking out code, running make only once, etc. that may be useful.

Also NB that you can optionally create a "somewhat more machine optimized builds" by modifying an appropriate --cflags parameter, like 
--cflags='-march=athlon64-sse2 -O3' or what not. (march or mtune specified here, google them)
Sometimes they slow down the executable, sometimes speed them up.
One option you cannot use is --cflags=-march=native (the native--doesn't work cross compiling apparently)
To find an appropriate "native" flag for your local box, if you plan on running it only on that box, instead then run http://stackoverflow.com/a/24213278/32453 then manually specify that.

Unfortunately, after doing some benchmarking, it seems that modifying the CFLAGS this way (at least using libx264) doesn't end up helping much speed-wise (it might make a smaller executable?) since libx264 auto detects and auto uses your cpu capabilities anyway, so...until further research is done, these options may not actually provide significant speedup.  Ping me if you get different results than this, and you may be wasting your time using the --cflags= parameter here.

NB that this may contain slightly older/out of date dependency versions, so there may be a chance of security risk, though FFmpeg itself will be built from git master by default, with all the latest and greatest.

NB that if you have wine installed (in linux) you may need to run this command first to disable it (if you are building for a different -march=XX than the building machine, especially), so that it doesn't auto run files like conftest.exe, etc. during the build (they may crash with an annoying popup prompt otherwise)
$ sudo update-binfmts --disable wine
ref: http://askubuntu.com/questions/344088/how-to-ensure-wine-does-not-auto-run-exe-files
or if you get hangs (esp. during configure) see above ref

Feedback welcome roger-projects@googlegroups.com

Related projects (similar to this one...):
  https://github.com/jb-alvarado/media-autobuild_suite (native'ish windows using msys2)
  https://github.com/Warblefly/multimediaWin64 (native'ish windows using cygwin)
  there's also the "fast" option see above, within this project

Related projects (that do cross compiling with dependency libraries):

  vlc has a "contribs" building (cross compiling) system for its dependencies: https://wiki.videolan.org/Win32Compile/
    (NB this script has an option to compile VLC as well, though currently it makes huge .exe files :)
  mxe "m cross environment" https://github.com/mxe/mxe is a library for cross compiling many things, including FFmpeg I believe.

[1] if you use a 512MB RAM droplet, make sure to first add some extra swap space: https://www.digitalocean.com/community/tutorials/how-to-add-swap-on-ubuntu-14-04 before starting.  
Here's my digitalocean referral link in case you want it [you get $10 free credit] https://www.digitalocean.com/?refcode=b3030b559d17
