#!/bin/sh

set -e

cd /root/emsdk
. ./emsdk_env.sh

cd /var/lib/wkndr
#make clean

cd /var/lib/wkndr
emmake make TARGET=emsc
