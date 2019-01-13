#!/bin/bash

set -e
set -x

####

cd /root/emsdk

. ./emsdk_env.sh

cd /var/lib/wkndr

rm -Rf release/*.o release/*.h
emmake make TARGET=emsc -j
