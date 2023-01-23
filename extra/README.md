# ffmpeg windows cross compile helper extra script

* This is Patch for Windows WSL Ubuntu
* FFmpeg 4.4.3 for Windows 64-bit with FDK-AAC(--disable-nonfree=n, --build-ffmpeg-static=y)
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
git clone https://github.com/FREEWING-JP/ffmpeg-windows-build-helpers
cd ffmpeg-windows-build-helpers

# Windows 11 WLS Ubuntu
bash ./extra/make.sh

or

# Windows 10 WLS Ubuntu
bash ./extra/make_win10.sh

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

# for more details visit following URL  
http://www.neko.ne.jp/~freewing/software/windows_compile_ffmpeg_enable_fdk_aac/

