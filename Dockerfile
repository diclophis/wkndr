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
COPY openssl.conf /etc/ssl/private/openssl.conf

COPY container.sh /var/tmp/container.sh

RUN /var/tmp/container.sh

COPY apache.conf /etc/apache2/sites-available/000-default.conf
COPY nginx-apt-proxy.conf /etc/nginx/conf.d
COPY git-repo-template /usr/share/git-core/templates
COPY etc-docker-registry-config.yaml /etc/docker/registry/config.yml

COPY Gemfile Gemfile.lock Rakefile wkndr.gemspec /var/lib/wkndr/
COPY ext /var/lib/wkndr/ext/
COPY lib /var/lib/wkndr/lib/

RUN cd /var/lib/wkndr && ls -l && bundle && bundle exec rake

COPY Thorfile Procfile.init strace.sh /var/lib/wkndr/

RUN ln -fs /var/lib/wkndr/Thorfile /usr/bin/wkndr && wkndr help
