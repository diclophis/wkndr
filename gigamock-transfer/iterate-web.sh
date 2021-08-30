#!/bin/bash

set -e
set -x

####

cd /root/emsdk

. ./emsdk_env.sh

cd /var/lib/wkndr

emmake make TARGET=emsc ${1}

ls -lh release

if [ "${1}" = "" ];
then
  cp release/wkndr.{js,wasm,data} public/
fi
