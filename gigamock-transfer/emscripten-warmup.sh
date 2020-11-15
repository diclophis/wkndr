#!/bin/bash

set -e
set -x

cd /root/emsdk

./emsdk list

#./emsdk activate sdk-1.38.36-64bit

./emsdk install latest
./emsdk activate latest

#./emsdk activate 1.39.19

. ./emsdk_env.sh

echo '#include <stdio.h>' > /var/tmp/emscripten.c
echo '#include <stdlib.h>' >> /var/tmp/emscripten.c
echo '#include <limits.h>' >> /var/tmp/emscripten.c
echo 'int main() {' >> /var/tmp/emscripten.c
echo 'printf("hello, world %d!\n", PATH_MAX);' >> /var/tmp/emscripten.c
echo 'return 0; }' >> /var/tmp/emscripten.c

emcc -lm -o /var/tmp/emscripten.html /var/tmp/emscripten.c
