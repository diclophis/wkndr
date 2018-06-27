# wkndr

git+ops authenticated journal deployment controller development pipeline kubernetes utility testing

# wkndr provision

_requires_ `$PATH/docker` and working `/var/lib/docker.sock`

build `wkndr:latest` from current version of utility

# wkndr dev

runs `Procfile` ... after running `Prepfile` inside of a kubernetes pod

# wkndr changelog

appends to development journal

# wkndr push

_requires_ `$PATH/git` to be present.

begins pipeline by sending latest commits to git remote controller

git remote controller will process inbound commits via `git-receive-pack`

current local branch will be stored into bare repo

event hooks are dispatched

a tar ball of the checkout of the current local branch will be created

# wkndr continuous

internal process for looping

# wkndr key

manages authentication

# wkndr test

dispatches job pods based on configured testing strategy, defaults to yaml

# wkndr deploy

_requires_ `$PATH/helm` to be present

installs wkndr as a deployment

# wkndr sh

exec into deployement for debugging interactive tty
