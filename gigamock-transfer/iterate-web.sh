#!/bin/bash

set -e
set -x

####

cd /root/emsdk

. ./emsdk_env.sh

cd /var/lib/wkndr

emmake make TARGET=emsc -j4 ${1}

ls -lh release

if [ "${1}" = "" ];
then
  mkdir -p public
  cp release/wkndr* public/
fi
