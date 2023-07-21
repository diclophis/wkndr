#!/bin/sh

set -e
set -x

export LC_ALL=C.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export DEBIAN_FRONTEND=noninteractive

apt-get update \
  && apt-get upgrade --no-install-recommends -y \
  && apt-get install --no-install-recommends -y \
       git ca-certificates automake autotools-dev build-essential cmake libtool rake make libssl-dev zlib1g-dev libuv1 libuv1-dev libx11-dev libxrandr-dev libxi-dev xorg-dev libgles-dev libgles1 libgles2 libgbm-dev libgbm1 \
       bash-static \
       busybox-static \
       clang clang-tools \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

update-ca-certificates --fresh

mkdir -p /var/lib/wkndr/public
