## layer 0 is vim-static bin
#FROM static-vim-dockerfile:latest

# layer 1 is linux-box stuff
FROM ubuntu:focal-20201008 as wkndr

ENV LC_ALL C.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV DEBIAN_FRONTEND noninteractive

USER root

COPY gigamock-transfer/bootstrap.sh /var/tmp/bootstrap.sh

RUN /var/tmp/bootstrap.sh

COPY gigamock-transfer/emscripten.sh /var/tmp/emscripten.sh
RUN /var/tmp/emscripten.sh

COPY gigamock-transfer/emscripten-warmup.sh /var/tmp/emscripten-warmup.sh
RUN /var/tmp/emscripten-warmup.sh

COPY config /var/lib/wkndr/config

RUN cd /var/lib/wkndr && \
    git clone https://github.com/mruby/mruby && \
    cd mruby && \
    git fetch && \
    git checkout 612e5d6aad7f224008735d57b19e5a81556cfd31

RUN cd /var/lib/wkndr && \
    git clone https://github.com/raysan5/raylib && \
    cd raylib && \
    git fetch && \
    git checkout 4d5ee7953ccac5c1d59f4223899d3d6bffc329b8

COPY rlgl.h.patch /var/lib/wkndr/
RUN cd /var/lib/wkndr/raylib && \
    cat ../rlgl.h.patch | git apply

#RUN cd /root/emsdk && \
#    . ./emsdk_env.sh && \
#    cd /var/lib/wkndr/mruby && \
#    MRUBY_CONFIG=../config/emscripten.rb make

#RUN cd /var/lib/wkndr/mruby && \
#    make mruby/build/host/bin/mrbc

#RUN cd /root/emsdk && \
#    . ./emsdk_env.sh && \
#    mkdir /var/lib/wkndr/release && \
#    cd /var/lib/wkndr/raylib/src && \
#    RAYLIB_RELEASE_PATH=../../release make PLATFORM=PLATFORM_WEB -B -e

COPY Makefile gigamock-transfer/simple-cp.sh gigamock-transfer/simple-bake.sh gigamock-transfer/iterate-server.sh gigamock-transfer/iterate-web.sh /var/lib/wkndr/
COPY gigamock-transfer/mkstatic-mruby-module.rb /var/lib/wkndr/gigamock-transfer/mkstatic-mruby-module.rb

RUN cd /var/lib/wkndr && \
    make clean

RUN cd /var/lib/wkndr && \
    make build-mruby

RUN cd /var/lib/wkndr && \
    TARGET=emcc make build-mruby

RUN cd /var/lib/wkndr && \
    make release/libraylib.a

COPY main.c /var/lib/wkndr/
COPY src /var/lib/wkndr/src
COPY include /var/lib/wkndr/include
COPY lib /var/lib/wkndr/lib
COPY gigamock-transfer/static /var/lib/wkndr/gigamock-transfer/static

COPY resources /var/lib/wkndr/resources

COPY Wkndrfile /var/lib/wkndr/

RUN cd /var/lib/wkndr && \
    make

#RUN /var/lib/wkndr/iterate-server.sh
#RUN cp /var/lib/wkndr/release/wkndr.mruby /var/tmp
#
#RUN /var/lib/wkndr/iterate-server.sh clean
#
RUN cd /root/emsdk && \
    . ./emsdk_env.sh && \
    cd /var/lib/wkndr && \
    find release -name "*.o" -delete && \
    find release -name "*.h" -delete && \
    find release -name "*.a" -delete && \
    emmake make TARGET=emsc
    
#RUN /var/lib/wkndr/simple-bake.sh
RUN /var/lib/wkndr/simple-cp.sh
#
#RUN cp /var/tmp/wkndr.mruby /var/lib/wkndr/release/
#
RUN ls -lh /var/lib/wkndr/release/wkndr.mruby /var/lib/wkndr/public

WORKDIR /var/lib/wkndr

CMD ["/var/lib/wkndr/release/wkndr.mruby", "--server=/var/lib/wkndr/public", "--no-client"]
