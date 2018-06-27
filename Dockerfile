FROM ubuntu:bionic-20180526

ENV DEBIAN_FRONTEND noninteractive
ENV LC_ALL C.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

USER root

RUN apt-get update \
    && apt-get upgrade --no-install-recommends -y \
    && apt-get install --no-install-recommends -y \
      locales ruby2.5 rake git \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN locale-gen --purge en_US.UTF-8 && /bin/echo -e  "LANG=$LANG\nLANGUAGE=$LANGUAGE\n" | tee /etc/default/locale \
    && locale-gen $LANGUAGE \
    && dpkg-reconfigure locales

RUN gem update --no-document --system
RUN gem install --no-document thor
RUN gem list
