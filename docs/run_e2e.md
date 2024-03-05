

#1. docker env 
```
cd scripts
3.0: bash build-in-docker.sh
2.1: bash build-in-docker.sh 210
```

#2. launch a tmux 
```
tmux new -s triton-xpu-test
tmux a -t triton-xpu-test
```
#3. run into container
```
3.0:  docker exec -ti llvm-target bash
2.1: docker exec -ti spirv-210 bash
```
#4. install e2e suites
```
cd /workspace
source /opt/intel/oneapi/setvars.sh
wget https://raw.githubusercontent.com/ESI-SYD/compile/main/scripts/install_e2e_suites.sh
bash install_e2e_suites.sh
```
[Note, check timm transformers version]

#5. run
```
cd /workspace/pytorch
source /opt/intel/oneapi/setvars.sh
wget https://raw.githubusercontent.com/intel/intel-xpu-backend-for-triton/llvm-target/scripts/inductor_xpu_test.sh
echo -e "========================================================================="
date +"%Y-%m-%d %H:%M:%S"
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
```
