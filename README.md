ffmpeg-windows-build-helpers
============================

This helper script lets you cross compile a windows-based 32 or 64-bit version of ffmpeg/mplayer/mp4box.exe, etc,  including their dependencies and libraries that they use.
Note that I do offer custom builds, typically $200. Ping me at rogerdpack@gmail.com and I'll do the work for you :) 

The script allows the user to either build on Windows via cygwin (as documented below), or on a Linux host (which uses cross compiles to build windows binaries).
Building on linux takes less time overall. On Windows 10, you can use the bash shell (provided that you've installed the Windows Subsystem for Linux as explained [here](http://www.howtogeek.com/249966/how-to-install-and-use-the-linux-bash-shell-on-windows-10/).
Building in windows takes considerably longer but avoids the need of deploying a  Linux installation for the same purpose.
I do have some "distribution release builds" of running the script here: https://sourceforge.net/projects/ffmpegwindowsbi/files

** Windows Cmd  **

To build in windows without a VM (uses the native'ish cygwin):

Obtain the repository by downloading and unzipping the archive below: 
       
https://github.com/rdp/ffmpeg-windows-build-helpers/archive/master.zip
       
Or, if you have git installed, clone the repository instead of downloading the zip, ex: 

     c:\>git clone https://github.com/rdp/ffmpeg-windows-build-helpers.git
       
Next run one of the "`native_build/build_locally_XXX.bat`" file.
* `build_locally_fdk_aac_and_x264_32bit_fast`: This will build libx264, fdk aac, and FFmpeg, and takes about 1 hour. This is the easiest way to get fdk aac, if you don't know which you want, use this one.
* `build_locally_with_various_option_prompts`: This will build FFmpeg and extra dependencies and  libraries.  It will prompt whether you'd like to also include fdk/nvenc libraries, 32 and/or 64 bit executables, etc.  This build will take 6 hours or more.
* `build_locally_gpl_32_bit_option`: Same as option prompts above, but selects 32bit non-fdk automatically.

**Cross-compiling from a Linux environment:**
  
You can build the project on Linux with a cross compiler toolchain, and this process is much faster, taking about 2 hours for the "options" build. Deploy a Linux VM on the host with a hypervisor of your choice, or natively on an extra computer or a dual boot system, and also, you could even create a VM temporarily, on a hosting provider such as Digital Ocean. 

NB: works with Ubuntu distros that uses gcc 5.x but not 6.x (yet) (i.e. 16.10 it will not work yet).

Download the script by cloning this repository via git:

    $ git clone https://github.com/rdp/ffmpeg-windows-build-helpers.git
    $ cd ffmpeg-windows-build-helpers

 Now run the script:
    
    $ ./cross_compile_ffmpeg.sh

Answer the prompts.
It should end up with a working, statically-built ffmpeg.exe binary within the "`sandbox/*/ffmpeg_git`" director(ies).

Another option instead of running `./cross_compile_ffmpeg.sh` is to run 

    $ native_build/quick_cross_compile_ffmpeg_fdk_aac_and_x264_using_packaged_mingw64.sh script.

Note the "quick" part here which attempts to use the locally installed `mingw-w64` package from your distribution for the cross compiler, thus skipping the time-intensive cross-compiler toolchain build step.  It's not as well tested as running the normal one, however, which builds gcc from scratch.

For Mac OSX users, simply follow the instructions for Linux above.

To view additional arguments and options supported by the script, run:

    ./cross_compile_ffmpeg.sh -h 

to see all the various options available.

 For long running builds, do run them overnight as they take a while.

Also note that you can also "cross compile" mp4box, mplayer,mencoder and vlc binaries if you pass in the appropriate command line parameters.
The VLC build is currently broken, send a PM if you'd want it fixed.

To enable Intel QuickSync encoders (supported on Windows vista and above), which is optional,  pass the  option `--build-intel-qsv=y` to the cross-compilation script above.
There is also an LGPL command line option for those that want that.

If you want to customize your FFmpeg final executable even further ( to remove features you don't need, make a smaller build, or custom build, etc.) then edit the script.
1. Add or remove the "`--enable-xxx`" settings in the `build_ffmpeg` function (under `config_options`) near the bottom of the script.  This can enable or disable parts of FFmpeg to suit your requirements.

You may also add new dependencies and libraries to the project as shown:
1. You can write custom functions for new features you want to integrate. Make sure to add them to the `build_dependencies()` functions and also include the corresponding "`--enable-xxx`" parameter switches to the `build_ffmpeg()` function under the `config_options`.
2. There are some helper methods (quoted under `do_XXX` clauses. for checking out code, running make only once, etc. that may be useful.

Note that you can optionally create a machine-optimized build by passing additional arguments to the  `--cflags` parameter, such as  --cflags='-march=athlon64-sse2 -O3' , as inferred by [mtune](https://gcc.gnu.org/onlinedocs/gcc-4.5.3/gcc/i386-and-x86_002d64-Options.html). Google mtune options for references to this. A good reference can be found on [Gentoo's wiki](https://wiki.gentoo.org/wiki/GCC_optimization).
Take precautions not to use excessive flags without understanding their impact on performance.

One option you cannot use is `--cflags=-march=native` (the native flag doesn't work in cross compiler environments).
To find an appropriate "native" flag for your local box, do as illustrated here:

On the target machine,run:

    % gcc -march=native -Q --help=target | grep march
    -march=                               core-avx-i

Then use the output shown (in this case, `core-avx-i`, corresponding to Intel's Sandy-bridge micro-architecture) on the build machine:

    % gcc -march=core-avx-i ...

Benchmarks prove that modifying the CFLAGS this way (at least using libx264) doesn't end up helping much speed-wise (it might make a smaller executable?) since libx264 auto detects and auto uses your cpu capabilities anyway, so until further research is done, these options may not actually provide significant speedup.  Ping me if you get different results than this, as you may be wasting your time using the `--cflags=` parameter here.

Note that the build scripts fetch stable sources (not mainline) which may contain slightly older/out of date dependency versions, and as such, there may be implied security risks (see CVEs that may not be patched downstream), though FFmpeg itself will be built from git master by default.

Note that if you have wine installed (in linux) you may need to run this command first to disable it (if you are building for a different `-march=XX` than the building machine, especially), so that it doesn't auto run files like `conftest.exe`, etc. during the build (they may crash with an annoying popup prompt otherwise)

    $ sudo update-binfmts --disable wine

See [this reference](http://askubuntu.com/questions/344088/how-to-ensure-wine-does-not-auto-run-exe-files) on the issue highlighted above. Failure to apply the workaround will most likely result in hangs (especially during the configure stage) as highlighted in the reference above.

Feedback is welcome, send an email to roger-projects@googlegroups.com

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


