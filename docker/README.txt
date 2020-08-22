run 
$ sudo apt install docker.io
$ sudo ./do-docker-build.sh 

to do an fdk "full non redistributable" ffmpeg build inside the docker instance, then it copies the ffmpeg.exe's to your local dir, and optionally destroys the docker instance, depending on how you have do-docker-build.sh setup near the bottom.

you can customize it as desired, see local files
