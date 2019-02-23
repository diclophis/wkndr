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

./emsdk install emscripten-1.38.27
#./emsdk install sdk-master-64bit
./emsdk install sdk-1.38.27-64bit
