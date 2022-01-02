#!/bin/sh

set -e

ls -lh /var/lib/wkndr/release

mkdir -p /var/lib/wkndr/public

cp -Rv /var/lib/wkndr/release/wkndr* /var/lib/wkndr/public/

ls -lh /var/lib/wkndr/release/wkndr.mruby /var/lib/wkndr/public
