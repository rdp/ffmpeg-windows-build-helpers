cd builds/win32/ffmpeg_git
git_version=`git rev-parse HEAD`
echo $git_version
cd ../../..
mkdir -p distros
date=`date +%Y-%m-%d`
file="ffmpeg-distro-static-$date-$git_version"
dir="distros/$file"
rm -rf $dir
mkdir $dir
cp ./builds/win32/ffmpeg_git/ffmpeg.exe "$dir/ffmpeg-32.exe"
#cp ./builds/win32/ffmpeg_git/avconv.exe "$dir/avconv-32.exe"
#cp ./builds/win32/ffmpeg_git/ffplay.exe "$dir/ffplay-32.exe"
#cp ./builds/win32/ffmpeg_git/ffmpeg_g.exe "$dir/ffmpeg-32_g.exe"
cp ./builds/x86_64/ffmpeg_git/ffmpeg.exe "$dir/ffmpeg-x86_64.exe"
#cp ./builds/x86_64/ffmpeg_git/ffmpeg_g.exe "$dir/ffmpeg-x86_64_g.exe"
cd distros
7zr a "$file.7z" "$file/*"
cd ..

