#!/bin/bash

set -e
set -x

cd /var/lib/wkndr

make -j ${1}

rm -Rf release/*.o release/*.h
ls -l release
