#!/bin/bash

set -e
set -x

####

cd /root/emsdk

. ./emsdk_env.sh

cd /var/lib/wkndr

emmake make TARGET=emsc -j ${1}

ls -l release
