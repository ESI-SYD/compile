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
echo -e "========================================================================="
echo -e "huggingface accuracy"
echo -e "========================================================================="
bash inductor_xpu_test.sh huggingface amp_bf16 inference accuracy xpu 0 & \
bash inductor_xpu_test.sh huggingface amp_bf16 training accuracy xpu 1 & \
bash inductor_xpu_test.sh huggingface amp_fp16 inference accuracy xpu 2 & \
bash inductor_xpu_test.sh huggingface amp_fp16 training accuracy xpu 3 & wait
bash inductor_xpu_test.sh huggingface bfloat16 inference accuracy xpu 0 & \
bash inductor_xpu_test.sh huggingface bfloat16 training accuracy xpu 1 & \
bash inductor_xpu_test.sh huggingface float16 inference accuracy xpu 2 & \
bash inductor_xpu_test.sh huggingface float16 training accuracy xpu 3 & wait
bash inductor_xpu_test.sh huggingface float32 inference accuracy xpu 0 & \
bash inductor_xpu_test.sh huggingface float32 training accuracy xpu 1 & wait

echo -e "========================================================================="
echo -e "timm_models accuracy"
echo -e "========================================================================="
bash inductor_xpu_test.sh timm_models amp_bf16 inference accuracy xpu 0 & \
bash inductor_xpu_test.sh timm_models amp_bf16 training accuracy xpu 1 & \
bash inductor_xpu_test.sh timm_models amp_fp16 inference accuracy xpu 2 & \
bash inductor_xpu_test.sh timm_models amp_fp16 training accuracy xpu 3 & wait
bash inductor_xpu_test.sh timm_models bfloat16 inference accuracy xpu 0 & \
bash inductor_xpu_test.sh timm_models bfloat16 training accuracy xpu 1 & \
bash inductor_xpu_test.sh timm_models float16 inference accuracy xpu 2 & \
bash inductor_xpu_test.sh timm_models float16 training accuracy xpu 3 & wait
bash inductor_xpu_test.sh timm_models float32 inference accuracy xpu 0 & \
bash inductor_xpu_test.sh timm_models float32 training accuracy xpu 1 & wait

echo -e "========================================================================="
echo -e "torchbench accuracy"
echo -e "========================================================================="
bash inductor_xpu_test.sh torchbench amp_bf16 inference accuracy xpu 0 & \
bash inductor_xpu_test.sh torchbench amp_bf16 training accuracy xpu 1 & \
bash inductor_xpu_test.sh torchbench amp_fp16 inference accuracy xpu 2 & \
bash inductor_xpu_test.sh torchbench amp_fp16 training accuracy xpu 3 & wait
bash inductor_xpu_test.sh torchbench bfloat16 inference accuracy xpu 0 & \
bash inductor_xpu_test.sh torchbench bfloat16 training accuracy xpu 1 & \
bash inductor_xpu_test.sh torchbench float16 inference accuracy xpu 2 & \
bash inductor_xpu_test.sh torchbench float16 training accuracy xpu 3 & wait
bash inductor_xpu_test.sh torchbench float32 inference accuracy xpu 0 & \
bash inductor_xpu_test.sh torchbench float32 training accuracy xpu 1 & wait

cp -r /workspace/pytorch/inductor_log /workspace/jenkins/logs