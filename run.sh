#!/usr/bin/env bash

read -p '##################### Welcome ######################
First we will download and compile a gcc cross-compiler (MinGW-w64).
You will be prompted with a few questions as it installs.
Enter to continue:'

wget http://zeranoe.com/scripts/mingw_w64_build/mingw-w64-build-3.0.6
chmod u+x mingw-w64-build-3.0.6
./mingw-w64-build-3.0.6

