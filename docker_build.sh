docker build -f docker/Dockerfile.debian -t debian_step --label tlsprobe docker/
docker build -f docker/Dockerfile.ubuntu -t ubuntu_step --label tlsprobe docker/
docker build -f docker/Dockerfile.busybox -t busybox_step --label tlsprobe docker/
docker build -f docker/Dockerfile.alpine -t alpine_step --label tlsprobe docker/
