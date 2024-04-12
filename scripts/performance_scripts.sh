WORKSPACE_FOLDER=/workspace
cd /workspace/pytorch
source /opt/intel/oneapi/setvars.sh
export HUGGING_FACE_HUB_TOKEN=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

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
#pip install tokenizers==0.13 
pip install tqdm pandas scipy
mkdir -p /workspace/jenkins/logs
echo -e "========================================================================="
echo -e "huggingface performance"
echo -e "========================================================================="
bash inductor_xpu_test.sh huggingface amp_bf16 inference performance xpu 0 & \
bash inductor_xpu_test.sh huggingface amp_bf16 training performance xpu 1 & \
bash inductor_xpu_test.sh huggingface amp_fp16 inference performance xpu 2 & \
bash inductor_xpu_test.sh huggingface amp_fp16 training performance xpu 3 & wait
bash inductor_xpu_test.sh huggingface bfloat16 inference performance xpu 0 & \
bash inductor_xpu_test.sh huggingface bfloat16 training performance xpu 1 & \
bash inductor_xpu_test.sh huggingface float16 inference performance xpu 2 & \
bash inductor_xpu_test.sh huggingface float16 training performance xpu 3 & wait
bash inductor_xpu_test.sh huggingface float32 inference performance xpu 0 & \
bash inductor_xpu_test.sh huggingface float32 training performance xpu 1 & wait

echo -e "========================================================================="
echo -e "timm_models performance"
echo -e "========================================================================="
pip install --no-deps "git+https://github.com/rwightman/pytorch-image-models@b9d43c7dcac1fe05e851dd7be7187b108af593d2"
bash inductor_xpu_test.sh timm_models amp_bf16 inference performance xpu 0 & \
bash inductor_xpu_test.sh timm_models amp_bf16 training performance xpu 1 & \
bash inductor_xpu_test.sh timm_models amp_fp16 inference performance xpu 2 & \
bash inductor_xpu_test.sh timm_models amp_fp16 training performance xpu 3 & wait
bash inductor_xpu_test.sh timm_models bfloat16 inference performance xpu 0 & \
bash inductor_xpu_test.sh timm_models bfloat16 training performance xpu 1 & \
bash inductor_xpu_test.sh timm_models float16 inference performance xpu 2 & \
bash inductor_xpu_test.sh timm_models float16 training performance xpu 3 & wait
bash inductor_xpu_test.sh timm_models float32 inference performance xpu 0 & \
bash inductor_xpu_test.sh timm_models float32 training performance xpu 1 & wait

echo -e "========================================================================="
echo -e "torchbench performance"
echo -e "========================================================================="
pip install transformers==4.38.1 --no-deps
pip install timm==0.9.7 --no-deps
pip install tqdm pandas pyre-extensions torchrec tensorboardX dalle2_pytorch torch_geometric scikit-image matplotlib  gym fastNLP doctr matplotlib opacus python-doctr higher opacus dominate kaldi-io librosa effdet pycocotools diffusers
pip uninstall -y pyarrow pandas
pip install pyarrow pandas

git clone https://github.com/facebookresearch/detectron2.git
python -m pip install -e detectron2

git clone --recursive https://github.com/facebookresearch/multimodal.git multimodal
pushd multimodal
pip install -e .
popd

if [ ! -d "${WORKSPACE_FOLDER}/benchmark" ]; then
    git clone --recursive https://github.com/weishi-deng/benchmark
fi

# git checkout ${TORCH_BENCH_PIN_COMMIT}
cd benchmark
git checkout fb0dfed4c8c8ab1c9816b02832f7a99d86ee4ca5
python install.py
pip install -e .

cd /workspace/pytorch
bash inductor_xpu_test.sh torchbench amp_bf16 inference performance xpu 0 & \
bash inductor_xpu_test.sh torchbench amp_bf16 training performance xpu 1 & \
bash inductor_xpu_test.sh torchbench amp_fp16 inference performance xpu 2 & \
bash inductor_xpu_test.sh torchbench amp_fp16 training performance xpu 3 & wait
bash inductor_xpu_test.sh torchbench bfloat16 inference performance xpu 0 & \
bash inductor_xpu_test.sh torchbench bfloat16 training performance xpu 1 & \
bash inductor_xpu_test.sh torchbench float16 inference performance xpu 2 & \
bash inductor_xpu_test.sh torchbench float16 training performance xpu 3 & wait
bash inductor_xpu_test.sh torchbench float32 inference performance xpu 0 & \
bash inductor_xpu_test.sh torchbench float32 training performance xpu 1 & wait

cp -r /workspace/pytorch/inductor_log /workspace/jenkins/logs
