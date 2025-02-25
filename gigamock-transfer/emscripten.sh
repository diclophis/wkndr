#!/bin/sh

set -e
set -x

cd /root

git clone https://github.com/emscripten-core/emsdk.git

cd emsdk

./emsdk update || git pull

./emsdk list

./emsdk install --shallow --override-repository sdk-main-64bit@https://github.com/diclophis/emscripten/tree/main-with-custom-keytrap sdk-main-64bit
