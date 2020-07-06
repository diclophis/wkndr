#!/bin/sh

set -e
set -x

       #locales ruby2.7 rake git \
       #build-essential make \
       #zlib1g-dev \
       #python2.7 nodejs cmake \
       #default-jre \
       #bison \
       #libssl-dev \
       #bash-static \
       #busybox-static \
       #rungetty \
       #automake build-essential libtool curl bison libxcursor-dev libxrandr-dev libxinerama-dev libxi-dev xinit openbox \
       #curl \
       #vim vim-common vim-runtime vim-tiny \
       #nginx \
       #libglfw3-dev \
       #jq \
       #strace \
       #htop \
       #ruby-bundler rake ruby2.5-dev build-essential make \
       #libcap2-bin \
       #sudo apt install libasound2-dev mesa-common-dev libx11-dev libxrandr-dev libxi-dev xorg-dev libgl1-mesa-dev libglu1-mesa-dev

apt-get update \
  && apt-get upgrade --no-install-recommends -y \
  && apt-get install --no-install-recommends -y \
       locales git ca-certificates automake build-essential cmake make python3 rake ruby2.7 libssl-dev zlib1g-dev libuv1 libuv1-dev libx11-dev libxrandr-dev libxi-dev xorg-dev \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

locale-gen --purge en_US.UTF-8 && /bin/echo -e  "LANG=$LANG\nLANGUAGE=$LANGUAGE\n" | tee /etc/default/locale \
  && locale-gen $LANGUAGE \
  && dpkg-reconfigure locales

update-alternatives --install /usr/bin/python python /usr/bin/python3 10

#gem install rack
#gem update --no-document --system
#gem install --no-document thor
#gem list

update-ca-certificates --fresh

#curl -fsSL -o /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v1.9.3/bin/linux/amd64/kubectl && \
#     echo "81eb30e62a12d6e0527a6a3c2a9501b56d65777bf66684739b16a0afe826c8f8  /usr/local/bin/kubectl" | sha256sum -c && \
#     chmod +x /usr/local/bin/kubectl

#NOTE: https://registry.npmjs.org/xterm/-/xterm-3.10.0.tgz ??? download and install at docker build time????
