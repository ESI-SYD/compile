#!/bin/bash
set -e

# parameters
TRITON_VERSION=${1:-}

# determine target
DOCKERFILE_NAME=""
CONTAINER_NAME=""
if [[ $TRITON_VERSION == "210" ]]; then
    DOCKERFILE_NAME="Dockerfile.2_1_0"
    IMAHE_NAME="triton-xpu-210"
    CONTAINER_NAME="spirv-210"
else
    DOCKERFILE_NAME="Dockerfile"
    IMAHE_NAME="triton-xpu-llvm"
    CONTAINER_NAME="llvm-target"
fi

# print
echo "==============================="
echo "CONTAINER_NAME: ${CONTAINER_NAME}"
echo "DOCKERFILE_NAME: ${DOCKERFILE_NAME}"
echo "IMAHE_NAME: ${IMAHE_NAME}"
echo "CONTAINER_NAME : ${CONTAINER_NAME}"
echo "TRITON_VERSION : ${TRITON_VERSION}"
echo "==============================="

echo "==============================="
echo "BUIDINGING IMAGE: ${IMAGE_NAME} ..."
echo "==============================="
# build image
DOCKER_BUILDKIT=1 docker build --build-arg https_proxy=${https_proxy} \
                               --build-arg http_proxy=${http_proxy} \
                               -t ${IMAHE_NAME} \
                               -f ../docker/${DOCKERFILE_NAME} .

echo "==============================="
echo "CLEANNING CONTAINERS..."
echo "==============================="
# clean container
if [[ -n "$(docker ps -a | grep llvm-target | awk '{print $1}')" ]]; then
    docker stop $(docker ps -a | grep llvm-target | awk '{print $1}')
    docker rm $(docker ps -a | grep llvm-target | awk '{print $1}')
fi
if [[ -n "$(docker ps -a | grep spirv-210 | awk '{print $1}')" ]]; then
    docker stop $(docker ps -a | grep spirv-210 | awk '{print $1}')
    docker rm $(docker ps -a | grep spirv-210 | awk '{print $1}')
fi

echo "==============================="
echo "CREATE CONTAINER..."
echo "==============================="
# container
docker run -id --name ${CONTAINER_NAME} \
               --privileged \
               --env https_proxy=${https_proxy} \
               --env http_proxy=${http_proxy} \
               --net host \
               --shm-size 2G ${IMAHE_NAME}

echo "==============================="
echo "BUILD TRITON IN CONTAINER..."
echo "==============================="
# build triton
if [[ $TRITON_VERSION == "210" ]]; then
    docker exec -i ${CONTAINER_NAME} bash -c "source /opt/intel/oneapi/setvars.sh"
else
    docker exec -i ${CONTAINER_NAME} bash -c "source /opt/intel/oneapi/setvars.sh && \
                                            export BASE=/workspace && \
                                            wget -qO- https://raw.githubusercontent.com/intel/intel-xpu-backend-for-triton/llvm-target/scripts/compile-triton.sh | bash"
fi


