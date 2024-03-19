

#1. docker env 
```
git clone https://github.com/ESI-SYD/compile.git
cd compile/scripts
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
# If triton is 2.1 version, please add this flag
export TRITON_XPU_USE_LEGACY_API=1
bash run_e2e.sh all performance

```
