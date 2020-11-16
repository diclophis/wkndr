#!/bin/sh

set -e

cd /root/emsdk
. ./emsdk_env.sh

cd /var/lib/wkndr
#make clean

cd /var/lib/wkndr/raylib/src
RAYLIB_RELEASE_PATH=../../release make PLATFORM=PLATFORM_WEB -B -e

cd /var/lib/wkndr/mruby
MRUBY_CONFIG=../config/emscripten.rb make

cd /var/lib/wkndr
emmake make TARGET=emsc
