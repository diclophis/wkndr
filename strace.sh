#!/bin/sh

while ! strace -e trace=desc -s 1024 -f -p $(pgrep -f rcp) 2>&1 | grep 'read\|write\|open\|exec\|spawn' | grep -v 'EAGAIN\|ERESTARTSYS\|ENOENT'; do echo -n .; done
