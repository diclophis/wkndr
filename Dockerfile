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
COPY --from=0 /var/tmp/build/vim-src/runtime /var/lib/vim-runtime

COPY gigamock-transfer/emscripten.sh /var/tmp/emscripten.sh
RUN /var/tmp/emscripten.sh

COPY gigamock-transfer/emscripten-warmup.sh /var/tmp/emscripten-warmup.sh
RUN /var/tmp/emscripten-warmup.sh

COPY config /var/lib/wkndr/config

RUN cd /var/lib/wkndr && ls -l && \
    git init && \
    git submodule add https://github.com/mruby/mruby mruby \
    git submodule init && \
    git submodule update && \
    cd mruby && \
    git fetch && \
    git checkout cb3ee2d0501612f406e2d44b1e6d55b18861b1e1

COPY Makefile gigamock-transfer/iterate-server.sh gigamock-transfer/iterate-web.sh /var/lib/wkndr/
COPY gigamock-transfer/mkstatic-mruby-module.rb /var/lib/wkndr/gigamock-transfer/mkstatic-mruby-module.rb
RUN /var/lib/wkndr/iterate-server.sh mruby/bin/mrbc

RUN /var/lib/wkndr/iterate-web.sh build-mruby

COPY raylib-src /var/lib/wkndr/raylib-src
RUN /var/lib/wkndr/iterate-server.sh release/libraylib.a
RUN /var/lib/wkndr/iterate-web.sh release/libraylib.bc

COPY main.c /var/lib/wkndr/
COPY lib /var/lib/wkndr/lib
COPY gigamock-transfer/static /var/lib/wkndr/gigamock-transfer/static
RUN /var/lib/wkndr/iterate-server.sh

COPY resources /var/lib/wkndr/resources
RUN /var/lib/wkndr/iterate-web.sh

COPY Wkndrfile /var/lib/wkndr/

#COPY public/index.html /var/lib/wkndr/public/index.html
#COPY public/index.js /var/lib/wkndr/public/index.js
#COPY public/xterm-dist /var/lib/wkndr/public/xterm-dist

RUN setcap cap_sys_chroot+ep /usr/sbin/chroot 

RUN mkdir -p /var/tmp/chroot/bin /var/tmp/chroot/usr/share /var/tmp/chroot/etc/skel /var/tmp/chroot/home /var/tmp/chroot/usr/share/vim
COPY gigamock-transfer/home-dir-template /var/tmp/chroot/etc/skel
COPY gigamock-transfer/wkndr-chroot.sh /var/tmp
RUN cp -R /var/lib/vim-runtime /var/tmp/chroot/usr/share/vim/runtime
RUN cp /var/lib/vim-static /var/tmp/chroot/bin/vim
RUN cp /bin/bash-static /var/tmp/chroot/bin/bash
RUN cd /var/tmp/chroot/bin && ln -s bash sh
RUN cp /bin/busybox /var/tmp/chroot/bin/busybox && \
    for I in ls mkdir which; do cd /var/tmp/chroot/bin && ln -s busybox ${I}; done
#RUN mkdir -p /var/tmp/chroot/usr/bin /var/tmp/chroot/sbin /var/tmp/chroot/usr/sbin
#RUN chroot /var/tmp/chroot /bin/busybox --install -s

#-rwxr-xr-x 1 root root 1220 Apr  9  2018 00-header
COPY gigamock-transfer/iterate-motd.sh /var/lib/wkndr/iterate-motd.sh
RUN rm /etc/legal /etc/update-motd.d/* && mv /var/lib/wkndr/iterate-motd.sh /etc/update-motd.d/00-wkndr
COPY gigamock-transfer/issue /etc/issue

COPY Thorfile gigamock-transfer/Procfile.init /var/lib/wkndr/
RUN ln -fs /var/lib/wkndr/Thorfile /usr/bin/wkndr && wkndr help

WORKDIR /var/lib/wkndr

CMD ["/var/lib/wkndr/release/wkndr.mruby", "server", "/var/lib/wkndr/public"]
#CMD ["bash"]
#CMD ["sleep", "infinity"]
