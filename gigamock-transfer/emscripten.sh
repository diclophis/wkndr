#!/bin/sh

set -e
set -x

cd /root

git clone https://github.com/juj/emsdk.git

cd emsdk

./emsdk update || git pull

./emsdk list

./emsdk install latest
