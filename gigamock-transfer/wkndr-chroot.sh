#!/bin/sh

set -x

env

exec chroot /var/tmp/chroot /bin/bash
