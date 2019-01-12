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

./emsdk install latest
