cd sandbox/win32/ffmpeg_git
git_version=`git rev-parse HEAD`
echo $git_version
cd ../../..
mkdir -p distros
date=`date +%Y-%m-%d`
file="ffmpeg-distro-static-$date-$git_version"
dir="distros/$file"
rm -rf $dir
mkdir $dir
mkdir $dir/32
#mkdir $dir/64
cp ./sandbox/win32/ffmpeg_git/ffmpeg.exe "$dir/32/ffmpeg.exe"
cp ./sandbox/win32/ffmpeg_git/*/*.dll     "$dir/32"
./sandbox/mingw-w64-i686/bin/i686-w64-mingw32-strip $dir/32/*.dll
#cp ./sandbox/win32/ffmpeg_git/ffplay.exe "$dir/32/ffplay.exe"
#cp ./sandbox/win32/ffmpeg_git/ffmpeg_g.exe "$dir/32/ffmpeg_g.exe"
#cp ./sandbox/x86_64/ffmpeg_git/ffmpeg.exe "$dir/64/ffmpeg.exe"
#cp ./sandbox/win32/ffmpeg_git/*/*.dll     "$dir/64"
#cp ./sandbox/x86_64/ffmpeg_git/ffmpeg_g.exe "$dir/64/ffmpeg_g.exe"
cd distros
7zr a "$file.7z" "$file/*"
cd ..

