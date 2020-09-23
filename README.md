# wrlcd-build

Build wrlinuxCD with the static code analyser CodeChecker.
The results are stored on a CodeChecker webserver running at localhost:8002

## Prerequisites:
* wrlinuxcd installed
* docker installed and working as non-root user


## Build steps:
0. To see available rules type
`make help`

1. create a hostconfig-$(hostname).mk file with the following content
```
# Define where you have wrlinux CD
WRL_INSTALL_DIR	= /opt/projects/ericsson/installs/wrlinux_ltsCD

# Define to trace cmd's
# V=1
```
2. start Codechecker web server (http://localhost:8002)
`make codechecker.server.start`

3. setup and configure to build IMAGE=wrlinux-image-small with MACHINE=qemux86-64
`make configure`

4. enable codechecker
`make codechecker.enable`

5. build image
`make image`

6. Check codechecker result in the webserver, http://localhost:8002


### build with docker
1. start docker image using modified crops/poky image
`make docker.start`

2. login to docker container
`make docker.shell`

3. Do step 3-6 in Build steps


### Podman build
- Not tested/working

## References:
- https://github.com/Ericsson/codechecker
- https://github.com/Ericsson/codechecker/blob/master/docs/web/docker.md
- https://github.com/dl9pf/meta-codechecker
