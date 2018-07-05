#!/bin/sh

set -e
set -x

apt-get update \
  && apt-get upgrade --no-install-recommends -y \
  && apt-get install --no-install-recommends -y \
       locales ruby2.5 rake git \
       apache2 apache2-utils \
       docker-registry \
       curl \
       vim \
       nginx \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

locale-gen --purge en_US.UTF-8 && /bin/echo -e  "LANG=$LANG\nLANGUAGE=$LANGUAGE\n" | tee /etc/default/locale \
  && locale-gen $LANGUAGE \
  && dpkg-reconfigure locales

gem update --no-document --system
gem install --no-document thor
gem list

a2enmod dav dav_fs headers rewrite

#a2dissite 000-default
#a2ensite vhosts

mkdir -p /var/run/apache2; chown www-data /var/run/apache2
mkdir -p /usr/local/apache; chown www-data /usr/local/apache
mkdir -p /var/lock/apache2; chown www-data /var/lock/apache2
mkdir -p /var/log/apache2; chown www-data /var/log/apache2
mkdir -p /var/tmp; chown www-data /var/tmp

htpasswd -cb /etc/apache2/webdav.password guest guest
chown root:www-data /etc/apache2/webdav.password
chmod 640 /etc/apache2/webdav.password

echo "Listen 8080" | tee /etc/apache2/ports.conf

mkdir -p /etc/openvpn/tmp \
         /etc/ssl/CA \
         /etc/ssl/private \
         /etc/ssl/private/newcerts

chown root /etc/ssl/private && chmod 0700 /etc/ssl/private

echo "01" | tee /etc/ssl/CA/serial | tee /etc/ssl/CA/crlnumber
touch /etc/ssl/CA/index.txt
touch /etc/ssl/CA/index.txt.attr

openssl req -config /etc/ssl/private/openssl.conf -new -x509 \
            -keyout /etc/ssl/private/cakey.pem \
            -out /usr/local/share/ca-certificates/ca.wkndr.crt \
            -days 365 -subj "/C=US/ST=Oregon/L=Portland/O=WKNDRCA" \
            -passout pass:01234567890123456789 \
            -extensions for_ca_req

openssl ca -gencrl -extensions v3_req \
           -keyfile /etc/ssl/private/cakey.pem \
           -cert /usr/local/share/ca-certificates/ca.wkndr.crt \
           -out /etc/ssl/CA/ca.wkndr.crl \
           -config /etc/ssl/private/openssl.conf \
           -passin pass:01234567890123456789 \
           -policy policy_anything \
           -batch

update-ca-certificates --fresh

openssl genrsa -out /etc/ssl/private/registry.wkndr.key 2048 && chmod 600 /etc/ssl/private/registry.wkndr.key

openssl req -new  \
            -out /etc/ssl/private/registry.wkndr.csr \
            -key /etc/ssl/private/registry.wkndr.key \
            -config /etc/ssl/private/openssl.conf \
            -extensions for_server_req \
            -subj "/C=US/ST=Oregon/L=Portland/O=WKNDR-SERVER/CN=wkndr-app"

openssl ca -in /etc/ssl/private/registry.wkndr.csr \
           -out /etc/ssl/private/registry.wkndr.pem \
           -config /etc/ssl/private/openssl.conf \
           -policy policy_anything \
           -batch \
           -passin pass:01234567890123456789 \
           -extensions for_server_req

openssl x509 -in /etc/ssl/private/registry.wkndr.pem -outform DER -out /etc/ssl/private/registry.wkndr.crt 

curl -fsSL -o /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v1.9.3/bin/linux/amd64/kubectl && \
     echo "81eb30e62a12d6e0527a6a3c2a9501b56d65777bf66684739b16a0afe826c8f8  /usr/local/bin/kubectl" | sha256sum -c && \
     chmod +x /usr/local/bin/kubectl
