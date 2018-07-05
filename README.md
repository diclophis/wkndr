# wkndr

A choose your own adventure git+ops authenticated journaled deployment controller development pipeline kubernetes utility test service

`wkndr` uses the basename of the current "working directory" as the name of the primary "context" of work aka `$APP`.

There are also the notion of the `wkndr` deployment "itself", known as `$WKNDR`

# safety instructions

do not expose or use wkndr unless you have thoroughly understood the risk.

# wkndr changelog

appends to development journal CHANGELOG.md by default.

Useful for creating notes, or making blank commits for pushing into a git+ops pipeline

# wkndr build

_requires_ `$PATH/docker` and access to a working `/var/lib/docker.sock`

build `$APP:latest` using the `Dockerfile` from the HEAD version of the current working directory's git repo.

# wkndr provision

_requires_ `$PATH/kubectl` to be present, with a valid `kubeconfig` context set

installs `$TOOL` as a deployment.

# wkndr sh

exec into `$WKNDR` deployement for debugging interactive tty

# wkndr push

_requires_ `$PATH/git` to be present.

begins pipeline by sending latest commits to git remote controller

git remote controller will process inbound commits via `git-receive-pack`

current local branch will be stored into bare repo

event hooks are dispatched

by default builds `Dockerfile` from a gitRepo volumeMount

# wkndr dev

runs `Procfile` ... after optionally running `Prepfile`

# wkndr test

dispatches job pods based on configured testing strategy, defaults to .circle/config.yml

# wkndr continuous

TBD: internal process for looping

# wkndr key

TBD: manages authentication

# wkndr gitch

# notes

* https://github.com/FiloSottile/mkcert
* https://www.atlassian.com/git/tutorials/setting-up-a-repository/git-init
* https://github.com/GoogleContainerTools/kaniko
* https://github.com/erikhuda/thor
