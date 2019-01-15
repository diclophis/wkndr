# layer 0 is vim-static bin
FROM static-vim-dockerfile:latest

# layer 1 is linux-box stuff
FROM ubuntu:bionic-20180526

ENV LC_ALL C.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV DEBIAN_FRONTEND noninteractive
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_RUN_DIR /var/run/apache2

USER root

#TODO: build openssl certs on client-side
COPY gigamock-transfer/openssl.conf /etc/ssl/private/openssl.conf

COPY gigamock-transfer/bootstrap.sh /var/tmp/bootstrap.sh

RUN /var/tmp/bootstrap.sh

COPY gigamock-transfer/apache.conf /etc/apache2/sites-available/000-default.conf
COPY gigamock-transfer/nginx-apt-proxy.conf /etc/nginx/conf.d/
COPY gigamock-transfer/git-repo-template /usr/share/git-core/templates/
COPY gigamock-transfer/etc-docker-registry-config.yaml /etc/docker/registry/config.yml

COPY Gemfile Gemfile.lock wkndr.gemspec /var/lib/wkndr/

RUN cd /var/lib/wkndr && ls -l && bundle

COPY --from=0 /var/tmp/build/vim-src/src/vim /var/lib/vim-static

COPY gigamock-transfer/emscripten.sh /var/tmp/emscripten.sh
RUN /var/tmp/emscripten.sh

COPY gigamock-transfer/emscripten-warmup.sh /var/tmp/emscripten-warmup.sh
RUN /var/tmp/emscripten-warmup.sh

COPY config /var/lib/wkndr/config

RUN cd /var/lib/wkndr && ls -l && \
    git init && \
    git submodule add https://github.com/mruby/mruby mruby \
    git submodule init && \
    git submodule update

COPY raylib-src /var/lib/wkndr/raylib-src

RUN mkdir -p /var/tmp/chroot/bin
RUN cp /var/lib/vim-static /var/tmp/chroot/bin/vi
RUN cp /bin/bash-static /var/tmp/chroot/bin/sh

COPY Makefile gigamock-transfer/iterate-server.sh gigamock-transfer/iterate-web.sh /var/lib/wkndr/
RUN /var/lib/wkndr/iterate-server.sh mruby/bin/mrbc
RUN /var/lib/wkndr/iterate-server.sh release/libraylib.a
RUN /var/lib/wkndr/iterate-web.sh cheese
RUN /var/lib/wkndr/iterate-web.sh release/libraylib.bc

COPY main.c /var/lib/wkndr/
COPY lib /var/lib/wkndr/lib
RUN /var/lib/wkndr/iterate-server.sh

RUN /var/lib/wkndr/iterate-web.sh

COPY Wkndrfile /var/lib/wkndr/

COPY public/index.html /var/lib/wkndr/public/index.html
COPY public/index.js /var/lib/wkndr/public/index.js
COPY public/xterm-dist /var/lib/wkndr/public/xterm-dist
RUN cd /var/lib/wkndr && ls -hl release && cp release/wkndr* public/

COPY Thorfile gigamock-transfer/Procfile.init /var/lib/wkndr/

RUN ln -fs /var/lib/wkndr/Thorfile /usr/bin/wkndr && wkndr help

WORKDIR /var/lib/wkndr

CMD ["/var/lib/wkndr/release/wkndr.mruby", "server", "/var/lib/wkndr/public"]
#CMD ["bash"]
#CMD ["sleep", "infinity"]
