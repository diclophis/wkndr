#!/bin/bash

set -e
set -x

polly build Dockerfile

docker run --rm wkndr:latest /bin/busybox tar -czf - public | tar zxvf -

docker run --rm -p 8000:8000 wkndr:latest 
