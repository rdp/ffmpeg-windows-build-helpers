cd builds/win32/ffmpeg_git
git_version=`git rev-parse HEAD`
echo $git_version
cd ../../..
mkdir -p distros
date=`date +%Y-%m-%d`
dir="distros/ffmpeg-distro-static-$date-$git_version"
mkdir "$dir"
cp ./builds/win32/ffmpeg_git/ffmpeg.exe "$dir/ffmpeg-32.exe"
cp ./builds/x86_64/ffmpeg_git/ffmpeg.exe "$dir/ffmpeg-x86_64.exe"
7zr a "$dir.7z" "$dir/*"
