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
  pybind11-dev \
  wget \
  vim \
  zlib1g-dev && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

RUN no_proxy=$no_proxy wget -qO - https://repositories.intel.com/gpu/intel-graphics.key | \
  gpg --dearmor --output /usr/share/keyrings/intel-graphics.gpg
RUN echo "deb [arch=amd64 signed-by=/usr/share/keyrings/intel-graphics.gpg] https://repositories.intel.com/gpu/ubuntu jammy unified" | \
  tee /etc/apt/sources.list.d/intel-gpu-jammy.list

RUN apt-get update && \
  apt-get install -y --no-install-recommends --fix-missing \
  intel-opencl-icd \
  clinfo \
  intel-level-zero-gpu \
  level-zero \
  level-zero-dev libigc-dev intel-igc-cm libigdfcl-dev libigfxcmrt-dev && \
  apt install -y --no-install-recommends --allow-downgrades --fix-missing libigc1=1.0.14828.26-736~22.04; \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*
ENV PATH /opt/conda/bin:$PATH  

FROM dev-base AS conda
ARG PYTHON_VERSION=3.10
RUN curl -fsSL -v -k -o ~/miniconda.sh -O https://repo.anaconda.com/miniconda/Miniconda3-py39_23.9.0-0-Linux-x86_64.sh && \
  chmod +x ~/miniconda.sh && \
  # Fix conda install issue
  sed -i "s;#!/bin/sh;#!/bin/bash;" ~/miniconda.sh && \
  ~/miniconda.sh -b -p /opt/conda && \
  rm ~/miniconda.sh && \
  /opt/conda/bin/conda config --set channel_priority strict && \
  /opt/conda/bin/conda config --append channels conda-forge && \
  /opt/conda/bin/conda install -y python=${PYTHON_VERSION} \
  setuptools && \
  /opt/conda/bin/conda clean -ya && \
  # Fix GLIBCXX version issue
  rm -f /opt/conda/lib/libstdc++.so.6

FROM dev-base AS build
COPY --from=conda /opt/conda /opt/conda
RUN cd $HOME; \
  no_proxy=$no_proxy wget https://registrationcenter-download.intel.com/akdlm/IRC_NAS/163da6e4-56eb-4948-aba3-debcec61c064/l_BaseKit_p_2024.0.1.46_offline.sh; \
  /bin/sh l_BaseKit*.sh -a --silent --eula accept; \
  rm l_BaseKit*.sh
