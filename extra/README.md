# ffmpeg windows cross compile helper extra script

* 2023/10/15 FFmpeg 4.4.4

* This is Patch for Windows WSL Ubuntu
* FFmpeg 4.4.4 for Windows 64-bit with FDK-AAC(--disable-nonfree=n, --build-ffmpeg-static=y)
* disable Tesseract OCR function

* Environment

|  Windows | WSL Linux | Result |
| ---- | ---- | ---- |
| Windows 11 | Ubuntu 22.04 | **OK** (Recommend) |
| Windows 11 | Ubuntu 20.04 | **OK** |
| Windows 11 | Debian 11.6 | Your own risk |
| Windows 10 | Ubuntu 20.04 | **OK** (Recommend) |
| Windows 10 | Debian 9.5 | NG |
| Windows | Other | Not Tested |

# How to use
1) Enable WSL and Install Ubuntu via Windows Command-Line  
```
wsl --install
 or
wsl --install -d Ubuntu
```
2) Type following to Build FFmpeg automatically  
```
cd
git clone https://github.com/rdp/ffmpeg-windows-build-helpers
cd ffmpeg-windows-build-helpers

# Windows 11 WLS Ubuntu
./extra/make.sh

or

# Windows 10 WLS Ubuntu
./extra/make_win10.sh

* FFmpeg is Win64 (64-bit only).
  Edit ./extra/build.sh if you want the 32-bit version .
```
3) Wait a few hours  
Take about 1 to few hours depending on machine specs  

|  CPU | WSL Linux | Build Time |
| ---- | ---- | ---- |
| Ryzen 5 PRO 3400GE | Windows 11 WSL Ubuntu 22.04 | 90 min |
| Ryzen 5 PRO 3400GE | Windows 11 WSL Ubuntu 20.04 | 75 min |
| Ryzen 7 PRO 4750G | Windows 10 WSL Ubuntu 20.04 | 111 min |
| Core i5-8259U | Windows 10 WSL Ubuntu 20.04 | 172 min |

# for more details visit following URL  
http://www.neko.ne.jp/~freewing/software/windows_compile_ffmpeg_enable_fdk_aac/

# 2023/10/15 FFmpeg 4.4.4 ffmpeg.exe -version
```
ffmpeg.exe -version
ffmpeg version n4.4.4-ffmpeg-windows-build-helpers Copyright (c) 2000-2023 the FFmpeg developers
built with gcc 10.2.0 (GCC)
configuration: --pkg-config=pkg-config --pkg-config-flags=--static --extra-version=ffmpeg-windows-build-helpers --enable-version3 --disable-debug --disable-w32threads --arch=x86_64 --target-os=mingw32 --cross-prefix=/home/user/ffmpeg-windows-build-helpers/sandbox/cross_compilers/mingw-w64-x86_64/bin/x86_64-w64-mingw32- --enable-libcaca --enable-gray --enable-fontconfig --enable-gmp --enable-libass --enable-libbluray --enable-libbs2b --enable-libflite --enable-libfreetype --enable-libfribidi --enable-libgme --enable-libgsm --enable-libilbc --enable-libmodplug --enable-libmp3lame --enable-libopencore-amrnb --enable-libopencore-amrwb --enable-libopus --enable-libsnappy --enable-libsoxr --enable-libspeex --enable-libtheora --enable-libtwolame --enable-libvo-amrwbenc --enable-libvorbis --enable-libwebp --enable-libzimg --enable-libzvbi --enable-libmysofa --enable-libopenjpeg --enable-libopenh264 --enable-libvmaf --enable-libsrt --enable-libxml2 --enable-opengl --enable-libdav1d --enable-cuda-llvm --enable-gnutls --enable-libsvtav1 --enable-libvpx --enable-libaom --enable-nvenc --enable-nvdec --extra-libs=-lharfbuzz --extra-libs=-lm --extra-libs=-lshlwapi --extra-libs=-lmpg123 --extra-libs=-lpthread --extra-cflags=-DLIBTWOLAME_STATIC --extra-cflags=-DMODPLUG_STATIC --extra-cflags=-DCACA_STATIC --enable-amf --enable-libmfx --enable-gpl --enable-frei0r --enable-librubberband --enable-libvidstab --enable-libx264 --enable-libx265 --enable-avisynth --enable-libaribb24 --enable-libxvid --enable-libdavs2 --enable-libxavs2 --enable-libxavs --extra-cflags='-mtune=generic' --extra-cflags=-O3 --enable-static --disable-shared --prefix=/home/user/ffmpeg-windows-build-helpers/sandbox/cross_compilers/mingw-w64-x86_64/x86_64-w64-mingw32 --disable-libdav1d --enable-nonfree --enable-libfdk-aac --enable-decklink
libavutil      56. 70.100 / 56. 70.100
libavcodec     58.134.100 / 58.134.100
libavformat    58. 76.100 / 58. 76.100
libavdevice    58. 13.100 / 58. 13.100
libavfilter     7.110.100 /  7.110.100
libswscale      5.  9.100 /  5.  9.100
libswresample   3.  9.100 /  3.  9.100
libpostproc    55.  9.100 / 55.  9.100
```

