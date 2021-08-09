#!/bin/bash

set -e
set -x

# dd if=/dev/urandom of=/var/tmp/big.data bs=1M count=1; rm debug; wget --debug http://localhost:8081/debug; shasum debug big.data
polly build Dockerfile

docker run --rm wkndr:latest /bin/busybox tar -czf - public | tar zxvf -

#docker run --rm -p 8000:8000 wkndr:latest 
