#!/bin/bash

# dd if=/dev/urandom of=/var/tmp/big.data bs=1M count=1; rm debug; wget --debug http://localhost:8081/debug; shasum debug big.data

docker run --rm -it -p 8000:8000 wkndr:latest 

