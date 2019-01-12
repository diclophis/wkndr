FROM static-vim-dockerfile:latest

FROM ubuntu:bionic-20180526

ENV LC_ALL C.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

ENV DEBIAN_FRONTEND noninteractive

USER root

COPY --from=0 /var/tmp/build/vim-src/src/vim /var/lib/vim-static

COPY bootstrap.sh /var/tmp/bootstrap.sh
RUN /var/tmp/bootstrap.sh

COPY emscripten.sh /var/tmp/emscripten.sh
RUN /var/tmp/emscripten.sh

COPY Makefile /var/tmp/kit1zx/Makefile

COPY emscripten-warmup.sh /var/tmp/emscripten-warmup.sh
RUN /var/tmp/emscripten-warmup.sh

COPY config /var/tmp/kit1zx/config
COPY mruby /var/tmp/kit1zx/mruby
RUN cd /var/tmp/kit1zx/mruby && rm -Rf build && make clean && MRUBY_CONFIG=../config/emscripten.rb make -j

COPY libuv-patch/process.c /var/tmp/kit1zx/mruby/build/host/mrbgems/mruby-uv/libuv-1.19.1/src/unix/process.c
COPY libuv-patch/Makefile.am /var/tmp/kit1zx/mruby/build/host/mrbgems/mruby-uv/libuv-1.19.1/Makefile.am
COPY libuv-patch/mrbgem.rake /var/tmp/kit1zx/mruby/build/mrbgems/mruby-uv/mrbgem.rake

RUN touch /var/tmp/kit1zx/mruby/build/host/mrbgems/mruby-uv/libuv-1.19.1/include/uv.h && cd /var/tmp/kit1zx/mruby && MRUBY_CONFIG=../config/emscripten.rb make -j

COPY raylib-src /var/tmp/kit1zx/raylib-src
COPY resources /var/tmp/kit1zx/resources
COPY lib /var/tmp/kit1zx/lib
COPY Makefile.emscripten main.c iterate.sh lib shell.html /var/tmp/kit1zx/

#RUN /var/tmp/kit1zx/iterate.sh

#COPY web_static.rb /var/tmp/kit1zx/

#COPY shell.js /var/tmp/kit1zx/release/libs/html5/

COPY server /var/tmp/kit1zx/server

RUN cd /var/tmp/kit1zx/server && make

RUN mkdir -p /var/tmp/chroot/bin
RUN cp /var/lib/vim-static /var/tmp/chroot/bin/vi
RUN cp /bin/bash-static /var/tmp/chroot/bin/sh

#CMD ["bash"]
#CMD ["rackup", "/var/tmp/kit1zx/web_static.rb", "-p8000", "-o0.0.0.0"]
CMD ["/var/tmp/kit1zx/server/release/libs/osx/kit1zx-server"]
