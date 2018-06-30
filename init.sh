#!/bin/sh

/usr/bin/apache2 -D FOREGROUND &
/usr/bin/docker-registry /etc/docker/registry/config.yml &

wait
