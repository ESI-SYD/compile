# syntax=docker/dockerfile:1
FROM ubuntu:22.04 AS dev-base

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
  apt-get install -y --no-install-recommends --fix-missing \
  apt-utils \
  build-essential \
  ca-certificates \
  cmake \
  curl \
  ninja-build \
  ncurses-term \
  git \
  gnupg2 \
  gpg-agent \
  libsm6 \
  libxext6 \
  libgl1-mesa-glx \
  python3 \
  python3-venv \
  python3-dev \
  python3-pip \
  pybind11-dev \
  wget \
  vim \
  zlib1g-dev && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

FROM dev-base AS build
# https://www.intel.com/content/www/us/en/developer/articles/tool/pytorch-prerequisites-for-intel-gpu/2-5.html
# Download the Intel APT repository’s public key and put it into the /usr/share/keyrings directory
RUN wget -O- https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB \
  | gpg --dearmor > /tmp/intel-for-pytorch-gpu-dev-keyring.gpg && \
  mv /tmp/intel-for-pytorch-gpu-dev-keyring.gpg /usr/share/keyrings

# Configure the APT client to add the Intel repository and its key
RUN echo "deb [signed-by=/usr/share/keyrings/intel-for-pytorch-gpu-dev-keyring.gpg] https://apt.repos.intel.com/intel-for-pytorch-gpu-dev all main" \
    > /tmp/intel-for-pytorch-gpu-dev.list && \
    mv /tmp/intel-for-pytorch-gpu-dev.list /etc/apt/sources.list.d


# Drivers
RUN echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/intel-graphics.gpg] https://repositories.intel.com/gpu/ubuntu jammy unified' > /etc/apt/sources.list.d/intel-gpu-jammy.list; \
  curl -sSL https://repositories.intel.com/gpu/intel-graphics.key | gpg --dearmor --output /usr/share/keyrings/intel-graphics.gpg

# Install
RUN apt-get update && \
  apt-get install -y --no-install-recommends --fix-missing \
  intel-for-pytorch-gpu-dev-0.5 \
  intel-pti-dev \
  intel-opencl-icd \
  clinfo \
  intel-level-zero-gpu \
  level-zero \
  level-zero-dev libigc-dev intel-igc-cm libigdfcl-dev libigfxcmrt-dev && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

FROM dev-base AS image
COPY --from=build /opt/intel /opt/intel
WORKDIR /workspace
