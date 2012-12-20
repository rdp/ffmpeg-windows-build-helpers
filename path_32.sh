# add the 32 bit gcc to your path so you can use it elsewhere
# run this like $ . pathr_32.sh

  me=`dirname $0`
  me=`readlink -f $me`
  cur_dir="$me/sandbox"
  echo $cur_dir
  export PATH="$cur_dir/mingw-w64-i686/bin:$PATH"
  export PKG_CONFIG_PATH="$cur_dir/mingw-w64-i686/i686-w64-mingw32/lib/pkgconfig"
  echo cross_prefix="$cur_dir/mingw-w64-i686/bin/i686-w64-mingw32-"

