#!/bin/bash

set -e
set -x

cd /root/emsdk

./emsdk activate latest

. ./emsdk_env.sh

echo '#include <stdio.h>' > /var/tmp/emscripten.c
echo 'int main() {' >> /var/tmp/emscripten.c
echo 'printf("hello, world!\n");' >> /var/tmp/emscripten.c
echo 'return 0; }' >> /var/tmp/emscripten.c

emcc -o /var/tmp/emscripten.html /var/tmp/emscripten.c
