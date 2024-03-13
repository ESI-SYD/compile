cd /workspace/pytorch
source /opt/intel/oneapi/setvars.sh

if [ -e /workspace/pytorch/inductor_xpu_test.sh ];then
    echo -e "inductor_xpu_test.sh ready"
else
    wget https://raw.githubusercontent.com/intel/intel-xpu-backend-for-triton/llvm-target/scripts/inductor_xpu_test.sh
fi

if [ ${TRITON_VERSION} == "210"];then
    export TRITON_XPU_USE_LEGACY_API=1
else
    echo -e "No need to set flag for triton3.0"
fi
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
pip install tqdm pandas pyre-extensions torchrec tensorboardX dalle2_pytorch torch_geometric scikit-image matplotlib  gym fastNLP doctr matplotlib opacus python-doctr higher opacus dominate kaldi-io librosa effdet pycocotools diffusers
pip uninstall -y pyarrow pandas
pip install pyarrow pandas

git clone https://github.com/facebookresearch/detectron2.git
python -m pip install -e detectron2

git clone --recursive https://github.com/facebookresearch/multimodal.git multimodal
pushd multimodal
pip install -e .
popd

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