#!/bin/sh

set -e

cd /root/emsdk
. ./emsdk_env.sh

cd /var/lib/wkndr
find release -name "*.o" -delete && \
find release -name "*.h" -delete && \
find release -name "*.a" -delete && \
emmake make TARGET=emsc
