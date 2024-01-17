#!/bin/bash

# name
IMAGE_NAME=${1:-triton-xpu}
CONTAINER_NAME=${2:-llvm}

# image
DOCKER_BUILDKIT=1 docker build --build-arg https_proxy=${https_proxy} \
                               --build-arg http_proxy=${http_proxy} \
                               --build-arg no_proxy=${no_proxy} \
                               -t ${IMAGE_NAME} \
                               -f ../docker/Dockerfile .

# container
docker run -id --name ${CONTAINER_NAME} \
               --privileged \
               --env https_proxy=${https_proxy} \
               --env http_proxy=${http_proxy} \
               --net host \
               --shm-size 2G ${IMAGE_NAME}

# build triton
docker exec -ti ${CONTAINER_NAME} bash -c "source /opt/intel/oneapi/setvars.sh && \
                                           export BASE=$(pwd) && \
                                           wget -qO- https://raw.githubusercontent.com/intel/intel-xpu-backend-for-triton/llvm-target/scripts/compile-triton.sh | bash"
