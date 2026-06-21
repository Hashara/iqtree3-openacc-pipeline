
pipeline {
    agent any
    parameters {
        string(name: 'BRANCH', defaultValue: 'master', description: 'Branch to build')
        booleanParam(defaultValue: true, description: 'Clone IQ-TREE?', name: 'CLONE_IQTREE')
        string(name: 'NCI_ALIAS', defaultValue: 'nci_gadi', description: 'ssh alias, if you do not have one, create one')


        string(name: 'WORKING_DIR', defaultValue: '/scratch/dx61/sa0557/iqtree2/ci-cd', description: 'Working directory')

        booleanParam(defaultValue: true, description: 'QSUB?', name: 'QSUB')


        booleanParam(defaultValue: true, description: 'Vanila (GCC)?', name: 'VANILA')
        booleanParam(defaultValue: false, description: 'Vanila (Clang)?', name: 'CLANG_VANILA')
        booleanParam(defaultValue: false, description: 'Vanila (Intel oneAPI on normalsr / Sapphire Rapids)?', name: 'INTEL_VANILA')
        booleanParam(defaultValue: false, description: 'Vanila (Intel oneAPI on normal / Cascade Lake)?', name: 'INTEL_VANILA_CLX')
        booleanParam(defaultValue: true, description: 'CUDA intergration?', name: 'CUDA')
        booleanParam(defaultValue: false, description: 'IQTREE_GPU (in-tree CUDA ModelFinder kernels)?', name: 'IQTREE_GPU')
        booleanParam(defaultValue: true, description: 'OpenACC implementation?', name: 'OPENACC')
        booleanParam(defaultValue: false, description: 'OpenACC with profiling instrumentation?', name: 'OPENACC_PROFILE')
        booleanParam(defaultValue: false, description: 'OpenACC with debug build?', name: 'OPENACC_DEBUG')
        booleanParam(defaultValue: false, description: 'OpenACC with debug build + profiling instrumentation?', name: 'OPENACC_DEBUG_PROFILE')
        booleanParam(defaultValue: false, description: 'OpenMP GPU implementation?', name: 'OPENMP_GPU')
        booleanParam(defaultValue: false, description: 'OpenMP GPU with profiling instrumentation?', name: 'OPENMP_GPU_PROFILE')
        booleanParam(defaultValue: false, description: 'OpenMP GPU with debug build?', name: 'OPENMP_GPU_DEBUG')
        booleanParam(defaultValue: false, description: 'OpenMP GPU with debug build + profiling instrumentation?', name: 'OPENMP_GPU_DEBUG_PROFILE')
        string(name: 'GPU_ARCH', defaultValue: '', description: 'GPU architecture (e.g. cc70, cc80, cc90). Empty = multi-arch default. Ignored when any of V100/A100/H200 below is selected.')

        // Per-arch single-target builds. When any of these is true, each enabled arch produces a separate build dir suffixed with -v100/-a100/-h200 (cc70/cc80/cc90 respectively). H200 shares Hopper cc90 with H100.
        booleanParam(defaultValue: false, description: 'Build dedicated single-arch binary for V100 (cc70)?', name: 'V100')
        booleanParam(defaultValue: false, description: 'Build dedicated single-arch binary for A100 (cc80)?', name: 'A100')
        booleanParam(defaultValue: false, description: 'Build dedicated single-arch binary for H200 (cc90)?', name: 'H200')


    }
    environment {
        IQTREE_GIT_URL = "git@github.com:hashara/iqtree3.git"
        NCI_ALIAS = "${params.NCI_ALIAS}"
        WORKING_DIR = "${params.WORKING_DIR}"
        GIT_REPO = "iqtree3"
        BUILD_SCRIPTS = "${WORKING_DIR}/build-scripts"
        IQTREE_DIR = "${WORKING_DIR}/${GIT_REPO}"
        BUILD_OUTPUT_DIR = "${WORKING_DIR}/builds"
        CLONE_IQTREE = "${params.CLONE_IQTREE}"
        QSUB = "${params.QSUB}"
        GPU_ARCH = "${params.GPU_ARCH}"

        // build directories
        BUILD_GCC_VANILA = "${BUILD_OUTPUT_DIR}/build-vanila"
        BUILD_CLANG_VANILA = "${BUILD_OUTPUT_DIR}/build-clang-vanila"
        BUILD_INTEL_VANILA = "${BUILD_OUTPUT_DIR}/build-intel-vanila"
        BUILD_INTEL_VANILA_CLX = "${BUILD_OUTPUT_DIR}/build-intel-vanila-clx"
        BUILD_NVHPC_CUDA = "${BUILD_OUTPUT_DIR}/build-nvhpc-cuda"
        BUILD_NVHPC_IQTREE_GPU = "${BUILD_OUTPUT_DIR}/build-nvhpc-iqtree-gpu"
        BUILD_NVHPC_OPENACC = "${BUILD_OUTPUT_DIR}/build-nvhpc-openacc"
        BUILD_NVHPC_PROF_OPENACC = "${BUILD_OUTPUT_DIR}/build-nvhpc-prof-openacc"
        BUILD_NVHPC_DEBUG_OPENACC = "${BUILD_OUTPUT_DIR}/build-nvhpc-debug-openacc"
        BUILD_NVHPC_DEBUG_PROF_OPENACC = "${BUILD_OUTPUT_DIR}/build-nvhpc-debug-prof-openacc"
        BUILD_NVHPC_OPENMP_GPU = "${BUILD_OUTPUT_DIR}/build-nvhpc-openmp-gpu"
        BUILD_NVHPC_PROF_OPENMP_GPU = "${BUILD_OUTPUT_DIR}/build-nvhpc-prof-openmp-gpu"
        BUILD_NVHPC_DEBUG_OPENMP_GPU = "${BUILD_OUTPUT_DIR}/build-nvhpc-debug-openmp-gpu"
        BUILD_NVHPC_DEBUG_PROF_OPENMP_GPU = "${BUILD_OUTPUT_DIR}/build-nvhpc-debug-prof-openmp-gpu"


    }
    stages {
        // ssh to NCI_ALIAS and scp build-scripts to working dir in NCI
        stage('Copy build scripts') {
            steps {
                script {
                    sh "pwd"
                    sh "scp -r build-scripts ${NCI_ALIAS}:${WORKING_DIR}"
                }
            }
        }
        stage('Setup environment') {
            steps {
                script {
                    if ("$CLONE_IQTREE" == "true") {
                        echo "Cloning IQ-TREE"
                        // remove existing IQ-TREE
                        cleanIQTree()

                        sh """
                        ssh ${NCI_ALIAS} << EOF
                        mkdir -p ${WORKING_DIR}
                        cd  ${WORKING_DIR}
                        git clone --recursive ${IQTREE_GIT_URL}
                        cd ${GIT_REPO}
                        git checkout ${params.BRANCH}
                        mkdir -p ${BUILD_OUTPUT_DIR}
                        mkdir -p ${BUILD_SCRIPTS}
                        cd ${BUILD_OUTPUT_DIR}
                       
                        exit
                        
                        """

                    }
                    else {
                        echo "Using existing IQ-TREE"
                    }
                }
            }
        }

        stage("Build: Build Vanila") {
            steps {
                script {

                    echo "building GCC vanila version"

                    if ("${params.VANILA}" == "true") {
                        runBuildScript("jenkins-cmake-build-gcc.sh", "${BUILD_GCC_VANILA}", "", "${QSUB}")
                    }


                }
            }
        }

        stage("Build: Build Clang Vanila") {
            steps {
                script {

                    echo "building Clang vanila version"

                    if ("${params.CLANG_VANILA}" == "true") {
                        runBuildScript("jenkins-cmake-build-clang-vanila.sh", "${BUILD_CLANG_VANILA}", "", "${QSUB}")
                    }

                }
            }
        }

        stage("Build: Build Intel Vanila (normalsr)") {
            steps {
                script {

                    echo "building Intel oneAPI vanila version on normalsr (Sapphire Rapids)"

                    if ("${params.INTEL_VANILA}" == "true") {
                        runBuildScript("jenkins-cmake-build-intel-vanila.sh", "${BUILD_INTEL_VANILA}", "", "${QSUB}")
                    }

                }
            }
        }

        stage("Build: Build Intel Vanila (CLX)") {
            steps {
                script {

                    echo "building Intel oneAPI vanila version on normal (Cascade Lake)"

                    if ("${params.INTEL_VANILA_CLX}" == "true") {
                        runBuildScript("jenkins-cmake-build-intel-clx.sh", "${BUILD_INTEL_VANILA_CLX}", "", "${QSUB}")
                    }

                }
            }
        }

        stage("Build: Build NVHPC CUDA") {
            steps {


                script {

                    echo "building NVHPC CUDA version"

                    if ("${params.CUDA}" == "true") {
                        runBuildScript("jenkins-cmake-build-nvhpc.sh", "${BUILD_NVHPC_CUDA}", "CUDA", "${QSUB}")
                    }
                }
            }

        }
        stage("Build: Build NVHPC IQTREE_GPU") {
            steps {


                script {

                    echo "building NVHPC IQTREE_GPU version (in-tree CUDA ModelFinder kernels)"

                    if ("${params.IQTREE_GPU}" == "true") {
                        buildIQTreeGPUVariants("${BUILD_NVHPC_IQTREE_GPU}", "IQTREE_GPU")
                    }
                }
            }

        }
        stage("Build: Build NVHPC OpenACC") {
            steps {


                script {

                    echo "building NVHPC OpenACC version"

                    if ("${params.OPENACC}" == "true") {
                        buildOpenACCVariants("${BUILD_NVHPC_OPENACC}", "OPENACC")
                    }
                }
            }
        }

        stage("Build: Build NVHPC OpenACC Profiling") {
            steps {
                script {

                    echo "building NVHPC OpenACC with profiling instrumentation"

                    if ("${params.OPENACC_PROFILE}" == "true") {
                        buildOpenACCVariants("${BUILD_NVHPC_PROF_OPENACC}", "OPENACC_PROFILE")
                    }
                }
            }
        }

        stage("Build: Build NVHPC OpenACC Debug") {
            steps {
                script {

                    echo "building NVHPC OpenACC with debug build"

                    if ("${params.OPENACC_DEBUG}" == "true") {
                        buildOpenACCVariants("${BUILD_NVHPC_DEBUG_OPENACC}", "OPENACC_DEBUG")
                    }
                }
            }
        }

        stage("Build: Build NVHPC OpenACC Debug + Profiling") {
            steps {
                script {

                    echo "building NVHPC OpenACC with debug build and profiling instrumentation"

                    if ("${params.OPENACC_DEBUG_PROFILE}" == "true") {
                        buildOpenACCVariants("${BUILD_NVHPC_DEBUG_PROF_OPENACC}", "OPENACC_DEBUG_PROFILE")
                    }
                }
            }
        }

        stage("Build: Build NVHPC OpenMP GPU") {
            steps {
                script {

                    echo "building NVHPC OpenMP GPU version"

                    if ("${params.OPENMP_GPU}" == "true") {
                        buildOpenMPGPUVariants("${BUILD_NVHPC_OPENMP_GPU}", "OPENMP_GPU")
                    }
                }
            }
        }

        stage("Build: Build NVHPC OpenMP GPU Profiling") {
            steps {
                script {

                    echo "building NVHPC OpenMP GPU with profiling instrumentation"

                    if ("${params.OPENMP_GPU_PROFILE}" == "true") {
                        buildOpenMPGPUVariants("${BUILD_NVHPC_PROF_OPENMP_GPU}", "OPENMP_GPU_PROFILE")
                    }
                }
            }
        }

        stage("Build: Build NVHPC OpenMP GPU Debug") {
            steps {
                script {

                    echo "building NVHPC OpenMP GPU with debug build"

                    if ("${params.OPENMP_GPU_DEBUG}" == "true") {
                        buildOpenMPGPUVariants("${BUILD_NVHPC_DEBUG_OPENMP_GPU}", "OPENMP_GPU_DEBUG")
                    }
                }
            }
        }

        stage("Build: Build NVHPC OpenMP GPU Debug + Profiling") {
            steps {
                script {

                    echo "building NVHPC OpenMP GPU with debug build and profiling instrumentation"

                    if ("${params.OPENMP_GPU_DEBUG_PROFILE}" == "true") {
                        buildOpenMPGPUVariants("${BUILD_NVHPC_DEBUG_PROF_OPENMP_GPU}", "OPENMP_GPU_DEBUG_PROFILE")
                    }
                }
            }
        }

        stage('Verify') {
            steps {
                script {
                    sh "ssh ${NCI_ALIAS} 'cd ${WORKING_DIR} && ls -l'"

                }
            }
        }


    }
    post {
        always {
            echo 'Cleaning up workspace'
           // cleanWs()
        }
    }
}

def void cleanWs() {
    // ssh to NCI_ALIAS and remove the working directory
    sh "ssh ${NCI_ALIAS} 'rm -rf ${BUILD_SCRIPTS}'"
}

def void cleanIQTree() {
    // ssh to NCI_ALIAS and remove the working directory
    sh "ssh ${NCI_ALIAS} 'rm -rf ${IQTREE_DIR}'"
}


def void runBuildScript(String script, String buildDir,  String CUDA, String qsub, String gpuArch = '') {
    echo "running building ..."
    if (qsub == "true") {
        echo "running with qsub ..."
        sh """
        ssh ${NCI_ALIAS} << EOF

        echo "building ${script}:${qsub}"
        qsub -vARG1=${buildDir},ARG2=${IQTREE_DIR},ARG3=${CUDA},ARG4=${gpuArch} ${BUILD_SCRIPTS}/qsub/${script}
        exit

        """
    }
    else {
        sh """
        ssh ${NCI_ALIAS} << EOF

        echo "building ${script}:${qsub}"
        sh ${BUILD_SCRIPTS}/${script} ${buildDir} ${IQTREE_DIR} ${CUDA} ${gpuArch}

        exit

        """
    }
}

// Dispatches one or more single-arch OpenACC builds for the given variant.
// When any of V100/A100/H200 is true, each enabled arch is built into a
// suffixed dir (-v100/-a100/-h200) with the matching qsub script:
//   V100  -> jenkins-cmake-build-nvhpc.sh       (-q normal,    cc70)
//   A100  -> jenkins-cmake-build-nvhpc-a100.sh  (-q dgxa100,   cc80)
//   H200  -> jenkins-cmake-build-nvhpc-h200.sh  (-q gpuhopper, cc90)
// dgxa100 and gpuhopper queues require ngpus>=1, so the per-arch scripts
// embed the appropriate PBS resource directives.
// When none of V100/A100/H200 is set, falls back to the original single-build
// behavior on the normal queue using GPU_ARCH (empty = multi-arch default).
def void buildOpenACCVariants(String baseDir, String variant) {
    boolean anyArch = ("${params.V100}" == "true") || ("${params.A100}" == "true") || ("${params.H200}" == "true")
    if (anyArch) {
        if ("${params.V100}" == "true") {
            echo "building ${variant} for V100 (cc70) -> ${baseDir}-v100"
            runBuildScript("jenkins-cmake-build-nvhpc.sh", "${baseDir}-v100", variant, "${QSUB}", "cc70")
        }
        if ("${params.A100}" == "true") {
            echo "building ${variant} for A100 (cc80) on dgxa100 queue -> ${baseDir}-a100"
            runBuildScript("jenkins-cmake-build-nvhpc-a100.sh", "${baseDir}-a100", variant, "${QSUB}", "cc80")
        }
        if ("${params.H200}" == "true") {
            echo "building ${variant} for H200 (cc90) on gpuhopper queue -> ${baseDir}-h200"
            runBuildScript("jenkins-cmake-build-nvhpc-h200.sh", "${baseDir}-h200", variant, "${QSUB}", "cc90")
        }
    } else {
        runBuildScript("jenkins-cmake-build-nvhpc.sh", baseDir, variant, "${QSUB}", "${GPU_ARCH}")
    }
}

// Dispatches one or more single-arch IQTREE_GPU builds (in-tree CUDA ModelFinder
// kernels). Mirrors buildOpenACCVariants but passes the IQTREE_GPU variant string.
//   V100  -> jenkins-cmake-build-nvhpc.sh       (-q normal,    cc70)
//   A100  -> jenkins-cmake-build-nvhpc-a100.sh  (-q dgxa100,   cc80)
//   H200  -> jenkins-cmake-build-nvhpc-h200.sh  (-q gpuhopper, cc90)
def void buildIQTreeGPUVariants(String baseDir, String variant) {
    boolean anyArch = ("${params.V100}" == "true") || ("${params.A100}" == "true") || ("${params.H200}" == "true")
    if (anyArch) {
        if ("${params.V100}" == "true") {
            echo "building ${variant} for V100 (cc70) -> ${baseDir}-v100"
            runBuildScript("jenkins-cmake-build-nvhpc.sh", "${baseDir}-v100", variant, "${QSUB}", "cc70")
        }
        if ("${params.A100}" == "true") {
            echo "building ${variant} for A100 (cc80) on dgxa100 queue -> ${baseDir}-a100"
            runBuildScript("jenkins-cmake-build-nvhpc-a100.sh", "${baseDir}-a100", variant, "${QSUB}", "cc80")
        }
        if ("${params.H200}" == "true") {
            echo "building ${variant} for H200 (cc90) on gpuhopper queue -> ${baseDir}-h200"
            runBuildScript("jenkins-cmake-build-nvhpc-h200.sh", "${baseDir}-h200", variant, "${QSUB}", "cc90")
        }
    } else {
        runBuildScript("jenkins-cmake-build-nvhpc.sh", baseDir, variant, "${QSUB}", "${GPU_ARCH}")
    }
}

// Dispatches one or more single-arch OpenMP GPU builds for the given variant.
// Mirrors buildOpenACCVariants but passes OPENMP_GPU* variant strings.
//   V100  -> jenkins-cmake-build-nvhpc.sh       (-q normal,    cc70)
//   A100  -> jenkins-cmake-build-nvhpc-a100.sh  (-q dgxa100,   cc80)
//   H200  -> jenkins-cmake-build-nvhpc-h200.sh  (-q gpuhopper, cc90)
def void buildOpenMPGPUVariants(String baseDir, String variant) {
    boolean anyArch = ("${params.V100}" == "true") || ("${params.A100}" == "true") || ("${params.H200}" == "true")
    if (anyArch) {
        if ("${params.V100}" == "true") {
            echo "building ${variant} for V100 (cc70) -> ${baseDir}-v100"
            runBuildScript("jenkins-cmake-build-nvhpc.sh", "${baseDir}-v100", variant, "${QSUB}", "cc70")
        }
        if ("${params.A100}" == "true") {
            echo "building ${variant} for A100 (cc80) on dgxa100 queue -> ${baseDir}-a100"
            runBuildScript("jenkins-cmake-build-nvhpc-a100.sh", "${baseDir}-a100", variant, "${QSUB}", "cc80")
        }
        if ("${params.H200}" == "true") {
            echo "building ${variant} for H200 (cc90) on gpuhopper queue -> ${baseDir}-h200"
            runBuildScript("jenkins-cmake-build-nvhpc-h200.sh", "${baseDir}-h200", variant, "${QSUB}", "cc90")
        }
    } else {
        runBuildScript("jenkins-cmake-build-nvhpc.sh", baseDir, variant, "${QSUB}", "${GPU_ARCH}")
    }
}