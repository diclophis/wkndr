#!/bin/bash

set -e
set -x

cd /var/lib/wkndr

make -j ${1}
