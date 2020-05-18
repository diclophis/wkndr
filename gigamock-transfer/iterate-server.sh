#!/bin/bash

set -e
set -x

cd /var/lib/wkndr

make ${1}

#rm -Rf release/*.o release/*.h
find release -name "*.o" -delete
find release -name "*.h" -delete
ls -l release

#cp -R mruby/{build,build-copy}
