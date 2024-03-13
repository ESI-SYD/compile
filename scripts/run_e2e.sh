#!/bin/bash
## you should run this script with 4 GPU cards support within docker env
TEST_SUITE=${1:-all}
TEST_MODE=${2:-performance}

# activate oneapi
source /opt/intel/oneapi/setvars.sh

# prepare to run the benchmark
cd /workspace/pytorch
wget https://raw.githubusercontent.com/intel/intel-xpu-backend-for-triton/scripts/inductor_xpu_test.sh

if [ "$TEST_SUITE" == "huggingface" ] || [ "$TEST_SUITE" == "all" ]; then
    bash inductor_xpu_test.sh huggingface amp_bf16 inference $TEST_MODE xpu 0 & \
    bash inductor_xpu_test.sh huggingface amp_bf16 training $TEST_MODE xpu 1 & \
    bash inductor_xpu_test.sh huggingface amp_fp16 inference $TEST_MODE xpu 2 & \
    bash inductor_xpu_test.sh huggingface amp_fp16 training $TEST_MODE xpu 3 & wait
    bash inductor_xpu_test.sh huggingface bfloat16 inference $TEST_MODE xpu 0 & \
    bash inductor_xpu_test.sh huggingface bfloat16 training $TEST_MODE xpu 1 & \
    bash inductor_xpu_test.sh huggingface float16 inference $TEST_MODE xpu 2 & \
    bash inductor_xpu_test.sh huggingface float16 training $TEST_MODE xpu 3 & wait
    bash inductor_xpu_test.sh huggingface float32 inference $TEST_MODE xpu 0 & \
    bash inductor_xpu_test.sh huggingface float32 training $TEST_MODE xpu 1 & wait
fi

if [ "$TEST_SUITE" == "timm_models" ] || [ "$TEST_SUITE" == "all" ]; then
    bash inductor_xpu_test.sh timm_models amp_bf16 inference $TEST_MODE xpu 0 & \
    bash inductor_xpu_test.sh timm_models amp_bf16 training $TEST_MODE xpu 1 & \
    bash inductor_xpu_test.sh timm_models amp_fp16 inference $TEST_MODE xpu 2 & \
    bash inductor_xpu_test.sh timm_models amp_fp16 training $TEST_MODE xpu 3 & wait
    bash inductor_xpu_test.sh timm_models bfloat16 inference $TEST_MODE xpu 0 & \
    bash inductor_xpu_test.sh timm_models bfloat16 training $TEST_MODE xpu 1 & \
    bash inductor_xpu_test.sh timm_models float16 inference $TEST_MODE xpu 2 & \
    bash inductor_xpu_test.sh timm_models float16 training $TEST_MODE xpu 3 & wait
    bash inductor_xpu_test.sh timm_models float32 inference $TEST_MODE xpu 0 & \
    bash inductor_xpu_test.sh timm_models float32 training $TEST_MODE xpu 1 & wait
fi

# install and run Torchbench benchmark at last to avoid modifying pytorch and triton implicitly
if [ "$TEST_SUITE" == "torchbench" ] || [ "$TEST_SUITE" == "all" ]; then
    cd /workspace
    # install Torchbench
    conda install -y git-lfs pyyaml pandas scipy psutil
    pip install tqdm pandas pyre-extensions torchrec tensorboardX dalle2_pytorch torch_geometric scikit-image matplotlib  gym fastNLP doctr matplotlib opacus python-doctr higher opacus dominate kaldi-io librosa effdet pycocotools diffusers
    pip uninstall -y pyarrow pandas
    pip install pyarrow pandas

    git clone https://github.com/facebookresearch/detectron2.git
    python -m pip install -e detectron2

    git clone --recursive https://github.com/facebookresearch/multimodal.git multimodal
    pushd multimodal
    pip install -e .
    popd

    # TODO : We use a temporary private repo. Thus we don't checkout commit.
    if [ ! -d "${WORKSPACE_FOLDER}/benchmark" ]; then
        git clone --recursive https://github.com/weishi-deng/benchmark
    fi

    # git checkout ${TORCH_BENCH_PIN_COMMIT}
    cd benchmark
    python install.py
    pip install -e .
    # run torchbench benchmark
    cd /workspace/pytorch
    bash inductor_xpu_test.sh torchbench amp_bf16 inference $TEST_MODE xpu 0 & \
    bash inductor_xpu_test.sh torchbench amp_bf16 training $TEST_MODE xpu 1 & \
    bash inductor_xpu_test.sh torchbench amp_fp16 inference $TEST_MODE xpu 2 & \
    bash inductor_xpu_test.sh torchbench amp_fp16 training $TEST_MODE xpu 3 & wait
    bash inductor_xpu_test.sh torchbench bfloat16 inference $TEST_MODE xpu 0 & \
    bash inductor_xpu_test.sh torchbench bfloat16 training $TEST_MODE xpu 1 & \
    bash inductor_xpu_test.sh torchbench float16 inference $TEST_MODE xpu 2 & \
    bash inductor_xpu_test.sh torchbench float16 training $TEST_MODE xpu 3 & wait
    bash inductor_xpu_test.sh torchbench float32 inference $TEST_MODE xpu 0 & \
    bash inductor_xpu_test.sh torchbench float32 training $TEST_MODE xpu 1 & wait    
fi