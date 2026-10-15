#!/usr/bin/env bash

cd /mnt/Data/Apps 
# Directory where RPCS3 will be installed

rm -f rpcs3.AppImage 
# Remove the previous verison

wget --content-disposition https://rpcs3.net/latest-appimage 
# Download the latest version

mv rpcs3-*_linux64.AppImage rpcs3.AppImage
# Rename the file for ease of use

chmod a+x rpcs3.AppImage
# Make the program executable

kill -9 $PPID
# Kill the terminal
