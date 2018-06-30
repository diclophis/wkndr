FROM ubuntu:bionic-20180526

ENV DEBIAN_FRONTEND noninteractive
ENV LC_ALL C.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

USER root

RUN apt-get update \
    && apt-get upgrade --no-install-recommends -y \
    && apt-get install --no-install-recommends -y \
      locales ruby2.5 rake git \
      apache2 apache2-utils \
      docker-registry \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN locale-gen --purge en_US.UTF-8 && /bin/echo -e  "LANG=$LANG\nLANGUAGE=$LANGUAGE\n" | tee /etc/default/locale \
    && locale-gen $LANGUAGE \
    && dpkg-reconfigure locales

RUN gem update --no-document --system
RUN gem install --no-document thor
RUN gem list

RUN a2enmod dav dav_fs headers rewrite
RUN a2dissite 000-default

ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data

ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_RUN_DIR /var/run/apache2

RUN mkdir -p /var/run/apache2; chown www-data /var/run/apache2
RUN mkdir -p /usr/local/apache; chown www-data /usr/local/apache
RUN mkdir -p /var/lock/apache2; chown www-data /var/lock/apache2
RUN mkdir -p /var/log/apache2; chown www-data /var/log/apache2
RUN mkdir -p /var/tmp; chown www-data /var/tmp

#ADD index.html /var/www/html/index.html

COPY vhosts.conf /etc/apache2/sites-available/vhosts.conf

RUN a2ensite vhosts

RUN htpasswd -cb /etc/apache2/webdav.password guest guest
RUN chown root:www-data /etc/apache2/webdav.password
RUN chmod 640 /etc/apache2/webdav.password

RUN echo "Listen 8080" | tee /etc/apache2/ports.conf

RUN git init --bare /var/tmp/workspace.git

RUN mv /var/tmp/workspace.git/hooks/post-update.sample /var/tmp/workspace.git/hooks/post-update && chmod +x /var/tmp/workspace.git/hooks/post-update

COPY init.sh /bin/init.sh
COPY etc-docker-registry-config.yaml /etc/docker/registry/config.yml
