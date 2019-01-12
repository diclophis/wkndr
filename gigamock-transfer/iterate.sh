#!/bin/bash

set -e
set -x

####

cd /root/emsdk

. ./emsdk_env.sh

cd /var/lib/wkndr


make -f Makefile clean
make -j

#emmake make -f Makefile.emscripten
