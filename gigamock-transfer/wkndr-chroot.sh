#!/bin/sh

#LOL
env

# echo $SESS $USER >> /var/run/wkndr.sock

exec chroot /var/tmp/chroot /bin/bash -c "cd $HOME && exec /bin/bash -i -l -r -O checkwinsize"
