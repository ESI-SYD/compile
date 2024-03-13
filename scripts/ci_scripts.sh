WORKSPACE_FOLDER=/workspace
cd /workspace/pytorch
source /opt/intel/oneapi/setvars.sh

if [ -e /workspace/pytorch/inductor_xpu_test.sh ];then
    echo -e "inductor_xpu_test.sh ready"
else
    wget https://raw.githubusercontent.com/intel/intel-xpu-backend-for-triton/llvm-target/scripts/inductor_xpu_test.sh
fi

if [ ${TRITON_VERSION} == "210" ];then
    export TRITON_XPU_USE_LEGACY_API=1
else
    echo -e "No need to set flag for triton3.0"
fi
mkdir -p /workspace/jenkins/logs
echo -e "========================================================================="
echo -e "CI test Begin"
echo -e "========================================================================="
pip install tokenizers==0.13 pandas
bash inductor_xpu_test.sh huggingface amp_bf16 training accuracy xpu 3 & \

python -c "import triton;print(triton.__version__)"

cd ${WORKSPACE_FOLDER}
# Torchbench
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

cd /workspace/pytorch
bash inductor_xpu_test.sh torchbench amp_fp16 inference accuracy xpu 3 & wait

cp -r /workspace/pytorch/inductor_log /workspace/jenkins/logs
