#!/bin/bash
set -e

# parameters
TRITON_VERSION=${1:-latest} # 210 / latest
TRITON_BRANCH=${2:-llvm-target} # llvm-target / yudong/xetla_softmax
TRITON_COMMIT=${3:-latest}
PT_COMMIT=${4:-pins}
IPEX_COMMIT=${5:-pins}
BASEKIT_VERSION=${6:-2024.1.0-589} # 2024.1.0-589 / 2024.0.1-43

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
echo "TRITON_BRANCH : ${TRITON_BRANCH}"
echo "TRITON_COMMIT : ${TRITON_COMMIT}"
echo "PT_COMMIT : ${PT_COMMIT}"
echo "IPEX_COMMIT : ${IPEX_COMMIT}"
echo "BASEKIT_VERSION : ${BASEKIT_VERSION}"
echo "==============================="

echo "==============================="
echo "BUIDINGING IMAGE: ${IMAGE_NAME} ..."
echo "==============================="
# build image
if [[ $TRITON_VERSION == "210" ]]; then
    DOCKER_BUILDKIT=1 docker build --build-arg https_proxy=${https_proxy} \
                                   --build-arg http_proxy=${http_proxy} \
                                   -t ${IMAHE_NAME} \
                                   -f ../docker/${DOCKERFILE_NAME} .
else
    DOCKER_BUILDKIT=1 docker build --build-arg TRITON_COMMIT=${TRITON_COMMIT} \
                                   --build-arg TRITON_BRANCH=${TRITON_BRANCH} \
                                   --build-arg PT_COMMIT=${PT_COMMIT} \
                                   --build-arg IPEX_COMMIT=${IPEX_COMMIT} \
                                   --build-arg BASEKIT_VERSION=${BASEKIT_VERSION} \
                                   --build-arg https_proxy=${https_proxy} \
                                   --build-arg http_proxy=${http_proxy} \
                                   -t ${IMAHE_NAME} \
                                   -f ../docker/${DOCKERFILE_NAME} .
fi
echo "==============================="
echo "CLEANNING CONTAINERS..."
echo "==============================="
# clean container
if [[ -n "$(docker ps -a | grep $CONTAINER_NAME | awk '{print $1}')" ]]; then
   docker stop $(docker ps -a | grep $CONTAINER_NAME | awk '{print $1}')
   docker rm $(docker ps -a | grep $CONTAINER_NAME | awk '{print $1}')
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
docker exec -i ${CONTAINER_NAME} bash -c "source /opt/intel/oneapi/setvars.sh"


