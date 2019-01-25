#!/bin/sh

#LOL

exec chroot /var/tmp/chroot /bin/bash -c "cd $HOME && exec /bin/bash -i -l -r"
