#!/bin/bash
set -e

echo "============================================================================== XPU-SMI Device Dump ==============================================================================="
if command -v xpu-smi &> /dev/null; then
    xpu-smi discovery --dump 2,6,8,9,19,22
else
    echo "xpu-smi cli Not installed"
    echo "refero to https://github.com/intel/xpumanager?tab=readme-ov-file#how-to-get-xpu-manager-xpu-smi-windows-cli-and-amcmcli-binaries"
fi

echo "============================================================================== Driver Components Info ============================================================================"
dpkg -l | grep intel
dpkg -l | grep dkms
dpkg -l | grep igc