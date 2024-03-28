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
def cleanup(){
        sh '''
            cd ${WORKSPACE}
            echo -e "begin to clean the workspace"
            sudo rm -rf ../IPEX-TorchInductor-XPU-Backend-CI_ws-cleanup*
            echo -e "finish cleaning the workspace"
        '''
}
node(env.nodes_label){
    cleanWs()
    cleanup()
    stage('setup env') {
        println('================================================================')
        println('setup nodes env')
        println('================================================================')
        sh '''
        set -e
        set +x
        git clone -b ruijie/add_docker_groovy https://github.com/ESI-SYD/compile.git
        if [ ${TRITON_VERSION} == "210"];then
            cd ${WORKSPACE}/compile/scripts
            bash build-in-docker.sh 210
        else
            cd ${WORKSPACE}/compile/scripts
            bash build-in-docker.sh
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
                docker exec -i spirv-210-${CONTAINER} bash -c ". /opt/intel/oneapi/setvars.sh; \
                wget https://raw.githubusercontent.com/ESI-SYD/compile/ruijie/add_docker_groovy/scripts/install_e2e_suites.sh; \
                bash install_e2e_suites.sh"
            else
                docker exec -i llvm-target-${CONTAINER} bash -c ". /opt/intel/oneapi/setvars.sh; \
                wget https://raw.githubusercontent.com/ESI-SYD/compile/ruijie/add_docker_groovy/scripts/install_e2e_suites.sh; \
                bash install_e2e_suites.sh"
            fi
            '''
    }//stage
    if(Test_CI == 'True' || Test_CI == 'true'){
        stage('CI-Test') {
            println('================================================================')
            println('CI-Test')
            println('================================================================')
                try{
                    sh'''
                    set -e
                    set +x
                    if [ ${TRITON_VERSION} == "210"];then
                        docker exec -i spirv-210-${CONTAINER} bash -c "wget https://raw.githubusercontent.com/ESI-SYD/compile/ruijie/add_docker_groovy/scripts/ci_scripts.sh; \
                        bash ci_scripts.sh"
                    else
                        docker exec -i llvm-target-${CONTAINER} bash -c "wget https://raw.githubusercontent.com/ESI-SYD/compile/ruijie/add_docker_groovy/scripts/ci_scripts.sh; \
                        bash ci_scripts.sh"
                    fi
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
                    docker exec -i spirv-210-${CONTAINER} bash -c "wget https://raw.githubusercontent.com/ESI-SYD/compile/ruijie/add_docker_groovy/scripts/performance_scripts.sh; \
                    bash performance_scripts.sh"
                else
                    docker exec -i llvm-target-${CONTAINER} bash -c "wget https://raw.githubusercontent.com/ESI-SYD/compile/ruijie/add_docker_groovy/scripts/performance_scripts.sh; \
                    bash performance_scripts.sh"
                fi
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
                        docker exec -i spirv-210-${CONTAINER} bash -c "cd /workspace; \
                        pip install styleFrame scipy pandas; \
                        mkdir -p refer; \
                        cp -r inductor_log refer; \
                        rm -rf inductor_log; \
                        mv refer /workspace/pytorch; \
                        cd /workspace/pytorch; \
                        wget https://raw.githubusercontent.com/ESI-SYD/compile/main/scripts/inductor_perf_summary.py; \
                        python inductor_perf_summary.py -r refer -p amp_bf16 amp_fp16 bfloat16 float16 float32; \
                        python inductor_perf_summary.py -r refer -p amp_bf16 amp_fp16 bfloat16 float16 float32 -s timm_models; \
                        python inductor_perf_summary.py -r refer -p amp_bf16 amp_fp16 bfloat16 float16 float32 -s torchbench; \
                        cp -r /workspace/pytorch/inductor_log /workspace/jenkins/logs"
                    else
                        docker exec -i llvm-target-${CONTAINER} bash -c "cd /workspace; \
                        pip install styleFrame scipy pandas; \
                        mkdir -p refer; \
                        cp -r inductor_log refer; \
                        rm -rf inductor_log; \
                        mv refer /workspace/pytorch; \
                        cd /workspace/pytorch; \
                        wget https://raw.githubusercontent.com/ESI-SYD/compile/main/scripts/inductor_perf_summary.py; \
                        python inductor_perf_summary.py -r refer -p amp_bf16 amp_fp16 bfloat16 float16 float32; \
                        python inductor_perf_summary.py -r refer -p amp_bf16 amp_fp16 bfloat16 float16 float32 -s timm_models; \
                        python inductor_perf_summary.py -r refer -p amp_bf16 amp_fp16 bfloat16 float16 float32 -s torchbench; \
                        cp -r /workspace/pytorch/inductor_log /workspace/jenkins/logs"
                    fi
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
                    docker exec -i spirv-210-${CONTAINER} bash -c "wget https://raw.githubusercontent.com/ESI-SYD/compile/ruijie/add_docker_groovy/scripts/accuracy_scripts.sh; \
                    bash accuracy_scripts.sh"
                else
                    docker exec -i llvm-target-${CONTAINER} bash -c "wget https://raw.githubusercontent.com/ESI-SYD/compile/ruijie/add_docker_groovy/scripts/accuracy_scripts.sh; \
                    bash accuracy_scripts.sh"
                fi
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
                        docker exec -i spirv-210-${CONTAINER} bash -c "cd /workspace/pytorch; \
                        pip install styleFrame scipy pandas; \
                        wget https://raw.githubusercontent.com/ESI-SYD/compile/ruijie/add_docker_groovy/scripts/inductor_accuracy_results_check.sh; \
                        bash inductor_accuracy_results_check.sh; \
                        cd /workspace/pytorch; \
                        mkdir -p target; \
                        cp -r /workspace/pytorch/inductor_log /workspace/pytorch/target; \
                        wget https://raw.githubusercontent.com/ESI-SYD/compile/main/scripts/inductor_accuracy_summary.py; \
                        python inductor_accuracy_summary.py -r refer -t target -p amp_bf16 amp_fp16 bfloat16 float16 float32; \
                        python inductor_accuracy_summary.py -r refer -t target -p amp_bf16 amp_fp16 bfloat16 float16 float32 -s timm_models; \
                        python inductor_accuracy_summary.py -r refer -t target -p amp_bf16 amp_fp16 bfloat16 float16 float32 -s torchbench; \
                        cp -r /workspace/pytorch/target /workspace/jenkins/logs"
                    else
                        docker exec -i llvm-target-${CONTAINER} bash -c "cd /workspace/pytorch; \
                        pip install styleFrame scipy pandas; \
                        wget https://raw.githubusercontent.com/ESI-SYD/compile/ruijie/add_docker_groovy/scripts/inductor_accuracy_results_check.sh; \
                        bash inductor_accuracy_results_check.sh; \
                        cd /workspace/pytorch; \
                        mkdir -p target; \
                        cp -r /workspace/pytorch/inductor_log /workspace/pytorch/target; \
                        wget https://raw.githubusercontent.com/ESI-SYD/compile/main/scripts/inductor_accuracy_summary.py; \
                        python inductor_accuracy_summary.py -r refer -t target -p amp_bf16 amp_fp16 bfloat16 float16 float32; \
                        python inductor_accuracy_summary.py -r refer -t target -p amp_bf16 amp_fp16 bfloat16 float16 float32 -s timm_models; \
                        python inductor_accuracy_summary.py -r refer -t target -p amp_bf16 amp_fp16 bfloat16 float16 float32 -s torchbench; \
                        cp -r /workspace/pytorch/target /workspace/jenkins/logs"
                    fi
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
