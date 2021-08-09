#!/bin/sh

set -e
set -x

cd /root

if ! (test -e emsdk && git --git-dir=emsdk/.git status)
then
  git clone https://github.com/juj/emsdk.git
fi

cd emsdk

./emsdk update || git pull

./emsdk list

#TODO: fix this upgrade
#./emsdk install 1.40.0

#./emsdk install 1.39.19
./emsdk install latest

#1.39.0
#latest
#emscripten-1.38.36
#./emsdk install emscripten-1.38.36
#./emsdk install sdk-master-64bit
#./emsdk install latest sdk-1.38.36-64bit
