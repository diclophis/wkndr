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

COPY Gemfile Gemfile.lock Rakefile wkndr.gemspec /var/lib/wkndr/
COPY lib /var/lib/wkndr/lib/

RUN cd /var/lib/wkndr && ls -l && bundle && bundle exec rake

COPY Thorfile Procfile.init /var/lib/wkndr/

RUN ln -fs /var/lib/wkndr/Thorfile /usr/bin/wkndr && wkndr help

#FROM ubuntu:bionic-20180526

#ENV LC_ALL C.UTF-8
#ENV LANG en_US.UTF-8
#ENV LANGUAGE en_US.UTF-8

#ENV DEBIAN_FRONTEND noninteractive

#USER root

COPY --from=0 /var/tmp/build/vim-src/src/vim /var/lib/vim-static

COPY gigamock-transfer/emscripten.sh /var/tmp/emscripten.sh
RUN /var/tmp/emscripten.sh

COPY Makefile /var/lib/wkndr/Makefile

COPY gigamock-transfer/emscripten-warmup.sh /var/tmp/emscripten-warmup.sh
RUN /var/tmp/emscripten-warmup.sh

COPY config /var/lib/wkndr/config

RUN cd /var/lib/wkndr/mruby && rm -Rf build && make clean && MRUBY_CONFIG=../config/emscripten.rb make -j

COPY libuv-patch/process.c /var/lib/wkndr/mruby/build/host/mrbgems/mruby-uv/libuv-1.19.1/src/unix/process.c
COPY libuv-patch/Makefile.am /var/lib/wkndr/mruby/build/host/mrbgems/mruby-uv/libuv-1.19.1/Makefile.am
COPY libuv-patch/mrbgem.rake /var/lib/wkndr/mruby/build/mrbgems/mruby-uv/mrbgem.rake

RUN touch /var/lib/wkndr/mruby/build/host/mrbgems/mruby-uv/libuv-1.19.1/include/uv.h && cd /var/lib/wkndr/mruby && MRUBY_CONFIG=../config/emscripten.rb make -j

COPY raylib-src /var/lib/wkndr/raylib-src
COPY lib /var/lib/wkndr/lib

#COPY Makefile.emscripten main.c iterate.sh lib shell.html /var/tmp/kit1zx/
##RUN /var/tmp/kit1zx/iterate.sh
##COPY web_static.rb /var/tmp/kit1zx/
##COPY shell.js /var/tmp/kit1zx/release/libs/html5/
#COPY server /var/tmp/kit1zx/server
#RUN cd /var/tmp/kit1zx/server && make
#RUN mkdir -p /var/tmp/chroot/bin
#RUN cp /var/lib/vim-static /var/tmp/chroot/bin/vi
#RUN cp /bin/bash-static /var/tmp/chroot/bin/sh


#CMD ["bash"]
#CMD ["rackup", "/var/tmp/kit1zx/web_static.rb", "-p8000", "-o0.0.0.0"]
CMD ["/var/tmp/kit1zx/server/release/libs/osx/kit1zx-server"]

#TODO: !!!!!!!!!!!!!!!  flesh out submodules in dockerfile, dont rely on local filesystem!!!
