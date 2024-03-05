#!/bin/bash
set -e
BASE=${1:-workspace}

function get_branch_commit () {
    cd /$BASE/$1
    echo "$1 branch: " $(git rev-parse --abbrev-ref HEAD)
    echo "$1 commit: " $(git rev-parse HEAD)
}

echo "################ Main components Commits ###########################"
get_branch_commit "pytorch"
get_branch_commit "ipex"
get_branch_commit "audio"
get_branch_commit "vision"
get_branch_commit "text"
get_branch_commit "benchmark"
get_branch_commit "intel-xpu-backend-for-triton"
