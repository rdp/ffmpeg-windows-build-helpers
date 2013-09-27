set -x

cd sandbox/win32/ffmpeg_git
git_version=`git rev-parse HEAD`
echo "creating distro for $git_version"
cd ../../..
mkdir -p distros # -p so it doesn't warn
date=`date +%Y-%m-%d-%H%M`

file="distro-$date"
root="distros/$file"
rm -rf $root
mkdir -p $root

dir="$root/$file-ffmpeg-static"
mkdir $dir
if [ -f ./sandbox/win32/ffmpeg_git/ffmpeg.exe ]; then
  mkdir $dir/32-bit
fi
if [ -f ./sandbox/x86_64/ffmpeg_git/ffmpeg.exe ]; then
  mkdir $dir/64-bit
fi

cp ./sandbox/win32/ffmpeg_git/ffmpeg.exe "$dir/32-bit"
cp ./sandbox/win32/ffmpeg_git/ffplay.exe "$dir/32-bit"
cp ./sandbox/win32/ffmpeg_git/ffmpeg_g.exe "$dir/32-bit"

cp ./sandbox/x86_64/ffmpeg_git/ffmpeg.exe "$dir/64-bit"
cp ./sandbox/x86_64/ffmpeg_git/ffplay.exe "$dir/64-bit"
cp ./sandbox/x86_64/ffmpeg_git/ffmpeg_g.exe "$dir/64-bit"

dir="$root/$file-ffmpeg-shared"
mkdir $dir
mkdir $dir/32-bit
mkdir $dir/64-bit

cp ./sandbox/win32/ffmpeg_git_shared/ffmpeg.exe "$dir/32-bit"
cp ./sandbox/win32/ffmpeg_git_shared/ffplay.exe "$dir/32-bit"
cp ./sandbox/win32/ffmpeg_git_shared/ffmpeg_g.exe "$dir/32-bit"

cp ./sandbox/win32/ffmpeg_git_shared/*/*-*.dll     "$dir/32-bit"  # have to flatten it
./sandbox/mingw-w64-i686/bin/i686-w64-mingw32-strip $dir/32-bit/*.dll # XXX debug dll's?

cp ./sandbox/x86_64/ffmpeg_git_shared/ffmpeg.exe "$dir/64-bit"
cp ./sandbox/x86_64/ffmpeg_git_shared/ffplay.exe "$dir/64-bit"
cp ./sandbox/x86_64/ffmpeg_git_shared/ffmpeg_g.exe "$dir/64-bit"

cp ./sandbox/x86_64/ffmpeg_git_shared/*/*-*.dll     "$dir/64-bit"  # have to flatten it
./sandbox/mingw-w64-x86_64/bin/x86_64-w64-mingw32-strip $dir/64-bit/*.dll # XXX debug dll's?

cd distros
# -mx=1 fastest compression speed [but biggest file]
7zr -mx=1 a "$file.7z" "$file/*" || 7za a "$file.7z" "$file/*"  # some have a package with only 7za, see https://github.com/rdp/ffmpeg-windows-build-helpers/issues/16
cd ..

echo "created distros/$file.7z"
