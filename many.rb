dec26 = "C:\\downloads\\ffmpeg-git-f514695-win32-static\\ffmpeg-git-f514695-win32-static"
dec22 =  "C:\\downloads\\ffmpeg-git-dd1fb65-win32-static\\ffmpeg-git-dd1fb65-win32-static"
seven26 = "c:\\downloads\\ffmpeg-20120726-git-236ecc3-win32-shared\\ffmpeg-20120726-git-236ecc3-win32-shared"
jan5 = "C:\\downloads\\ffmpeg-git-7f83db3-win32-static\\ffmpeg-git-7f83db3-win32-static"
aug4 = "C:\\downloads\\ffmpeg-20120804-git-f857465-win32-static\\ffmpeg-20120804-git-f857465-win32-static"

c = "#{aug4}\\bin\\ffmpeg.exe -threads 6 -y -i sintel.mpg -pass 1 -t 75 -c:v libx264 -an nul.mp4"

times = []
loop { 
start = Time.now
system(c)
elapsed = Time.now - start
times <<elapsed
p times.sort, times.length, elapsed, c
#sleep 1
}