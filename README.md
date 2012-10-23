ffmpeg-windows-build-helpers
============================

This helper script lets you compile locally a windows 32 bit version of ffmpeg.exe,
including various dependency libraries.

To run the script:

In a Linux box (VM or native):

Make sure you have the following installed:
git gcc autoconf libtool automake patch svn
for ubuntu, you could install it like:
$ sudo apt-get install git subversion gcc autoconf libtool automake patch

now download the script (git clone the repo, run it, or do the following in a bash window) $

```bash
wget https://raw.github.com/rdp/ffmpeg-windows-build-helpers/master/cross_compile_ffmpeg.sh -O cross_compile_ffmpeg.sh
chmod u+x cross_compile_ffmpeg.sh
./cross_compile_ffmpeg.sh
```

And follow the prompts.
It works with 32 or 64 bit Linux.

See also 
http://github.com/rdp/ffmpeg-windows-build-helpers/wiki for more tips, including being able to build it more quickly  !
Feedback welcome roger-projects@googlegroups.com
