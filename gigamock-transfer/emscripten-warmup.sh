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

echo '#include <stdio.h>' > /var/tmp/example.c
echo '#include <stdlib.h>' >> /var/tmp/example.c
echo '#include <limits.h>' >> /var/tmp/example.c
echo 'int main() {' >> /var/tmp/example.c
echo 'printf("hello, world %d!\n", PATH_MAX);' >> /var/tmp/example.c
echo 'return 0; }' >> /var/tmp/example.c

emcc -lm -s USE_ZLIB=1 -s WASM=1 -o /var/lib/wkndr/public/example.html /var/tmp/example.c
emcc -lm -s USE_ZLIB=1 -s WASM=1 -o /var/lib/wkndr/public/example-wasi.wasm /var/tmp/example.c
emcc -lm -s USE_ZLIB=1 -s WASM=1 -o /var/lib/wkndr/public/example-wasi.js /var/tmp/example.c
