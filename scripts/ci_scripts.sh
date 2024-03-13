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
echo -e "CI test Begin"
echo -e "========================================================================="
bash inductor_xpu_test.sh huggingface amp_bf16 training accuracy xpu 3 & \
bash inductor_xpu_test.sh torchbench amp_fp16 inference accuracy xpu 3 & wait

cp -r /workspace/pytorch/inductor_log /workspace/jenkins/logs
