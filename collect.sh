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
mkdir $dir/32-bit
mkdir $dir/64-bit

cp ./sandbox/win32/ffmpeg_git/ffmpeg.exe "$dir/32-bit"
cp ./sandbox/win32/ffmpeg_git/ffmpeg_g.exe "$dir/32-bit"
cp ./sandbox/win32/ffmpeg_git/*/*.dll     "$dir/32-bit"
./sandbox/mingw-w64-i686/bin/i686-w64-mingw32-strip $dir/32-bit/*.dll

cp ./sandbox/x86_64/ffmpeg_git/ffmpeg.exe "$dir/64-bit/ffmpeg.exe"
cp ./sandbox/x86_64/ffmpeg_git/ffmpeg_g.exe "$dir/64-bit"
cp ./sandbox/x86_64/ffmpeg_git/*/*.dll     "$dir/64-bit"
./sandbox/mingw-w64-i686/bin/i686-w64-mingw32-strip $dir/64-bit/*.dll

cd distros
7zr a "$file.7z" "$file/*"
cd ..

echo "created distros/$file"
