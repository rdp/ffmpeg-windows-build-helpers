### Building FFmpeg in Docker

To avoid breaking your current Linux system and to avoid conflicts of libraries, it is convenient to build them in Docker container.

Examples:

`docker build -t ffmpeg:cpu cpu` 

`docker build -t ffmpeg:gpu gpu` 
