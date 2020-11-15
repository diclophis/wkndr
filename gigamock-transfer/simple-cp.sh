#!/bin/sh

set -e

ls -lh /var/lib/wkndr/release

mkdir -p /var/lib/wkndr/public

cp /var/lib/wkndr/release/wkndr.js /var/lib/wkndr/public/
cp /var/lib/wkndr/release/wkndr.wasm /var/lib/wkndr/public/
cp /var/lib/wkndr/release/wkndr.data /var/lib/wkndr/public/

ls -lh /var/lib/wkndr/public
