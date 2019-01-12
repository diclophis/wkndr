#!/bin/sh

set -e
set -x

apt-get update \
  && apt-get upgrade --no-install-recommends -y \
  && apt-get install --no-install-recommends -y \
       locales ruby2.5 rake git \
       build-essential make \
       python2.7 nodejs cmake \
       default-jre \
       bison \
       libssl-dev \
       bash-static \
       automake build-essential libtool curl bison libxcursor-dev libxrandr-dev libxinerama-dev libxi-dev xinit openbox \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

update-alternatives --install /usr/bin/python python /usr/bin/python2.7 10

gem install rack
