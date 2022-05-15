#!/bin/sh

set -e
set -x

apt-get update \
  && apt-get upgrade --no-install-recommends -y \
  && apt-get install --no-install-recommends -y \
       locales git ca-certificates automake autotools-dev build-essential cmake libtool make python3 rake ruby2.7 libssl-dev zlib1g-dev libuv1 libuv1-dev libx11-dev libxrandr-dev libxi-dev xorg-dev \
       bash-static \
       busybox-static \
       clang clang-10 clang-tools-10 \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

locale-gen --purge en_US.UTF-8 && /bin/echo -e  "LANG=$LANG\nLANGUAGE=$LANGUAGE\n" | tee /etc/default/locale \
  && locale-gen $LANGUAGE \
  && dpkg-reconfigure locales

update-alternatives --install /usr/bin/python python /usr/bin/python3 10

update-ca-certificates --fresh

mkdir -p /var/lib/wkndr/public
