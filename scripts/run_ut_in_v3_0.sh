#!/bin/bash
## run in /workspace/intel-xpu-backend-for-triton
## refer to https://github.com/intel/intel-xpu-backend-for-triton/blob/llvm-target/.github/workflows/build-test.yml
source /opt/intel/oneapi/setvars.sh
pip install wheel pytest pytest-xdist pytest-rerunfailures
mkdir ~/reports
cd python/test/unit
python3 -m pytest --junitxml=~/reports/language.xml -n 8 --verbose --device xpu language/ --ignore=language/test_line_info.py
# run runtime tests serially to avoid race condition with cache handling.
python3 -m pytest --junitxml=~/reports/runtime.xml --device xpu runtime/
# run test_line_info.py separately with TRITON_DISABLE_LINE_INFO=0
TRITON_DISABLE_LINE_INFO=0 python3 -m pytest --junitxml=~/reports/line_info.xml --verbose --device xpu language/test_line_info.py

rm -rf ~/.triton

export TRITON_INTERPRET=1
cd python/test/unit
python3 -m pytest --junitxml=~/reports/interpreter_core.xml -vvv -n 4 -m interpreter language/test_core.py --device cpu
python3 -m pytest --junitxml=~/reports/interpreter_flash_attention.xml -n 8 -m interpreter -vvv -s operators/test_flash_attention.py::test_op --device cpu

export TRITON_INTERPRET=0
cd python/test/unit
python3 -m pytest --junitxml=~/reports/operators.xml -n 8 --verbose --device xpu operators

python3 scripts/pass_rate.py --reports ~/reports > ut_v3_0_pass_rate.txt