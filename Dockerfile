## layer 0 is vim-static bin
#FROM static-vim-dockerfile:latest

# layer 1 is linux-box stuff
FROM ubuntu:noble-20250127 as wkndr

ENV LC_ALL C.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV DEBIAN_FRONTEND noninteractive
ENV BITS fooo

USER root

COPY gigamock-transfer/bootstrap.sh /var/tmp/bootstrap.sh
RUN /var/tmp/bootstrap.sh

COPY gigamock-transfer/emscripten.sh /var/tmp/emscripten.sh
RUN /var/tmp/emscripten.sh

COPY gigamock-transfer/emscripten-warmup.sh /var/tmp/emscripten-warmup.sh
RUN /var/tmp/emscripten-warmup.sh

RUN cd /var/lib/wkndr && \
    git clone https://github.com/raysan5/raylib.git && \
    cd raylib && \
    git fetch && \
    git checkout 5.5

ENV RAYLIB_CACHE_SINCE 2025-02-22

COPY raylib-config.h /var/tmp/raylib-config.h

RUN cd /root/emsdk && \
    . ./emsdk_env.sh && \
    cp /var/tmp/raylib-config.h /var/lib/wkndr/raylib/src && \
    cd /var/lib/wkndr/raylib/src && \
    mkdir -p ../../release/wasm ../../release/desktop-heavy ../../release/desktop-heavy-x11 && \
    RAYLIB_RELEASE_PATH=../../release/desktop-heavy PLATFORM=PLATFORM_DRM make -B -e && \
    RAYLIB_RELEASE_PATH=../../release/desktop-heavy-x11 PLATFORM=PLATFORM_DESKTOP make -B -e && \
    RAYLIB_RELEASE_PATH=../../release/wasm PLATFORM=PLATFORM_WEB emmake make -B -e

RUN cd /var/lib/wkndr && \
    git clone https://github.com/mruby/mruby && \
    cd mruby && \
    git fetch && \
    git checkout 87260e7bb1a9edfb2ce9b41549c4142129061ca5

COPY config /var/lib/wkndr/config
RUN cd /root/emsdk && \
    . ./emsdk_env.sh && \
    cd /var/lib/wkndr/mruby && \
    MRUBY_CONFIG=../config/heavy.rb make

RUN cd /root/emsdk && \
    . ./emsdk_env.sh && \
    cd /var/lib/wkndr/mruby && \
    cp /root/emsdk/upstream/emscripten/cmake/Modules/TestBigEndian.cmake /usr/share/cmake-3.28/Modules/TestBigEndian.cmake && \
    MRUBY_CONFIG=../config/emscripten.rb emmake make
    #cp /root/emsdk/upstream/emscripten/cmake/Modules/TestBigEndian.cmake /usr/share/cmake-3.16/Modules/TestBigEndian.cmake && \

#RUN cd /var/lib/wkndr && \
#    git clone https://github.com/RandyGaul/qu3e.git && \
#    cd qu3e && \
#    git fetch && \
#    git checkout 1f519c95460ce2852356576b0f895861edbfe0be

RUN cd /var/lib/wkndr && \
    git clone https://bitbucket.org/odedevs/ode.git && \
    cd ode && \
    git fetch && \
    git checkout 92362ac1e6cf3a12343493f67807780505253e1c && \
	  ./bootstrap && ./configure && make

RUN cd /root/emsdk && \
    . ./emsdk_env.sh && \
    cd /var/lib/wkndr/ode && \
	  emmake make

##COPY rlgl.h.patch /var/lib/wkndr/
##RUN cd /var/lib/wkndr/raylib && \
##    cat ../rlgl.h.patch | git apply
#
COPY Makefile gigamock-transfer/simple-cp.sh gigamock-transfer/simple-bake.sh gigamock-transfer/iterate-server.sh gigamock-transfer/iterate-web.sh /var/lib/wkndr/
COPY gigamock-transfer/mkstatic-mruby-module.rb /var/lib/wkndr/gigamock-transfer/mkstatic-mruby-module.rb

#RUN cd /var/lib/wkndr && \
#    make clean
#
#RUN cd /var/lib/wkndr && \
#    make build-mruby
#
####RUN cp /root/emsdk/upstream/emscripten/cmake/Modules/TestBigEndian.cmake /usr/share/cmake-3.16/Modules/TestBigEndian.cmake
#
#RUN cd /var/lib/wkndr && \
#    TARGET=emcc make build-mruby
#
#RUN cd /var/lib/wkndr && \
#    make release/libraylib.a
#
RUN cd /root/emsdk && \
    . ./emsdk_env.sh && \
    cd /var/lib/wkndr && \
    mkdir -p release/desktop/src/desktop && \
    mkdir -p release/src/desktop && \
    emmake make ode/ode/src/.libs/libode.a mruby/build/emscripten/lib/libmruby.a mruby/build/emscripten/mrbgems/mruby-simplemsgpack/lib/libmsgpackc.a release/wasm/libraylib.a

COPY main.c /var/lib/wkndr/
COPY glyph /var/lib/wkndr/glyph
COPY src /var/lib/wkndr/src
RUN ls -l /var/lib/wkndr/src
COPY include /var/lib/wkndr/include
COPY lib /var/lib/wkndr/lib
COPY gigamock-transfer/static /var/lib/wkndr/gigamock-transfer/static
COPY resources /var/lib/wkndr/resources

RUN cd /var/lib/wkndr && \
    mkdir -p release/desktop/src/desktop && \
    mkdir -p release/src/desktop && \
    make release/wkndr.mruby.x11

RUN cd /root/emsdk && \
    . ./emsdk_env.sh && \
    cd /var/lib/wkndr && \
    mkdir -p release/wasm/src && \
    mkdir -p release/src/wasm && \
    emmake make release/wkndr.html

COPY Wkndrfile /var/lib/wkndr/

#RUN /var/lib/wkndr/simple-bake.sh

RUN /var/lib/wkndr/simple-cp.sh

#RUN ls -lh /var/lib/wkndr/release/wkndr.mruby /var/lib/wkndr/public

WORKDIR /var/lib/wkndr

CMD ["/var/lib/wkndr/release/wkndr.mruby", "--server=/var/lib/wkndr/public", "--no-client"]
