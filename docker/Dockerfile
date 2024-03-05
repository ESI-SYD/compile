# syntax=docker/dockerfile:1
FROM ubuntu:22.04 AS dev-base

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y --no-install-recommends --fix-missing \
    apt-utils \
    build-essential \
    ca-certificates \
    clinfo \
    cmake \
    ninja-build \
    ncurses-term \
    curl \
    git \
    gnupg2 \
    gpg-agent \
    libsm6 \
    libxext6 \
    libgl1-mesa-glx \
    pybind11-dev \
    wget \
    vim \
    zlib1g-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# gpu driver refer to 
# https://dgpu-docs.intel.com/releases/LTS_803.29_20240131.html#ubuntu-22-04
RUN wget -qO - https://repositories.intel.com/gpu/intel-graphics.key | \
  gpg --dearmor --output /usr/share/keyrings/intel-graphics.gpg
RUN echo "deb [arch=amd64 signed-by=/usr/share/keyrings/intel-graphics.gpg] https://repositories.intel.com/gpu/ubuntu jammy/lts/2350 unified" | \
  tee /etc/apt/sources.list.d/intel-gpu-jammy.list

# latest public oneapi basekit refer to 2024.0.1
# https://www.intel.com/content/www/us/en/developer/tools/oneapi/base-toolkit-download.html?operatingsystem=linux&distributions=aptpackagemanager
RUN wget -O- https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB \ | gpg --dearmor | \
tee /usr/share/keyrings/oneapi-archive-keyring.gpg > /dev/null
RUN echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" | \
 tee /etc/apt/sources.list.d/oneAPI.list


RUN apt-get update && \
    apt-get install -y --no-install-recommends --fix-missing \
    intel-basekit \
    intel-opencl-icd \
    clinfo \
    intel-level-zero-gpu \
    level-zero \
    level-zero-dev libigc-dev intel-igc-cm libigdfcl-dev libigfxcmrt-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
ENV PATH /opt/conda/bin:$PATH  

FROM dev-base AS conda
ARG PYTHON_VERSION=3.10
RUN curl -fsSL -v -k -o ~/miniconda.sh -O https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    chmod +x ~/miniconda.sh && \
    ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh && \
    /opt/conda/bin/conda config --set channel_priority strict && \
    /opt/conda/bin/conda config --append channels conda-forge && \
    /opt/conda/bin/conda install -y python=${PYTHON_VERSION} \
    setuptools && \
    /opt/conda/bin/conda clean -ya && \
    # Fix GLIBCXX version issue
    rm -f /opt/conda/lib/libstdc++.so.6
# pt and ipex
FROM dev-base AS build
COPY --from=conda /opt/conda /opt/conda
WORKDIR /workspace
RUN git clone https://github.com/Stonepia/pytorch.git -b dev/triton-test-3.0 && \
    cd pytorch && git checkout c9153c96f547f269581743e7443aa86d7e003505 && \
    pip install pyyaml && pip install -r requirements.txt && \
    git submodule sync && git submodule update --init --recursive && \
    python setup.py develop && cd .. && \
    git clone https://github.com/intel/intel-extension-for-pytorch.git -b dev/triton-test-3.0 ipex && \
    cd ipex && git checkout faadb009c12ed4fb3133db9a10020726016b3d24 && git submodule sync && \
    git submodule update --init --recursive && cd .. && \
    . /opt/intel/oneapi/setvars.sh && \
    cd ipex && pip install -r requirements.txt && python setup.py develop && cd .. && \
    git clone https://github.com/intel/intel-xpu-backend-for-triton.git -b llvm-target && \
    cd intel-xpu-backend-for-triton && scripts/compile-triton.sh

FROM dev-base AS image
COPY --from=build /opt/conda /opt/conda
COPY --from=build /workspace/pytorch /workspace/pytorch
COPY --from=build /workspace/ipex /workspace/ipex
COPY --from=build /workspace/intel-xpu-backend-for-triton /workspace/intel-xpu-backend-for-triton
WORKDIR /workspace
