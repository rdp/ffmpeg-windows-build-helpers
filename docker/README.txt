This is the "docker" way to build ffmpeg.
Docker basically copies down a "known supported" version of linux, and does the build within that "docker."

to do it, run 
$ sudo apt install docker.io
# on WSL do  Docker Desktop for Windows. instead, apparently?  You can't use the above, anyway...
$ sudo ./do-docker-build.sh 

it creates an fdk "full non redistributable" ffmpeg build inside the docker instance, then it copies the ffmpeg.exe's to your local dir, and optionally destroys the docker instance, depending on how you have do-docker-build.sh setup near the bottom.

you can customize it as desired, please peruse all local files here for details...
