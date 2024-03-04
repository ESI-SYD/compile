#!/bin/bash

WORKSPACE_FOLDER=/workspace
TRANSFORMERS_VERSION=`cat /workspace/pytorch/.ci/docker/ci_commit_pins/huggingface.txt`
TIMM_COMMIT_ID=`cat /workspace/pytorch/.ci/docker/ci_commit_pins/timm.txt`

TORCH_VISION_PIN_COMMIT=`cat /workspace/pytorch/.github/ci_commit_pins/vision.txt`
TORCH_TEXT_PIN_COMMIT=`cat /workspace/pytorch/.github/ci_commit_pins/text.txt`
TORCH_AUDIO_PIN_COMMIT=`cat /workspace/pytorch/.github/ci_commit_pins/audio.txt`

# install HF
pip install transformers==4.27.4

# install timm
pip install --no-deps git+https://github.com/huggingface/pytorch-image-models@$TIMM_COMMIT_ID
# install timm dependencies without torch and torchvision
pip install $(curl -sSL https://raw.githubusercontent.com/huggingface/pytorch-image-models/$TIMM_COMMIT_ID/requirements.txt | grep -vE torch)

# install torchbench

cd ${WORKSPACE_FOLDER}

# Torchvision
if [ ! -d "${WORKSPACE_FOLDER}/vision" ]; then
    git clone --recursive https://github.com/pytorch/vision.git
fi
cd vision
git checkout ${TORCH_VISION_PIN_COMMIT}
conda install -y libpng jpeg
# TODO: We use an older version ffmpeg to avoid the vision capability issue.
conda install -y -c conda-forge 'ffmpeg<4.4'
python setup.py install
cd ..

# Torchtext
if [ ! -d "${WORKSPACE_FOLDER}/text" ]; then
    git clone --recursive https://github.com/pytorch/text.git
fi
cd text
git checkout ${TORCH_TEXT_PIN_COMMIT}
python setup.py clean install
cd ..

# Torch audio
if [ ! -d "${WORKSPACE_FOLDER}/audio" ]; then
    git clone --recursive https://github.com/pytorch/audio.git
fi

cd audio
# Optionally `git checkout {pinned_commit}`
# git checkout ${TORCH_AUDIO_PIN_COMMIT} break in pinned_commit
python setup.py install
cd ..

# Check first
python -c "import torchvision,torchtext,torchaudio;print(torchvision.__version__, torchtext.__version__, torchaudio.__version__)"

# Torchbench
conda install -y git-lfs pyyaml pandas scipy psutil
pip install pyre_extensions
pip install torchrec
# TODO : We use a temporary private repo. Thus we don't checkout commit.
if [ ! -d "${WORKSPACE_FOLDER}/benchmark" ]; then
    git clone --recursive https://github.com/weishi-deng/benchmark
fi

# git checkout ${TORCH_BENCH_PIN_COMMIT}
cd benchmark
python install.py
pip install -e .
