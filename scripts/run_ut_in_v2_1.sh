#!/bin/bash
## run in /workspace/intel-xpu-backend-for-triton
## refer to https://github.com/intel/intel-xpu-backend-for-triton/blob/spirv-target/.github/workflows/triton_xpu_backend_ci.yml
source /opt/intel/oneapi/setvars.sh
pip install pytest
rm -rf ~/.triton/cache
export TRITON_LIBDEVICE_PATH=/workspace/triton_src/python/triton/third_party/xpu/lib
cd /workspace/triton_src/python/test/unit/language
bash /workspace/triton_src/third_party/intel_xpu_backend/.github/scripts/case_update.sh
ZE_AFFINITY_MASK=1 pytest -n 32 -v -ra --tb=line . --device=xpu 2>&1 | tee /workspace/triton_src/python/test/unit/ut_raw.log || true
cd /workspace/triton_src/python/test/unit
ZE_AFFINITY_MASK=1 pytest -n 32 --ignore=hopper --ignore=language -v -ra --tb=line 2>&1 | tee -a /workspace/triton_src/python/test/unit/ut_raw.log || true
res=$(cat ut_raw.log | sed -n '7p' |  awk '{print $NF}')
if [ "$res" == "error" ]; then
echo -e "[ERROR] IPEX PVC Triton UT FAIL"
exit 1
fi
cd /workspace/triton_src/python/test/unit
echo -e "============ UT Status Overview ============" | tee ./ut_summary.log
grep "^FAILED" ut_raw.log | awk '{print $2}' > ./ut_failed.log
grep "^SKIPPED" ut_raw.log | awk '{print $2}' | grep -o '[0-9]\+' > ./ut_skipped.log
grep "^SKIPPED.*Only for cuda" ut_raw.log | awk '{print $2}' | grep -o '[0-9]\+' > ./ut_cuda_only_skipped.log
grep "PASSED" ut_raw.log | awk '{print $5}' > ./ut_passed.log
num_failed=$(cat ./ut_failed.log | wc -l)
num_skipped=$(echo $(echo -n `cat ./ut_skipped.log | awk '{print $1}'`| tr ' ' '+')|bc)
num_cuda_only_skipped=$(cat ./ut_cuda_only_skipped.log | awk '{print $1}')
num_passed=$(cat ./ut_passed.log | wc -l)
num_language=$(grep "items" ut_raw.log | awk '{print $3}' | grep -o '[0-9]\+' | awk 'NR==1')
num_others=$(grep "items" ut_raw.log | awk '{print $3}' | grep -o '[0-9]\+' | awk 'NR==2')
let num_total=$num_language+$num_others
let num_total_wo_skipped=num_total-num_skipped+num_cuda_only_skipped-3
total_pass_rate=`awk 'BEGIN{printf "%.2f%%\n",('$num_passed'/'$num_total_wo_skipped')*100}'`
if [ -z $num_total ]; then num_total=0; fi
echo "num_language: $num_language" | tee -a ./ut_summary.log
echo "num_others: $num_others" | tee -a ./ut_summary.log
echo "num_total: $num_total" | tee -a ./ut_summary.log
echo "num_skipped: $num_skipped" | tee -a ./ut_summary.log
echo "num_cuda_only_skipped: $num_cuda_only_skipped" | tee -a ./ut_summary.log
echo "num_failed: $num_failed" | tee -a ./ut_summary.log
echo "num_passed: $num_passed" | tee -a ./ut_summary.log
echo "total_pass_rate: $total_pass_rate" | tee -a ./ut_summary.log