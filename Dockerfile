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

#COPY --from=0 /var/tmp/build/vim-src/src/vim /var/lib/vim-static
#COPY --from=0 /var/tmp/build/vim-src/runtime /var/lib/vim-runtime

COPY gigamock-transfer/emscripten.sh /var/tmp/emscripten.sh
RUN /var/tmp/emscripten.sh

COPY gigamock-transfer/emscripten-warmup.sh /var/tmp/emscripten-warmup.sh
RUN /var/tmp/emscripten-warmup.sh

COPY config /var/lib/wkndr/config

RUN cd /var/lib/wkndr && ls -l && \
    git init 

RUN cd /var/lib/wkndr && ls -l && \
    git submodule add https://github.com/mruby/mruby mruby \
    git submodule init && \
    git submodule update && \
    cd mruby && \
    git fetch && \
    git checkout 612e5d6aad7f224008735d57b19e5a81556cfd31

RUN cd /var/lib/wkndr && ls -l && \
    git submodule add https://github.com/raysan5/raylib raylib \
    git submodule init && \
    git submodule update && \
    cd raylib && \
    git fetch && \
    git checkout 0c29ca8166f26ef24311fab5e2fd614f9358ea76

COPY rlgl.h.patch /var/lib/wkndr/
RUN cd /var/lib/wkndr && ls -l && \
    cd raylib && ls -l && \
    cat ../rlgl.h.patch | git apply

COPY Makefile gigamock-transfer/simple-cp.sh gigamock-transfer/simple-bake.sh gigamock-transfer/iterate-server.sh gigamock-transfer/iterate-web.sh /var/lib/wkndr/
COPY gigamock-transfer/mkstatic-mruby-module.rb /var/lib/wkndr/gigamock-transfer/mkstatic-mruby-module.rb

RUN /var/lib/wkndr/iterate-server.sh clean

#RUN /var/lib/wkndr/iterate-server.sh mruby/bin/mrbc

#RUN /var/lib/wkndr/iterate-web.sh build-mruby

COPY main.c /var/lib/wkndr/
COPY src /var/lib/wkndr/src
COPY include /var/lib/wkndr/include
COPY lib /var/lib/wkndr/lib
COPY gigamock-transfer/static /var/lib/wkndr/gigamock-transfer/static

#RUN /var/lib/wkndr/iterate-server.sh

COPY resources /var/lib/wkndr/resources

#RUN /var/lib/wkndr/iterate-web.sh

COPY Wkndrfile /var/lib/wkndr/

RUN /var/lib/wkndr/simple-bake.sh
RUN /var/lib/wkndr/simple-cp.sh

RUN /var/lib/wkndr/iterate-server.sh clean
RUN /var/lib/wkndr/iterate-server.sh

RUN ls -lh /var/lib/wkndr/release/wkndr.mruby /var/lib/wkndr/public

WORKDIR /var/lib/wkndr

CMD ["/var/lib/wkndr/release/wkndr.mruby", "--server=/var/lib/wkndr/public", "--no-client"]
