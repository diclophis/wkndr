## layer 0 is vim-static bin
#FROM static-vim-dockerfile:latest

# layer 1 is linux-box stuff
FROM ubuntu:focal-20201008 as wkndr

ENV LC_ALL C.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV DEBIAN_FRONTEND noninteractive
ENV BITS foo

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
    git checkout 1e1d2964972eda9dd0317dfa422311e5c5b80783

RUN cd /var/lib/wkndr && \
    git clone https://github.com/raysan5/raylib && \
    cd raylib && \
    git fetch && \
    git checkout 7eb341ccafa1cb39006b354714e4524a612c6e25

#COPY rlgl.h.patch /var/lib/wkndr/
#RUN cd /var/lib/wkndr/raylib && \
#    cat ../rlgl.h.patch | git apply

COPY Makefile gigamock-transfer/simple-cp.sh gigamock-transfer/simple-bake.sh gigamock-transfer/iterate-server.sh gigamock-transfer/iterate-web.sh /var/lib/wkndr/
COPY gigamock-transfer/mkstatic-mruby-module.rb /var/lib/wkndr/gigamock-transfer/mkstatic-mruby-module.rb

RUN cd /var/lib/wkndr && \
    make clean

RUN cd /var/lib/wkndr && \
    make build-mruby

RUN cp /root/emsdk/upstream/emscripten/cmake/Modules/TestBigEndian.cmake /usr/share/cmake-3.16/Modules/TestBigEndian.cmake

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

RUN /var/lib/wkndr/simple-bake.sh

RUN /var/lib/wkndr/simple-cp.sh

RUN ls -lh /var/lib/wkndr/release/wkndr.mruby /var/lib/wkndr/public

WORKDIR /var/lib/wkndr

CMD ["/var/lib/wkndr/release/wkndr.mruby", "--server=/var/lib/wkndr/public", "--no-client"]
