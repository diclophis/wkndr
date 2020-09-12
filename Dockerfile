## layer 0 is vim-static bin
#FROM static-vim-dockerfile:latest

# layer 1 is linux-box stuff
FROM ubuntu:focal-20200606 as wkndr

ENV LC_ALL C.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV DEBIAN_FRONTEND noninteractive

USER root

COPY gigamock-transfer/bootstrap.sh /var/tmp/bootstrap.sh

RUN /var/tmp/bootstrap.sh

#COPY --from=0 /var/tmp/build/vim-src/src/vim /var/lib/vim-static
#COPY --from=0 /var/tmp/build/vim-src/runtime /var/lib/vim-runtime

COPY gigamock-transfer/emscripten.sh /var/tmp/emscripten.sh
RUN /var/tmp/emscripten.sh

COPY gigamock-transfer/emscripten-warmup.sh /var/tmp/emscripten-warmup.sh
RUN /var/tmp/emscripten-warmup.sh

COPY config /var/lib/wkndr/config
COPY rlgl.h.patch /var/lib/wkndr/

RUN cd /var/lib/wkndr && ls -l && \
    git init && \
    git submodule add https://github.com/mruby/mruby mruby \
    git submodule init && \
    git submodule update && \
    cd mruby && \
    git fetch && \
    git checkout 612e5d6aad7f224008735d57b19e5a81556cfd31

RUN cd /var/lib/wkndr && ls -l && \
    git init && \
    git submodule add https://github.com/raysan5/raylib raylib \
    git submodule init && \
    git submodule update && \
    cd raylib && \
    git fetch && \
    git checkout 00fda3be650ade80f1492105c2107a4ace6bc575 && \
    cat ../rlgl.h.patch | git apply

COPY Makefile gigamock-transfer/iterate-server.sh gigamock-transfer/iterate-web.sh /var/lib/wkndr/
COPY gigamock-transfer/mkstatic-mruby-module.rb /var/lib/wkndr/gigamock-transfer/mkstatic-mruby-module.rb

RUN /var/lib/wkndr/iterate-server.sh clean

RUN /var/lib/wkndr/iterate-server.sh mruby/bin/mrbc

RUN /var/lib/wkndr/iterate-web.sh build-mruby

#COPY raylib-src /var/lib/wkndr/raylib-src
#RUN /var/lib/wkndr/iterate-server.sh release/libraylib.a
#RUN /var/lib/wkndr/iterate-web.sh release/libraylib.bc

COPY main.c /var/lib/wkndr/
COPY src /var/lib/wkndr/src
COPY include /var/lib/wkndr/include
COPY lib /var/lib/wkndr/lib
COPY gigamock-transfer/static /var/lib/wkndr/gigamock-transfer/static

RUN /var/lib/wkndr/iterate-server.sh

COPY resources /var/lib/wkndr/resources
RUN /var/lib/wkndr/iterate-web.sh

COPY Wkndrfile /var/lib/wkndr/

#COPY public/index.html /var/lib/wkndr/public/index.html
##COPY public/index.js /var/lib/wkndr/public/index.js
##COPY public/xterm-dist /var/lib/wkndr/public/xterm-dist
#
#RUN setcap cap_sys_chroot+ep /usr/sbin/chroot 
#
#RUN mkdir -p /var/tmp/chroot/bin /var/tmp/chroot/usr/share /var/tmp/chroot/etc/skel /var/tmp/chroot/home /var/tmp/chroot/usr/share/vim
#COPY gigamock-transfer/home-dir-template /var/tmp/chroot/etc/skel
#COPY gigamock-transfer/wkndr-chroot.sh /var/tmp
#RUN cp -R /var/lib/vim-runtime /var/tmp/chroot/usr/share/vim/runtime
#RUN cp /var/lib/vim-static /var/tmp/chroot/bin/vim
#RUN cp /bin/bash-static /var/tmp/chroot/bin/bash
#RUN cd /var/tmp/chroot/bin && ln -s bash sh
#RUN cp /bin/busybox /var/tmp/chroot/bin/busybox && \
#    for I in ls mkdir which; do cd /var/tmp/chroot/bin && ln -s busybox ${I}; done
##RUN mkdir -p /var/tmp/chroot/usr/bin /var/tmp/chroot/sbin /var/tmp/chroot/usr/sbin
##RUN chroot /var/tmp/chroot /bin/busybox --install -s
#
##-rwxr-xr-x 1 root root 1220 Apr  9  2018 00-header
#COPY gigamock-transfer/iterate-motd.sh /var/lib/wkndr/iterate-motd.sh
#RUN rm /etc/legal /etc/update-motd.d/* && mv /var/lib/wkndr/iterate-motd.sh /etc/update-motd.d/00-wkndr
#COPY gigamock-transfer/issue /etc/issue
#
#COPY gigamock-transfer/exgetty.rb /var/lib/wkndr/exgetty.rb

## layer 2 is minimal
#FROM scratch
#
#COPY --from=wkndr /var/lib/wkndr/release/wkndr.mruby /var/lib/wkndr/release/wkndr.mruby
#COPY --from=wkndr /var/lib/wkndr/public /var/lib/wkndr/public
#COPY --from=wkndr /var/lib/wkndr/Wkndrfile /var/lib/wkndr/Wkndrfile
#COPY --from=wkndr /bin/busybox /bin/busybox

WORKDIR /var/lib/wkndr

CMD ["/var/lib/wkndr/release/wkndr.mruby", "--server=/var/lib/wkndr/public", "--no-client"]
