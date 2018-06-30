#!/bin/sh

/usr/sbin/apache2 -D FOREGROUND &

/usr/bin/docker-registry serve /etc/docker/registry/config.yml &

wait
