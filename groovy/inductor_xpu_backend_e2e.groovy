def report(){
    try{
        if(refer_build != '0') {
            copyArtifacts(
                projectName: "IPEX-TorchInductor-XPU-Backend",
                selector: specific("${refer_build}"),
                filter: 'inductor_log/',
                fingerprintArtifacts: true,
                )
        }
    }catch(err){
        echo err.getMessage()
    }
}

node(env.nodes_label){
    cleanWs()
    stage('setup env') {
        println('================================================================')
        println('setup nodes env')
        println('================================================================')
        checkout scm
        sh '''
        set -e
        set +x
        if [ ${TRITON_VERSION} == "210"];then
            bash ${WORKSPACE}/scripts/build-in-docker.sh 210
        else
            bash ${WORKSPACE}/scripts/build-in-docker.sh
        fi
        '''
    }//stage
    stage('Install Dependency') {
        println('================================================================')
        println('Install Dependency')
        println('================================================================')
            sh '''
            set -e
            set +x
            if [ ${TRITON_VERSION} == "210"];then
                docker exec -ti spirv-210-${CONTAINER} bash
            else
                docker exec -ti llvm-target-${CONTAINER} bash
            fi

            cd /workspace
            source /opt/intel/oneapi/setvars.sh
            export http_proxy= http://child-jf.intel.com:912
            export https_proxy= http://child-jf.intel.com:912
            wget https://raw.githubusercontent.com/ESI-SYD/compile/main/scripts/install_e2e_suites.sh
            bash install_e2e_suites.sh
            '''
    }//stage
    if(Test_CI == 'True' || Test_CI == 'true'){
        stage('CI-Test') {
            println('================================================================')
            println('CI-Test')
            println('================================================================')
                sh'''
                set -e
                set +x
                if [ ${TRITON_VERSION} == "210"];then
                    docker exec -ti spirv-210-${CONTAINER} bash
                else
                    docker exec -ti llvm-target-${CONTAINER} bash
                fi
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
                '''   
        }
    }else{
        stage('Performance-Test') {
            println('================================================================')
            println('Performance-Test')
            println('================================================================')
                sh'''
                set -e
                set +x
                if [ ${TRITON_VERSION} == "210"];then
                    docker exec -ti spirv-210-${CONTAINER} bash
                else
                    docker exec -ti llvm-target-${CONTAINER} bash
                fi
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
                '''
        }//stage
        stage('Perf Test Results Generate and Overview') {
            println('================================================================')
            println('Perf Test Results Generate and Overview')
            println('================================================================')
                try{
                    report()
                    sh'''
                    set -e
                    set +x
                    if [ ${TRITON_VERSION} == "210"];then
                        docker exec -ti spirv-210-${CONTAINER} bash
                    else
                        docker exec -ti llvm-target-${CONTAINER} bash
                    fi
                    cd /workspace/pytorch
                    wget https://raw.githubusercontent.com/ESI-SYD/compile/main/scripts/inductor_perf_summary.py
                    python inductor_perf_summary.py -r refer -p amp_bf16 amp_fp16 bfloat16 float16 float32
                    python inductor_perf_summary.py -r refer -p amp_bf16 amp_fp16 bfloat16 float16 float32 -s timm_models
                    python inductor_perf_summary.py -r refer -p amp_bf16 amp_fp16 bfloat16 float16 float32 -s torchbench
                    
                    cp -r /workspace/pytorch/inductor_log /workspace/jenkins/logs
                    '''
                }catch (Exception e) {
                    println('================================================================')
                    println('Exception')
                    println('================================================================')v
                    println(e.toString())
                }finally {
                    dir("${WORKSPACE}/logs") {
                        archiveArtifacts '**'
                    }//dir
                }//finally
        }//stage
        stage('Accuracy-Test') {
            println('================================================================')
            println('Accuracy-Test')
            println('================================================================')
                sh'''
                set +e
                set +x
                if [ ${TRITON_VERSION} == "210"];then
                    docker exec -ti spirv-210-${CONTAINER} bash
                else
                    docker exec -ti llvm-target-${CONTAINER} bash
                fi
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
                '''
        }//stage
        stage('ACC Test Results Overview') {
            println('================================================================')
            println('ACC Test Results Overview')
            println('================================================================')
                try {
                    sh'''
                    #! bin/bash
                    set +e
                    set +x
                    if [ ${TRITON_VERSION} == "210"];then
                        docker exec -ti spirv-210-${CONTAINER} bash
                    else
                        docker exec -ti llvm-target-${CONTAINER} bash
                    fi
                    cd /workspace/pytorch
                    wget https://raw.githubusercontent.com/ESI-SYD/compile/ruijie/add_docker_groovy/scripts/inductor_accuracy_results_check.sh
                    bash inductor_accuracy_results_check.sh
                    '''
                }catch (Exception e) {
                    println('================================================================')
                    println('Exception')
                    println('================================================================')v
                    println(e.toString())
                }finally {
                    dir("${WORKSPACE}/logs") {
                        archiveArtifacts '**'
                    }//dir
                }//finally
        }//stage
    }//if
}//node
