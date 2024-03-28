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
mkdir -p /workspace/jenkins/logs
echo -e "========================================================================="
echo -e "CI HF test Begin"
echo -e "========================================================================="
#pip install tokenizers==0.13 pandas
pip install pandas
bash inductor_xpu_test.sh huggingface amp_bf16 training accuracy xpu 3
cp -r /workspace/pytorch/inductor_log /workspace/jenkins/logs
python -c "import triton;print(triton.__version__)"

echo -e "========================================================================="
echo -e "CI Torchbench test Begin"
echo -e "========================================================================="
cd ${WORKSPACE_FOLDER}
# Torchbench
pip install transformers==4.38.1 --no-deps
pip install timm==0.9.7 --no-deps

apt-get update -y
apt install libgl1-mesa-glx -y
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
git checkout fb0dfed4c8c8ab1c9816b02832f7a99d86ee4ca5
python install.py
pip install -e .

cd /workspace/pytorch
bash inductor_xpu_test.sh torchbench amp_fp16 inference accuracy xpu 3

cp -r /workspace/pytorch/inductor_log /workspace/jenkins/logs

echo -e "========================================================================="
echo -e "accuracy results check"
echo -e "========================================================================="

cd /workspace/pytorch/inductor_log/huggingface
cd amp_bf16
echo -e "============ Acc Check for HF amp_bf16 Training ============" | tee -a /workspace/jenkins/logs/e2e_summary.log
csv_lines_train=$(cat inductor_huggingface_amp_bf16_training_xpu_accuracy.csv | wc -l)
let num_total_amp_bf16=csv_lines_train-1
echo "num_total_amp_bf16: $num_total_amp_bf16" | tee -a /workspace/jenkins/logs/e2e_summary.log
num_passed_amp_bf16_tra=$(grep "pass" inductor_huggingface_amp_bf16_training_xpu_accuracy.csv | wc -l)
let num_failed_amp_bf16_tra=num_total_amp_bf16-num_passed_amp_bf16_tra
amp_bf16_tra_acc_pass_rate=`awk 'BEGIN{printf "%.2f%%",('$num_passed_amp_bf16_tra'/'$num_total_amp_bf16')*100}'`
echo "num_passed_amp_bf16_tra: $num_passed_amp_bf16_tra" | tee -a /workspace/jenkins/logs/e2e_summary.log
echo "num_failed_amp_bf16_tra: $num_failed_amp_bf16_tra" | tee -a /workspace/jenkins/logs/e2e_summary.log
echo "amp_bf16_tra_acc_pass_rate: $amp_bf16_tra_acc_pass_rate" | tee -a /workspace/jenkins/logs/e2e_summary.log

cd /workspace/pytorch/inductor_log/torchbench
cd amp_fp16
echo -e "============ Acc Check for torchbench amp_fp16 ============" | tee -a /workspace/jenkins/logs/e2e_summary.log
csv_lines_inf=$(cat inductor_torchbench_amp_fp16_inference_xpu_accuracy.csv | wc -l)
let num_total_amp_fp16=csv_lines_inf-1
num_passed_amp_fp16_inf=$(grep "pass" inductor_torchbench_amp_fp16_inference_xpu_accuracy.csv | wc -l)
let num_failed_amp_fp16_inf=num_total_amp_fp16-num_passed_amp_fp16_inf
amp_fp16_inf_acc_pass_rate=`awk 'BEGIN{printf "%.2f%%",('$num_passed_amp_fp16_inf'/'$num_total_amp_fp16')*100}'`
echo "num_total_amp_fp16: $num_total_amp_fp16" | tee -a /workspace/jenkins/logs/e2e_summary.log
echo "num_passed_amp_fp16_inf: $num_passed_amp_fp16_inf" | tee -a /workspace/jenkins/logs/e2e_summary.log
echo "num_failed_amp_fp16_inf: $num_failed_amp_fp16_inf" | tee -a /workspace/jenkins/logs/e2e_summary.log
echo "amp_fp16_inf_acc_pass_rate: $amp_fp16_inf_acc_pass_rate" | tee -a /workspace/jenkins/logs/e2e_summary.log