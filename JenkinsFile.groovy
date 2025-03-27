//  a JenkinsFile to build iqtree
// paramters
//  1. git branch
// 2. git url

pipeline {
    agent any
    parameters {
        string(name: 'BRANCH', defaultValue: 'master', description: 'Branch to build')
        booleanParam(defaultValue: true, description: 'Clone IQ-TREE?', name: 'CLONE_IQTREE')
        string(name: 'NCI_ALIAS', defaultValue: 'nci_gadi', description: 'ssh alias, if you do not have one, create one')


        string(name: 'WORKING_DIR', defaultValue: '/scratch/dx61/sa0557/iqtree2/ci-cd', description: 'Working directory')

        booleanParam(defaultValue: true, description: 'Use QSUB?', name: 'QSUB')

        // bool for building NN
        booleanParam(defaultValue: true, description: 'Compile with NVHPC?', name: 'NVHPC')
        booleanParam(defaultValue: true, description: 'Compile with GCC?', name: 'GCC')
        booleanParam(defaultValue: true, description: 'OpenACC intergration?', name: 'OPENACC')

//        booleanParam(defaultValue: true, description: 'Run the GPU?', name: 'GPU')
//        string(name: 'ONNX_NN_GPU', description: 'onnxruntime for NN-CUDA (use 1.12 version)', defaultValue: '/scratch/dx61/sa0557/iqtree2/onnxruntime-linux-x64-gpu-1.12.1')

    }
    environment {
        IQTREE_GIT_URL = "https://github.com/hashara/iqtree3.git"
        NCI_ALIAS = "${params.NCI_ALIAS}"
        WORKING_DIR = "${params.WORKING_DIR}"
        GIT_REPO = "iqtree3"
        BUILD_SCRIPTS = "${WORKING_DIR}/build-scripts"
        IQTREE_DIR = "${WORKING_DIR}/${GIT_REPO}"
        BUILD_OUTPUT_DIR = "${WORKING_DIR}/builds"
        CLONE_IQTREE = "${params.CLONE_IQTREE}"
        QSUB = "${params.QSUB}"

        // build directories
        BUILD_NVHPC_VANILA = "${BUILD_OUTPUT_DIR}/build-nvhpc-vanila"
        BUILD_GCC_VANILA = "${BUILD_OUTPUT_DIR}/build-gcc-vanila"
        BUILD_NVHPC_OPENACC = "${BUILD_OUTPUT_DIR}/build-nvhpc-openacc"
        BUILD_GCC_OPENACC = "${BUILD_OUTPUT_DIR}/build-gcc-openacc"


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
                        rm -rf *
                        exit
                        
                        """

                    }
                    else {
                        echo "Using existing IQ-TREE"
                    }
                }
            }
        }
        stage("Build: Build NVHPC Vanila") {
            steps {
                script {

                    echo "building NVHPC vanila version"

                    if ("${params.NVHPC}" == "true") {
                        sh """
                        ssh ${NCI_ALIAS} << EOF

                        echo "building NVHPC vanila version"
                        sh ${BUILD_SCRIPTS}/jenkins-cmake-build-nvhpc-vanila.sh ${BUILD_NVHPC_VANILA} ${IQTREE_DIR}

                        exit
                        
                        """
                    }
                }
            }
        }

        stage("Build: Build GCC Vanila") {
            steps {
                script {

                    echo "building GCC vanila version"



                    if ("${params.GCC}" == "true") {

                        sh """
                        ssh ${NCI_ALIAS} << EOF

                        echo "building GCC vanila version"

                        sh ${BUILD_SCRIPTS}/jenkins-cmake-build-gcc-vanila.sh ${BUILD_GCC_VANILA} ${IQTREE_DIR}
                        exit
                        
                        """

//                        sh """
//                        ssh ${NCI_ALIAS} << EOF
//
//                        echo "building GCC vanila version"
//
//                        qsub -vARG1=${BUILD_GCC_VANILA},ARG2=${IQTREE_DIR},ARG3="" ${BUILD_SCRIPTS}/jenkins-cmake-build-gcc-vanila.sh
//                        exit
//
//                        """
                    }


                }
            }
        }

        stage("Build: Build NVHPC OpenACC") {
            steps {


                script {

                    echo "building NVHPC OpenACC version"

                    if ("${params.NVHPC}" == "true" && "${params.OPENACC}" == "true") {
                        sh """
                        ssh ${NCI_ALIAS} << EOF

                        echo "building NVHPC openACC version"
                        sh ${BUILD_SCRIPTS}/jenkins-cmake-build-gcc-vanila.sh  ${BUILD_NVHPC_OPENACC} ${IQTREE_DIR} openacc

                        exit
                        
                        """
                    }
                }
            }
        }

        stage("Build: Build GCC OpenACC") {
            steps {
                script {

                    echo "building GCC OpenACC version"


                    if ("${params.GCC}" == "true"  && "${params.OPENACC}" == "true") {

                        sh """
                        ssh ${NCI_ALIAS} << EOF

                        echo "building GCC vanila version"
                        sh ${BUILD_SCRIPTS}/jenkins-cmake-build-gcc-vanila.sh ${BUILD_GCC_OPENACC} ${IQTREE_DIR} openacc

                        exit
                        
                        """
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
            cleanWs()
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